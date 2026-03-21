import { invoke } from "@tauri-apps/api/core";
import { listen } from "@tauri-apps/api/event";
import { useCallback, useEffect, useMemo, useState } from "react";
import { useTranslation } from "react-i18next";
import { FaDownload } from "react-icons/fa";
import { FiWifi } from "react-icons/fi";
import { GoGear, GoKebabHorizontal, GoPlus } from "react-icons/go";
import {
  LuCloud,
  LuPlug,
  LuPuzzle,
  LuSearch,
  LuUsers,
  LuX,
} from "react-icons/lu";
import { useCloudAuth } from "@/hooks/use-cloud-auth";
import { cn } from "@/lib/utils";
import type { SyncSettings } from "@/types";
import { Logo } from "./icons/logo";
import { useRuntimeAppConfig } from "./runtime-app-config-provider";
import { Button } from "./ui/button";
import { CardTitle } from "./ui/card";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "./ui/dropdown-menu";
import { Input } from "./ui/input";
import { Tooltip, TooltipContent, TooltipTrigger } from "./ui/tooltip";

type Props = {
  onSettingsDialogOpen: (open: boolean) => void;
  onProxyManagementDialogOpen: (open: boolean) => void;
  onGroupManagementDialogOpen: (open: boolean) => void;
  onImportProfileDialogOpen: (open: boolean) => void;
  onCreateProfileDialogOpen: (open: boolean) => void;
  onSyncConfigDialogOpen: (open: boolean) => void;
  onIntegrationsDialogOpen: (open: boolean) => void;
  onExtensionManagementDialogOpen: (open: boolean) => void;
  searchQuery: string;
  onSearchQueryChange: (query: string) => void;
  extensionToolsEnabled?: boolean;
};

const HomeHeader = ({
  onSettingsDialogOpen,
  onProxyManagementDialogOpen,
  onGroupManagementDialogOpen,
  onImportProfileDialogOpen,
  onCreateProfileDialogOpen,
  onSyncConfigDialogOpen,
  onIntegrationsDialogOpen,
  onExtensionManagementDialogOpen,
  searchQuery,
  onSearchQueryChange,
  extensionToolsEnabled = true,
}: Props) => {
  const { t } = useTranslation();
  const runtimeConfig = useRuntimeAppConfig();
  const { isLoggedIn, user } = useCloudAuth();
  const [syncSettings, setSyncSettings] = useState<SyncSettings | null>(null);

  const loadSyncSettings = useCallback(async () => {
    try {
      const settings = await invoke<SyncSettings>("get_sync_settings");
      setSyncSettings(settings);
    } catch (error) {
      console.error("Failed to load sync settings for header:", error);
      setSyncSettings(null);
    }
  }, []);

  useEffect(() => {
    if (!isLoggedIn || runtimeConfig.hosted_cloud_ui_mode === "hidden") {
      setSyncSettings(null);
      return;
    }

    void loadSyncSettings();

    const unlisten = listen("cloud-auth-changed", () => {
      void loadSyncSettings();
    });

    return () => {
      void unlisten.then((dispose) => {
        dispose();
      });
    };
  }, [isLoggedIn, loadSyncSettings, runtimeConfig.hosted_cloud_ui_mode]);

  const hostedStatus = useMemo(() => {
    if (!isLoggedIn || runtimeConfig.hosted_cloud_ui_mode === "hidden") {
      return null;
    }

    if (
      syncSettings?.hosted_sync_enabled &&
      syncSettings.active_sync_mode === "hosted"
    ) {
      return {
        label: t("sync.hosted.headerActive"),
        tooltip: t("sync.hosted.headerActiveHint"),
        className:
          "border-success/50 bg-success/10 text-success hover:bg-success/15",
      };
    }

    return {
      label: t("sync.hosted.headerInactive"),
      tooltip: user?.email
        ? t("sync.hosted.headerInactiveHintWithEmail", { email: user.email })
        : t("sync.hosted.headerInactiveHint"),
      className:
        "border-warning/50 bg-warning/10 text-warning hover:bg-warning/15",
    };
  }, [
    isLoggedIn,
    runtimeConfig.hosted_cloud_ui_mode,
    syncSettings?.active_sync_mode,
    syncSettings?.hosted_sync_enabled,
    t,
    user?.email,
  ]);

  const handleLogoClick = () => {
    if (!runtimeConfig.homepage_url) {
      return;
    }

    // Trigger the same URL handling logic as if the URL came from the system
    const event = new CustomEvent("url-open-request", {
      detail: runtimeConfig.homepage_url,
    });
    window.dispatchEvent(event);
  };
  return (
    <div className="flex justify-between items-center mt-6">
      <div className="flex gap-3 items-center">
        <button
          type="button"
          className="p-1 cursor-pointer"
          title={
            runtimeConfig.homepage_url
              ? `Open ${runtimeConfig.display_name} homepage`
              : runtimeConfig.display_name
          }
          onClick={handleLogoClick}
          disabled={!runtimeConfig.homepage_url}
        >
          <Logo className="w-10 h-10 transition-transform duration-300 ease-out will-change-transform hover:scale-110" />
        </button>
        <CardTitle>{runtimeConfig.display_name}</CardTitle>
      </div>
      <div className="flex gap-2 items-center">
        {hostedStatus ? (
          <Tooltip>
            <TooltipTrigger asChild>
              <Button
                size="sm"
                variant="outline"
                className={cn(
                  "flex gap-2 items-center h-[36px]",
                  hostedStatus.className,
                )}
                onClick={() => {
                  onSyncConfigDialogOpen(true);
                }}
              >
                <LuCloud className="w-4 h-4" />
                <span>{hostedStatus.label}</span>
              </Button>
            </TooltipTrigger>
            <TooltipContent>{hostedStatus.tooltip}</TooltipContent>
          </Tooltip>
        ) : null}
        <div className="relative">
          <Input
            type="text"
            placeholder={t("header.searchPlaceholder")}
            value={searchQuery}
            onChange={(e) => onSearchQueryChange(e.target.value)}
            className="pr-8 pl-10 w-48"
          />
          <LuSearch className="absolute left-3 top-1/2 w-4 h-4 transform -translate-y-1/2 text-muted-foreground" />
          {searchQuery && (
            <button
              type="button"
              onClick={() => onSearchQueryChange("")}
              className="absolute right-2 top-1/2 p-1 rounded-sm transition-colors transform -translate-y-1/2 hover:bg-accent"
              aria-label={t("header.clearSearch")}
            >
              <LuX className="w-4 h-4 text-muted-foreground hover:text-foreground" />
            </button>
          )}
        </div>
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <span>
              <Tooltip>
                <TooltipTrigger asChild>
                  <span>
                    <Button
                      size="sm"
                      variant="outline"
                      className="flex gap-2 items-center h-[36px]"
                    >
                      <GoKebabHorizontal className="w-4 h-4" />
                    </Button>
                  </span>
                </TooltipTrigger>
                <TooltipContent>{t("header.moreActions")}</TooltipContent>
              </Tooltip>
            </span>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end">
            <DropdownMenuItem
              onClick={() => {
                onSettingsDialogOpen(true);
              }}
            >
              <GoGear className="mr-2 w-4 h-4" />
              {t("header.menu.settings")}
            </DropdownMenuItem>
            <DropdownMenuItem
              onClick={() => {
                onProxyManagementDialogOpen(true);
              }}
            >
              <FiWifi className="mr-2 w-4 h-4" />
              {t("header.menu.proxies")}
            </DropdownMenuItem>
            <DropdownMenuItem
              onClick={() => {
                onGroupManagementDialogOpen(true);
              }}
            >
              <LuUsers className="mr-2 w-4 h-4" />
              {t("header.menu.groups")}
            </DropdownMenuItem>
            <DropdownMenuItem
              disabled={!extensionToolsEnabled}
              className={cn(!extensionToolsEnabled && "opacity-50")}
              onClick={() => {
                onExtensionManagementDialogOpen(true);
              }}
            >
              <LuPuzzle className="mr-2 w-4 h-4" />
              {t("header.menu.extensions")}
            </DropdownMenuItem>
            <DropdownMenuItem
              onClick={() => {
                onSyncConfigDialogOpen(true);
              }}
            >
              <LuCloud className="mr-2 w-4 h-4" />
              {t("header.menu.syncService")}
            </DropdownMenuItem>
            <DropdownMenuItem
              onClick={() => {
                onIntegrationsDialogOpen(true);
              }}
            >
              <LuPlug className="mr-2 w-4 h-4" />
              {t("header.menu.integrations")}
            </DropdownMenuItem>
            <DropdownMenuItem
              onClick={() => {
                onImportProfileDialogOpen(true);
              }}
            >
              <FaDownload className="mr-2 w-4 h-4" />
              {t("header.menu.importProfile")}
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
        <Tooltip>
          <TooltipTrigger asChild>
            <span>
              <Button
                size="sm"
                onClick={() => {
                  onCreateProfileDialogOpen(true);
                }}
                className="flex gap-2 items-center h-[36px]"
              >
                <GoPlus className="w-4 h-4" />
              </Button>
            </span>
          </TooltipTrigger>
          <TooltipContent
            arrowOffset={-8}
            style={{ transform: "translateX(-8px)" }}
          >
            {t("header.createProfile")}
          </TooltipContent>
        </Tooltip>
      </div>
    </div>
  );
};

export default HomeHeader;
