"use client";

import { invoke } from "@tauri-apps/api/core";
import { createContext, useContext, useEffect, useMemo, useState } from "react";
import type { RuntimeAppConfig } from "@/types";

const DEFAULT_RUNTIME_APP_CONFIG: RuntimeAppConfig = {
  display_name: "TwitterBrowser",
  homepage_url: null,
  support_url: null,
  account_url: null,
  cross_os_profiles_enabled: true,
  cookie_tools_enabled: true,
  extension_tools_enabled: true,
  self_hosted_sync_enabled: true,
  hosted_cloud_enabled: false,
  hosted_cloud_ui_mode: "disabled",
  commercial_license_ui_enabled: false,
  updater_enabled: false,
  release_page_base_url: null,
};

const RuntimeAppConfigContext = createContext<RuntimeAppConfig>(
  DEFAULT_RUNTIME_APP_CONFIG,
);

export function RuntimeAppConfigProvider({
  children,
}: {
  children: React.ReactNode;
}) {
  const [config, setConfig] = useState<RuntimeAppConfig>(
    DEFAULT_RUNTIME_APP_CONFIG,
  );

  useEffect(() => {
    let cancelled = false;

    const loadConfig = async () => {
      try {
        const runtimeConfig = await invoke<RuntimeAppConfig>(
          "get_runtime_app_config",
        );
        if (!cancelled) {
          setConfig({
            ...DEFAULT_RUNTIME_APP_CONFIG,
            ...runtimeConfig,
          });
        }
      } catch (error) {
        console.error("Failed to load runtime app config:", error);
      }
    };

    void loadConfig();

    return () => {
      cancelled = true;
    };
  }, []);

  const value = useMemo(() => config, [config]);

  return (
    <RuntimeAppConfigContext.Provider value={value}>
      {children}
    </RuntimeAppConfigContext.Provider>
  );
}

export function useRuntimeAppConfig() {
  return useContext(RuntimeAppConfigContext);
}
