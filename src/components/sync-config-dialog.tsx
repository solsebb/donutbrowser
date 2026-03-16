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
}

type ConnectionStatus = "unknown" | "testing" | "connected" | "error";

export function SyncConfigDialog({ isOpen, onClose }: SyncConfigDialogProps) {
  const { t } = useTranslation();
  const runtimeConfig = useRuntimeAppConfig();
  const hostedCloudVisible = runtimeConfig.hosted_cloud_ui_mode !== "hidden";
  const hostedCloudDisabled = runtimeConfig.hosted_cloud_ui_mode === "disabled";
  const selfHostedSyncEnabled = runtimeConfig.self_hosted_sync_enabled;

  const {
    user,
    isLoggedIn,
    isLoading: isCloudLoading,
    requestOtp,
    verifyOtp,
    signInWithPassword,
    startGoogleSignIn,
    enableHostedSync,
    disableHostedSync,
    logout,
    refreshProfile,
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

  const activeSyncMode: ActiveSyncMode =
    syncSettings?.active_sync_mode ?? "none";
  const hostedSyncEnabled = Boolean(syncSettings?.hosted_sync_enabled);
  const hostedSyncAvailable = Boolean(syncSettings?.hosted_sync_available);
  const hasSelfHostedConfig = Boolean(
    selfHostedServerUrl.trim() && selfHostedToken.trim(),
  );

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
    setConnectionStatus("unknown");
    void loadSettings();
  }, [isOpen, loadSettings]);

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
      showSuccessToast("Verification code sent.");
    } catch (error) {
      console.error("Failed to request hosted OTP:", error);
      showErrorToast(String(error));
    } finally {
      setIsSubmittingHostedAction(false);
    }
  }, [email, requestOtp]);

  const verifyEmailOtp = useCallback(async () => {
    if (!email.trim() || !otpCode.trim()) {
      showErrorToast("Enter your email and verification code.");
      return;
    }

    setIsSubmittingHostedAction(true);
    try {
      await verifyOtp(email.trim(), otpCode.trim());
      await loadSettings();
      showSuccessToast("Hosted account connected.");
    } catch (error) {
      console.error("Failed to verify hosted OTP:", error);
      showErrorToast(String(error));
    } finally {
      setIsSubmittingHostedAction(false);
    }
  }, [email, loadSettings, otpCode, verifyOtp]);

  const signInWithEmailPassword = useCallback(async () => {
    if (!email.trim() || !password) {
      showErrorToast("Enter your email and password.");
      return;
    }

    setIsSubmittingHostedAction(true);
    try {
      await signInWithPassword(email.trim(), password);
      await loadSettings();
      showSuccessToast("Hosted account connected.");
    } catch (error) {
      console.error("Failed to sign in with password:", error);
      showErrorToast(String(error));
    } finally {
      setIsSubmittingHostedAction(false);
    }
  }, [email, loadSettings, password, signInWithPassword]);

  const triggerGoogleSignIn = useCallback(async () => {
    setIsSubmittingHostedAction(true);
    try {
      await startGoogleSignIn();
      showSuccessToast(
        "Google sign-in opened in your browser. Complete the flow there.",
      );
    } catch (error) {
      console.error("Failed to start Google sign-in:", error);
      showErrorToast(String(error));
    } finally {
      setIsSubmittingHostedAction(false);
    }
  }, [startGoogleSignIn]);

  const enableHostedSyncMode = useCallback(async () => {
    setIsSubmittingHostedAction(true);
    try {
      await enableHostedSync();
      await loadSettings();
      showSuccessToast("Hosted sync enabled.");
      onClose(true);
    } catch (error) {
      console.error("Failed to enable hosted sync:", error);
      showErrorToast(String(error));
    } finally {
      setIsSubmittingHostedAction(false);
    }
  }, [enableHostedSync, loadSettings, onClose]);

  const disableHostedSyncMode = useCallback(async () => {
    setIsSubmittingHostedAction(true);
    try {
      await disableHostedSync();
      await loadSettings();
      showSuccessToast("Hosted sync disabled.");
    } catch (error) {
      console.error("Failed to disable hosted sync:", error);
      showErrorToast(String(error));
    } finally {
      setIsSubmittingHostedAction(false);
    }
  }, [disableHostedSync, loadSettings]);

  const logoutHostedAccount = useCallback(async () => {
    setIsSubmittingHostedAction(true);
    try {
      await logout();
      await loadSettings();
      showSuccessToast("Hosted account signed out.");
    } catch (error) {
      console.error("Failed to sign out of hosted account:", error);
      showErrorToast(String(error));
    } finally {
      setIsSubmittingHostedAction(false);
    }
  }, [loadSettings, logout]);

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

  const hostedStatusMessage = useMemo(() => {
    if (hostedCloudDisabled) {
      return "Hosted account auth is not configured in this build yet.";
    }
    if (!hostedSyncAvailable) {
      if (!isLoggedIn) {
        return "Hosted account sign-in is available. Hosted sync will stay disabled until this build is given a TWITTERBROWSER_CLOUD_SYNC_URL.";
      }
      return "Your hosted account is connected. Hosted sync activation is unavailable until this build is given a TWITTERBROWSER_CLOUD_SYNC_URL.";
    }
    if (!isLoggedIn) {
      return "Sign in to your hosted TwitterBrowser account, then explicitly enable hosted sync.";
    }
    if (hostedSyncEnabled && activeSyncMode === "hosted") {
      return "Hosted sync is active for this app instance.";
    }
    return "Your hosted account is connected. Enable hosted sync when you want cloud-backed sync to become active.";
  }, [
    activeSyncMode,
    hostedCloudDisabled,
    hostedSyncAvailable,
    hostedSyncEnabled,
    isLoggedIn,
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
                  {hostedSyncEnabled && activeSyncMode === "hosted"
                    ? "Enabled"
                    : "Disabled"}
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

          <div className="flex flex-wrap gap-2">
            <LoadingButton
              type="button"
              isLoading={isSubmittingHostedAction}
              onClick={enableHostedSyncMode}
              disabled={
                !hostedSyncAvailable ||
                (hostedSyncEnabled && activeSyncMode === "hosted")
              }
            >
              Enable Hosted Sync
            </LoadingButton>
            <LoadingButton
              type="button"
              variant="outline"
              isLoading={isSubmittingHostedAction}
              onClick={disableHostedSyncMode}
              disabled={!hostedSyncEnabled && activeSyncMode !== "hosted"}
            >
              Disable Hosted Sync
            </LoadingButton>
            <LoadingButton
              type="button"
              variant="outline"
              isLoading={isSubmittingHostedAction}
              onClick={refreshHostedAccount}
            >
              Refresh Account
            </LoadingButton>
            <LoadingButton
              type="button"
              variant="destructive"
              isLoading={isSubmittingHostedAction}
              onClick={logoutHostedAccount}
            >
              Sign Out
            </LoadingButton>
          </div>
        </div>
      ) : (
        <div className="grid gap-5">
          {!hostedSyncAvailable ? (
            <div className="rounded-md border border-dashed p-4 text-sm text-muted-foreground">
              Hosted account sign-in is ready. Add
              `TWITTERBROWSER_CLOUD_SYNC_URL` to this build when you are ready
              to activate hosted sync.
            </div>
          ) : null}

          <div className="grid gap-3 rounded-md border p-4">
            <div className="font-medium text-foreground">
              Sign in with Email and Password
            </div>
            <div className="grid gap-2">
              <Label htmlFor="hosted-email-password-email">Email</Label>
              <Input
                id="hosted-email-password-email"
                type="email"
                value={email}
                onChange={(event) => setEmail(event.target.value)}
                placeholder="you@example.com"
              />
            </div>
            <div className="grid gap-2">
              <Label htmlFor="hosted-email-password-password">Password</Label>
              <Input
                id="hosted-email-password-password"
                type="password"
                value={password}
                onChange={(event) => setPassword(event.target.value)}
                placeholder="Enter your password"
              />
            </div>
            <LoadingButton
              type="button"
              isLoading={isSubmittingHostedAction}
              onClick={signInWithEmailPassword}
            >
              Sign In
            </LoadingButton>
          </div>

          <div className="grid gap-3 rounded-md border p-4">
            <div className="font-medium text-foreground">
              Sign in with Email Code
            </div>
            <div className="grid gap-2">
              <Label htmlFor="hosted-email-otp-email">Email</Label>
              <Input
                id="hosted-email-otp-email"
                type="email"
                value={email}
                onChange={(event) => setEmail(event.target.value)}
                placeholder="you@example.com"
              />
            </div>
            {codeSent ? (
              <div className="grid gap-2">
                <Label htmlFor="hosted-email-otp-code">Verification Code</Label>
                <Input
                  id="hosted-email-otp-code"
                  value={otpCode}
                  onChange={(event) => setOtpCode(event.target.value)}
                  placeholder="123456"
                />
              </div>
            ) : null}
            <div className="flex flex-wrap gap-2">
              <LoadingButton
                type="button"
                variant="outline"
                isLoading={isSubmittingHostedAction}
                onClick={sendOtp}
              >
                Send Code
              </LoadingButton>
              <LoadingButton
                type="button"
                isLoading={isSubmittingHostedAction}
                onClick={verifyEmailOtp}
                disabled={!codeSent || !otpCode.trim()}
              >
                Verify Code
              </LoadingButton>
            </div>
          </div>

          <div className="grid gap-3 rounded-md border p-4">
            <div className="font-medium text-foreground">
              Sign in with Google
            </div>
            <div className="text-sm text-muted-foreground">
              TwitterBrowser will open your browser and complete the OAuth flow
              through the configured deep link callback.
            </div>
            <LoadingButton
              type="button"
              variant="outline"
              isLoading={isSubmittingHostedAction}
              onClick={triggerGoogleSignIn}
            >
              Continue with Google
            </LoadingButton>
          </div>
        </div>
      )}
    </div>
  );

  return (
    <Dialog open={isOpen} onOpenChange={(open) => !open && onClose(false)}>
      <DialogContent className="max-w-2xl">
        <DialogHeader>
          <DialogTitle>
            {t("sync.config.title", "Sync Configuration")}
          </DialogTitle>
          <DialogDescription>
            Manage self-hosted and hosted sync independently. Hosted sync only
            becomes active after you explicitly enable it.
          </DialogDescription>
        </DialogHeader>

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

        <DialogFooter>
          <Button variant="outline" onClick={() => onClose(false)}>
            {t("common.actions.close", "Close")}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
