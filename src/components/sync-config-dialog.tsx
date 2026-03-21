"use client";

import { invoke } from "@tauri-apps/api/core";
import { useCallback, useEffect, useMemo, useState } from "react";
import { useTranslation } from "react-i18next";
import { LuEye, LuEyeOff } from "react-icons/lu";
import { LoadingButton } from "@/components/loading-button";
import { useRuntimeAppConfig } from "@/components/runtime-app-config-provider";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { useCloudAuth } from "@/hooks/use-cloud-auth";
import { showErrorToast, showSuccessToast } from "@/lib/toast-utils";
import type { ActiveSyncMode, SyncSettings } from "@/types";

interface SyncConfigDialogProps {
  isOpen: boolean;
  onClose: (loginOccurred?: boolean) => void;
  onReviewUnsyncedItems?: () => void;
}

type ConnectionStatus = "unknown" | "testing" | "connected" | "error";

export function SyncConfigDialog({
  isOpen,
  onClose,
  onReviewUnsyncedItems,
}: SyncConfigDialogProps) {
  const { t } = useTranslation();
  const runtimeConfig = useRuntimeAppConfig();
  const hostedCloudVisible = runtimeConfig.hosted_cloud_ui_mode !== "hidden";
  const hostedCloudDisabled = runtimeConfig.hosted_cloud_ui_mode === "disabled";
  const selfHostedSyncEnabled = runtimeConfig.self_hosted_sync_enabled;

  const {
    user,
    isLoggedIn,
    isLoading: isCloudLoading,
    lastError,
    requestOtp,
    verifyOtp,
    signInWithPassword,
    startGoogleSignIn,
    enableHostedSync,
    disableHostedSync,
    logout,
    refreshProfile,
    clearLastError,
  } = useCloudAuth();

  const [syncSettings, setSyncSettings] = useState<SyncSettings | null>(null);
  const [activeTab, setActiveTab] = useState("self-hosted");
  const [isLoadingSettings, setIsLoadingSettings] = useState(false);
  const [isSavingSelfHosted, setIsSavingSelfHosted] = useState(false);
  const [isTestingSelfHosted, setIsTestingSelfHosted] = useState(false);
  const [isSubmittingHostedAction, setIsSubmittingHostedAction] =
    useState(false);
  const [connectionStatus, setConnectionStatus] =
    useState<ConnectionStatus>("unknown");
  const [selfHostedServerUrl, setSelfHostedServerUrl] = useState("");
  const [selfHostedToken, setSelfHostedToken] = useState("");
  const [showSelfHostedToken, setShowSelfHostedToken] = useState(false);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [otpCode, setOtpCode] = useState("");
  const [codeSent, setCodeSent] = useState(false);
  const [awaitingGoogleCompletion, setAwaitingGoogleCompletion] =
    useState(false);

  const handleEmailChange = useCallback((value: string) => {
    setEmail(value);
    setCodeSent(false);
    setOtpCode("");
  }, []);

  const activeSyncMode: ActiveSyncMode =
    syncSettings?.active_sync_mode ?? "none";
  const hostedSyncEnabled = Boolean(syncSettings?.hosted_sync_enabled);
  const hostedSyncAvailable = Boolean(syncSettings?.hosted_sync_available);
  const hasSelfHostedConfig = Boolean(
    selfHostedServerUrl.trim() && selfHostedToken.trim(),
  );
  const hostedSyncActive = hostedSyncEnabled && activeSyncMode === "hosted";
  const showHostedActivationStep =
    isLoggedIn && hostedSyncAvailable && !hostedSyncActive;

  const loadSettings = useCallback(async () => {
    setIsLoadingSettings(true);
    try {
      const settings = await invoke<SyncSettings>("get_sync_settings");
      setSyncSettings(settings);
      setSelfHostedServerUrl(settings.self_hosted_sync_server_url ?? "");
      setSelfHostedToken(settings.self_hosted_sync_token ?? "");

      if (settings.self_hosted_sync_server_url) {
        setConnectionStatus("unknown");
      } else {
        setConnectionStatus("unknown");
      }
    } catch (error) {
      console.error("Failed to load sync settings:", error);
      showErrorToast("Failed to load sync settings.");
    } finally {
      setIsLoadingSettings(false);
    }
  }, []);

  useEffect(() => {
    if (!isOpen) return;

    setEmail("");
    setPassword("");
    setOtpCode("");
    setCodeSent(false);
    setAwaitingGoogleCompletion(false);
    setConnectionStatus("unknown");
    void loadSettings();
  }, [isOpen, loadSettings]);

  useEffect(() => {
    if (!isOpen || !lastError) {
      return;
    }

    setIsSubmittingHostedAction(false);
    setAwaitingGoogleCompletion(false);
    showErrorToast(lastError);
    clearLastError();
  }, [clearLastError, isOpen, lastError]);

  useEffect(() => {
    if (!isOpen || !awaitingGoogleCompletion || !isLoggedIn) {
      return;
    }

    setIsSubmittingHostedAction(false);
    setAwaitingGoogleCompletion(false);
    showSuccessToast(t("sync.hosted.loginConnectedToast"));
    void loadSettings();
  }, [awaitingGoogleCompletion, isLoggedIn, isOpen, loadSettings, t]);

  useEffect(() => {
    if (!isOpen) return;

    if (activeSyncMode === "hosted" && hostedCloudVisible) {
      setActiveTab("hosted");
      return;
    }

    if (hasSelfHostedConfig && selfHostedSyncEnabled) {
      setActiveTab("self-hosted");
      return;
    }

    if (hostedCloudVisible) {
      setActiveTab("hosted");
      return;
    }

    setActiveTab("self-hosted");
  }, [
    activeSyncMode,
    hasSelfHostedConfig,
    hostedCloudVisible,
    isOpen,
    selfHostedSyncEnabled,
  ]);

  const testSelfHostedConnection = useCallback(async () => {
    if (!selfHostedServerUrl.trim()) {
      showErrorToast("Please enter a sync server URL.");
      return;
    }

    setIsTestingSelfHosted(true);
    setConnectionStatus("testing");
    try {
      const healthUrl = `${selfHostedServerUrl.replace(/\/$/, "")}/health`;
      const response = await fetch(healthUrl);

      if (!response.ok) {
        setConnectionStatus("error");
        showErrorToast("The sync server responded with an error.");
        return;
      }

      setConnectionStatus("connected");
      showSuccessToast("Sync server connection succeeded.");
    } catch (error) {
      console.error("Failed to connect to sync server:", error);
      setConnectionStatus("error");
      showErrorToast("Failed to connect to the sync server.");
    } finally {
      setIsTestingSelfHosted(false);
    }
  }, [selfHostedServerUrl]);

  const saveSelfHostedSettings = useCallback(async () => {
    setIsSavingSelfHosted(true);
    try {
      const updatedSettings = await invoke<SyncSettings>("save_sync_settings", {
        syncServerUrl: selfHostedServerUrl.trim() || null,
        syncToken: selfHostedToken.trim() || null,
      });
      await invoke("restart_sync_service");
      setSyncSettings(updatedSettings);
      showSuccessToast("Self-hosted sync settings saved.");
      onClose(false);
    } catch (error) {
      console.error("Failed to save self-hosted sync settings:", error);
      showErrorToast(String(error));
    } finally {
      setIsSavingSelfHosted(false);
    }
  }, [onClose, selfHostedServerUrl, selfHostedToken]);

  const disconnectSelfHosted = useCallback(async () => {
    setIsSavingSelfHosted(true);
    try {
      const updatedSettings = await invoke<SyncSettings>("save_sync_settings", {
        syncServerUrl: null,
        syncToken: null,
      });
      await invoke("restart_sync_service");
      setSyncSettings(updatedSettings);
      setSelfHostedServerUrl("");
      setSelfHostedToken("");
      setConnectionStatus("unknown");
      showSuccessToast("Self-hosted sync disconnected.");
    } catch (error) {
      console.error("Failed to disconnect self-hosted sync:", error);
      showErrorToast(String(error));
    } finally {
      setIsSavingSelfHosted(false);
    }
  }, []);

  const sendOtp = useCallback(async () => {
    if (!email.trim()) {
      showErrorToast("Please enter your email address.");
      return;
    }

    setIsSubmittingHostedAction(true);
    try {
      await requestOtp(email.trim());
      setCodeSent(true);
      showSuccessToast(t("sync.hosted.sendCodeSuccessToast"));
    } catch (error) {
      console.error("Failed to request hosted OTP:", error);
      showErrorToast(String(error));
    } finally {
      setIsSubmittingHostedAction(false);
    }
  }, [email, requestOtp, t]);

  const verifyEmailOtp = useCallback(async () => {
    if (!email.trim() || !otpCode.trim()) {
      showErrorToast("Enter your email and verification code.");
      return;
    }

    setIsSubmittingHostedAction(true);
    try {
      await verifyOtp(email.trim(), otpCode.trim());
      await loadSettings();
      showSuccessToast(t("sync.hosted.loginConnectedToast"));
    } catch (error) {
      console.error("Failed to verify hosted OTP:", error);
      showErrorToast(String(error));
    } finally {
      setIsSubmittingHostedAction(false);
    }
  }, [email, loadSettings, otpCode, t, verifyOtp]);

  const signInWithEmailPassword = useCallback(async () => {
    if (!email.trim() || !password) {
      showErrorToast("Enter your email and password.");
      return;
    }

    setIsSubmittingHostedAction(true);
    try {
      await signInWithPassword(email.trim(), password);
      await loadSettings();
      showSuccessToast(t("sync.hosted.loginConnectedToast"));
    } catch (error) {
      console.error("Failed to sign in with password:", error);
      showErrorToast(String(error));
    } finally {
      setIsSubmittingHostedAction(false);
    }
  }, [email, loadSettings, password, signInWithPassword, t]);

  const triggerGoogleSignIn = useCallback(async () => {
    setIsSubmittingHostedAction(true);
    try {
      await startGoogleSignIn();
      setAwaitingGoogleCompletion(true);
      showSuccessToast(
        "Google sign-in opened in your browser. Complete the flow there.",
      );
    } catch (error) {
      console.error("Failed to start Google sign-in:", error);
      showErrorToast(String(error));
      setAwaitingGoogleCompletion(false);
    } finally {
      setIsSubmittingHostedAction(false);
    }
  }, [startGoogleSignIn]);

  const enableHostedSyncMode = useCallback(async () => {
    setIsSubmittingHostedAction(true);
    try {
      await enableHostedSync();
      await loadSettings();
      showSuccessToast(t("sync.hosted.syncEnabledToast"));
      onClose(true);
    } catch (error) {
      console.error("Failed to enable hosted sync:", error);
      showErrorToast(String(error));
    } finally {
      setIsSubmittingHostedAction(false);
    }
  }, [enableHostedSync, loadSettings, onClose, t]);

  const disableHostedSyncMode = useCallback(async () => {
    setIsSubmittingHostedAction(true);
    try {
      await disableHostedSync();
      await loadSettings();
      showSuccessToast(t("sync.hosted.syncDisabledToast"));
    } catch (error) {
      console.error("Failed to disable hosted sync:", error);
      showErrorToast(String(error));
    } finally {
      setIsSubmittingHostedAction(false);
    }
  }, [disableHostedSync, loadSettings, t]);

  const logoutHostedAccount = useCallback(async () => {
    setIsSubmittingHostedAction(true);
    try {
      await logout();
      await loadSettings();
      showSuccessToast(t("sync.hosted.signOutToast"));
    } catch (error) {
      console.error("Failed to sign out of hosted account:", error);
      showErrorToast(String(error));
    } finally {
      setIsSubmittingHostedAction(false);
    }
  }, [loadSettings, logout, t]);

  const refreshHostedAccount = useCallback(async () => {
    setIsSubmittingHostedAction(true);
    try {
      await refreshProfile();
      await loadSettings();
      showSuccessToast("Hosted account refreshed.");
    } catch (error) {
      console.error("Failed to refresh hosted account:", error);
      showErrorToast(String(error));
    } finally {
      setIsSubmittingHostedAction(false);
    }
  }, [loadSettings, refreshProfile]);

  const reviewUnsyncedItems = useCallback(() => {
    onClose(false);
    onReviewUnsyncedItems?.();
  }, [onClose, onReviewUnsyncedItems]);

  const hostedStatusMessage = useMemo(() => {
    if (hostedCloudDisabled) {
      return "Hosted account auth is not configured in this build yet.";
    }
    if (!hostedSyncAvailable) {
      if (!isLoggedIn) {
        return t("sync.hosted.syncUnavailableLoggedOut");
      }
      return t("sync.hosted.syncUnavailableLoggedIn");
    }
    if (!isLoggedIn) {
      return t("sync.hosted.signInFirst");
    }
    if (hostedSyncActive) {
      return t("sync.hosted.activeStatus");
    }
    return t("sync.hosted.activationStatus");
  }, [
    hostedSyncActive,
    hostedCloudDisabled,
    hostedSyncAvailable,
    isLoggedIn,
    t,
  ]);

  const selfHostedSection = (
    <div className="grid gap-4 py-2">
      {!selfHostedSyncEnabled && (
        <div className="rounded-md border bg-muted/40 p-3 text-sm text-muted-foreground">
          Self-hosted sync is disabled in this build.
        </div>
      )}

      <div className="space-y-2">
        <Label htmlFor="self-hosted-sync-server-url">
          {t("sync.serverUrl", "Server URL")}
        </Label>
        <Input
          id="self-hosted-sync-server-url"
          placeholder={
            t("sync.serverUrlPlaceholder", "https://sync.example.com") ||
            "https://sync.example.com"
          }
          value={selfHostedServerUrl}
          onChange={(event) => setSelfHostedServerUrl(event.target.value)}
          disabled={!selfHostedSyncEnabled}
        />
      </div>

      <div className="space-y-2">
        <Label htmlFor="self-hosted-sync-token">
          {t("sync.token", "Sync Token")}
        </Label>
        <div className="relative">
          <Input
            id="self-hosted-sync-token"
            type={showSelfHostedToken ? "text" : "password"}
            placeholder={
              t("sync.tokenPlaceholder", "Enter your sync token") ||
              "Enter your sync token"
            }
            value={selfHostedToken}
            onChange={(event) => setSelfHostedToken(event.target.value)}
            disabled={!selfHostedSyncEnabled}
            className="pr-10"
          />
          <button
            type="button"
            onClick={() => setShowSelfHostedToken((previous) => !previous)}
            className="absolute right-3 top-1/2 -translate-y-1/2 rounded-sm p-1 text-muted-foreground transition-colors hover:bg-accent hover:text-foreground"
            aria-label={showSelfHostedToken ? "Hide token" : "Show token"}
            disabled={!selfHostedSyncEnabled}
          >
            {showSelfHostedToken ? (
              <LuEyeOff className="h-4 w-4" />
            ) : (
              <LuEye className="h-4 w-4" />
            )}
          </button>
        </div>
      </div>

      <div className="rounded-md border bg-muted/40 p-3 text-sm text-muted-foreground">
        <div className="font-medium text-foreground">Current mode</div>
        <div className="mt-1">
          {activeSyncMode === "self_hosted" &&
            "Self-hosted sync is the active sync target."}
          {activeSyncMode === "hosted" &&
            "Hosted sync is currently active. Saving self-hosted settings here keeps them ready as a fallback without switching modes."}
          {activeSyncMode === "none" &&
            "No sync target is currently active. Saving these settings will make self-hosted sync available."}
        </div>
        <div className="mt-2">
          Connection status:{" "}
          <span className="font-medium">
            {connectionStatus === "unknown" && "Not tested"}
            {connectionStatus === "testing" && "Testing"}
            {connectionStatus === "connected" && "Connected"}
            {connectionStatus === "error" && "Error"}
          </span>
        </div>
      </div>

      <div className="flex flex-wrap gap-2">
        <LoadingButton
          type="button"
          variant="outline"
          isLoading={isTestingSelfHosted}
          onClick={testSelfHostedConnection}
          disabled={!selfHostedSyncEnabled || !selfHostedServerUrl.trim()}
        >
          Test Connection
        </LoadingButton>
        <LoadingButton
          type="button"
          isLoading={isSavingSelfHosted}
          onClick={saveSelfHostedSettings}
          disabled={!selfHostedSyncEnabled || !hasSelfHostedConfig}
        >
          Save Self-Hosted Settings
        </LoadingButton>
        <LoadingButton
          type="button"
          variant="destructive"
          isLoading={isSavingSelfHosted}
          onClick={disconnectSelfHosted}
          disabled={
            !selfHostedSyncEnabled || !syncSettings?.self_hosted_sync_server_url
          }
        >
          Disconnect Self-Hosted
        </LoadingButton>
      </div>
    </div>
  );

  const hostedSection = (
    <div className="grid gap-4 py-2">
      <div className="rounded-md border bg-muted/40 p-3 text-sm text-muted-foreground">
        {hostedStatusMessage}
      </div>

      {hostedCloudDisabled ? (
        <div className="rounded-md border border-dashed p-4 text-sm text-muted-foreground">
          Configure `TWITTERBROWSER_SUPABASE_URL` and
          `TWITTERBROWSER_SUPABASE_ANON_KEY` to enable hosted account sign-in in
          this build.
        </div>
      ) : isCloudLoading || isLoadingSettings ? (
        <div className="flex justify-center py-8">
          <div className="h-6 w-6 animate-spin rounded-full border-2 border-current border-t-transparent" />
        </div>
      ) : isLoggedIn && user ? (
        <div className="grid gap-4">
          <div className="rounded-md border p-4">
            <div className="font-medium text-foreground">
              {user.displayName || user.email}
            </div>
            <div className="text-sm text-muted-foreground">{user.email}</div>
            <div className="mt-3 grid gap-1 text-sm text-muted-foreground">
              <div>
                Hosted sync:{" "}
                <span className="font-medium text-foreground">
                  {hostedSyncActive ? "Enabled" : "Disabled"}
                </span>
              </div>
              <div>
                Cloud profiles used:{" "}
                <span className="font-medium text-foreground">
                  {user.cloudProfilesUsed}
                </span>
              </div>
              <div>
                Profile limit:{" "}
                <span className="font-medium text-foreground">
                  {user.profileLimit === 0 ? "Unlimited" : user.profileLimit}
                </span>
              </div>
              {user.syncPrefix ? (
                <div>
                  Sync prefix:{" "}
                  <span className="font-medium text-foreground">
                    {user.syncPrefix}
                  </span>
                </div>
              ) : null}
              {!hostedSyncAvailable ? (
                <div>
                  Hosted sync server URL:{" "}
                  <span className="font-medium text-foreground">
                    Not configured in this build
                  </span>
                </div>
              ) : null}
            </div>
          </div>

          {showHostedActivationStep ? (
            <div className="grid gap-4 rounded-md border border-warning/50 bg-warning/10 p-4">
              <div className="space-y-2">
                <div className="font-medium text-foreground">
                  {t("sync.hosted.activationTitle")}
                </div>
                <div className="text-sm text-muted-foreground">
                  {t("sync.hosted.activationDescription")}
                </div>
              </div>
              <div className="flex flex-wrap gap-2">
                <LoadingButton
                  type="button"
                  isLoading={isSubmittingHostedAction}
                  onClick={enableHostedSyncMode}
                  disabled={!hostedSyncAvailable}
                >
                  {t("sync.hosted.enableAction")}
                </LoadingButton>
                <Button
                  type="button"
                  variant="outline"
                  onClick={() => onClose(false)}
                >
                  {t("sync.hosted.keepLocalOnly")}
                </Button>
                <Button
                  type="button"
                  variant="outline"
                  onClick={reviewUnsyncedItems}
                >
                  {t("sync.hosted.reviewUnsyncedItemsAction")}
                </Button>
                <LoadingButton
                  type="button"
                  variant="outline"
                  isLoading={isSubmittingHostedAction}
                  onClick={refreshHostedAccount}
                >
                  {t("sync.hosted.refreshAction")}
                </LoadingButton>
                <LoadingButton
                  type="button"
                  variant="destructive"
                  isLoading={isSubmittingHostedAction}
                  onClick={logoutHostedAccount}
                >
                  {t("sync.hosted.signOutAction")}
                </LoadingButton>
              </div>
            </div>
          ) : (
            <div className="flex flex-wrap gap-2">
              <LoadingButton
                type="button"
                isLoading={isSubmittingHostedAction}
                onClick={enableHostedSyncMode}
                disabled={!hostedSyncAvailable || hostedSyncActive}
              >
                {t("sync.hosted.enableAction")}
              </LoadingButton>
              <LoadingButton
                type="button"
                variant="outline"
                isLoading={isSubmittingHostedAction}
                onClick={disableHostedSyncMode}
                disabled={!hostedSyncEnabled && activeSyncMode !== "hosted"}
              >
                {t("sync.hosted.disableAction")}
              </LoadingButton>
              <LoadingButton
                type="button"
                variant="outline"
                isLoading={isSubmittingHostedAction}
                onClick={refreshHostedAccount}
              >
                {t("sync.hosted.refreshAction")}
              </LoadingButton>
              <Button
                type="button"
                variant="outline"
                onClick={reviewUnsyncedItems}
              >
                {t("sync.hosted.reviewUnsyncedItemsAction")}
              </Button>
              <LoadingButton
                type="button"
                variant="destructive"
                isLoading={isSubmittingHostedAction}
                onClick={logoutHostedAccount}
              >
                {t("sync.hosted.signOutAction")}
              </LoadingButton>
            </div>
          )}
        </div>
      ) : (
        <div className="grid gap-5">
          {!hostedSyncAvailable ? (
            <div className="rounded-md border border-dashed p-4 text-sm text-muted-foreground">
              {t("sync.hosted.syncReadyHint")}
            </div>
          ) : null}

          <div className="grid gap-3 rounded-md border p-4">
            <div className="font-medium text-foreground">
              {t("sync.hosted.googleTitle")}
            </div>
            <div className="text-sm text-muted-foreground">
              {t("sync.hosted.googleDescription")}
            </div>
            <LoadingButton
              type="button"
              variant="outline"
              isLoading={isSubmittingHostedAction}
              onClick={triggerGoogleSignIn}
            >
              {t("sync.hosted.googleAction")}
            </LoadingButton>
          </div>

          <div className="grid gap-3 rounded-md border p-4">
            <div className="font-medium text-foreground">
              {t("sync.hosted.passwordTitle")}
            </div>
            <div className="text-sm text-muted-foreground">
              {t("sync.hosted.passwordDescription")}
            </div>
            <div className="grid gap-2">
              <Label htmlFor="hosted-email-password-email">
                {t("sync.cloud.email")}
              </Label>
              <Input
                id="hosted-email-password-email"
                type="email"
                value={email}
                onChange={(event) => handleEmailChange(event.target.value)}
                placeholder={t("sync.cloud.emailPlaceholder")}
              />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="hosted-email-password-password">
                {t("proxies.form.password")}
              </Label>
              <Input
                id="hosted-email-password-password"
                type="password"
                value={password}
                onChange={(event) => setPassword(event.target.value)}
                placeholder={t("sync.hosted.passwordPlaceholder")}
              />
            </div>
            <LoadingButton
              type="button"
              isLoading={isSubmittingHostedAction}
              onClick={signInWithEmailPassword}
            >
              {t("sync.hosted.passwordAction")}
            </LoadingButton>
          </div>

          <div className="grid gap-3 rounded-md border p-4">
            <div className="font-medium text-foreground">
              {t("sync.hosted.emailCodeTitle")}
            </div>
            <div className="text-sm text-muted-foreground">
              {t("sync.hosted.emailCodeDescription")}
            </div>
            <div className="grid gap-2">
              <Label htmlFor="hosted-email-otp-email">
                {t("sync.cloud.email")}
              </Label>
              <Input
                id="hosted-email-otp-email"
                type="email"
                value={email}
                onChange={(event) => handleEmailChange(event.target.value)}
                placeholder={t("sync.cloud.emailPlaceholder")}
              />
            </div>
            {codeSent ? (
              <>
                <div className="rounded-md border bg-muted/40 p-3 text-sm text-muted-foreground">
                  {t("sync.hosted.emailCodeSentHint")}
                </div>
                <div className="grid gap-2">
                  <Label htmlFor="hosted-email-otp-code">
                    {t("sync.cloud.verificationCode")}
                  </Label>
                  <Input
                    id="hosted-email-otp-code"
                    value={otpCode}
                    onChange={(event) => setOtpCode(event.target.value)}
                    placeholder={t("sync.cloud.codePlaceholder")}
                  />
                </div>
              </>
            ) : null}
            <div className="flex flex-wrap gap-2">
              <LoadingButton
                type="button"
                variant="outline"
                isLoading={isSubmittingHostedAction}
                onClick={sendOtp}
              >
                {t("sync.cloud.sendCode")}
              </LoadingButton>
              <LoadingButton
                type="button"
                isLoading={isSubmittingHostedAction}
                onClick={verifyEmailOtp}
                disabled={!codeSent || !otpCode.trim()}
              >
                {t("sync.cloud.verifyAndLogin")}
              </LoadingButton>
            </div>
          </div>
        </div>
      )}
    </div>
  );

  return (
    <Dialog open={isOpen} onOpenChange={(open) => !open && onClose(false)}>
      <DialogContent className="max-h-[calc(100vh-2rem)] max-w-2xl grid-rows-[auto_minmax(0,1fr)_auto] gap-0 overflow-hidden p-0">
        <DialogHeader className="border-b px-6 py-4 pr-12">
          <DialogTitle>
            {t("sync.config.title", "Sync Configuration")}
          </DialogTitle>
          <DialogDescription>
            {t("sync.hosted.dialogDescription")}
          </DialogDescription>
        </DialogHeader>
        <div className="min-h-0 overflow-y-auto px-6 py-4">
          {isLoadingSettings ? (
            <div className="flex justify-center py-8">
              <div className="h-6 w-6 animate-spin rounded-full border-2 border-current border-t-transparent" />
            </div>
          ) : hostedCloudVisible && selfHostedSyncEnabled ? (
            <Tabs value={activeTab} onValueChange={setActiveTab}>
              <TabsList className="w-full">
                <TabsTrigger value="self-hosted" className="flex-1">
                  Self-Hosted
                </TabsTrigger>
                <TabsTrigger value="hosted" className="flex-1">
                  Hosted
                </TabsTrigger>
              </TabsList>
              <TabsContent value="self-hosted">{selfHostedSection}</TabsContent>
              <TabsContent value="hosted">{hostedSection}</TabsContent>
            </Tabs>
          ) : hostedCloudVisible ? (
            hostedSection
          ) : (
            selfHostedSection
          )}
        </div>

        <DialogFooter className="border-t px-6 py-4">
          <Button variant="outline" onClick={() => onClose(false)}>
            {t("common.actions.close", "Close")}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
