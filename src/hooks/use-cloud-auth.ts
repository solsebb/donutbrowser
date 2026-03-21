import { invoke } from "@tauri-apps/api/core";
import { listen } from "@tauri-apps/api/event";
import { useCallback, useEffect, useState } from "react";
import type { CloudAuthState, CloudUser } from "@/types";

interface UseCloudAuthReturn {
  user: CloudUser | null;
  isLoggedIn: boolean;
  isLoading: boolean;
  lastError: string | null;
  requestOtp: (email: string) => Promise<string>;
  verifyOtp: (email: string, code: string) => Promise<CloudAuthState>;
  signInWithPassword: (
    email: string,
    password: string,
  ) => Promise<CloudAuthState>;
  startGoogleSignIn: () => Promise<void>;
  enableHostedSync: () => Promise<void>;
  disableHostedSync: () => Promise<void>;
  logout: () => Promise<void>;
  refreshProfile: () => Promise<CloudUser>;
  clearLastError: () => void;
}

export function useCloudAuth(): UseCloudAuthReturn {
  const [authState, setAuthState] = useState<CloudAuthState | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [lastError, setLastError] = useState<string | null>(null);

  const loadUser = useCallback(async () => {
    try {
      const state = await invoke<CloudAuthState | null>("hosted_auth_get_user");
      setAuthState(state);
    } catch (error) {
      console.error("Failed to load cloud auth state:", error);
      setAuthState(null);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    loadUser();

    const unlistenExpired = listen("cloud-auth-expired", () => {
      setAuthState(null);
    });

    const unlistenChanged = listen("cloud-auth-changed", () => {
      loadUser();
    });

    const unlistenError = listen<string>("cloud-auth-error", (event) => {
      setLastError(event.payload);
    });

    return () => {
      void unlistenExpired.then((unlisten) => {
        unlisten();
      });
      void unlistenChanged.then((unlisten) => {
        unlisten();
      });
      void unlistenError.then((unlisten) => {
        unlisten();
      });
    };
  }, [loadUser]);

  const clearLastError = useCallback(() => {
    setLastError(null);
  }, []);

  const requestOtp = useCallback(async (email: string): Promise<string> => {
    return invoke<string>("hosted_auth_request_email_otp", { email });
  }, []);

  const verifyOtp = useCallback(
    async (email: string, code: string): Promise<CloudAuthState> => {
      const state = await invoke<CloudAuthState>(
        "hosted_auth_verify_email_otp",
        {
          email,
          code,
        },
      );
      setAuthState(state);
      return state;
    },
    [],
  );

  const signInWithPassword = useCallback(
    async (email: string, password: string): Promise<CloudAuthState> => {
      const state = await invoke<CloudAuthState>(
        "hosted_auth_sign_in_with_password",
        {
          email,
          password,
        },
      );
      setAuthState(state);
      return state;
    },
    [],
  );

  const startGoogleSignIn = useCallback(async () => {
    await invoke("hosted_auth_start_google_sign_in");
  }, []);

  const enableHostedSync = useCallback(async () => {
    await invoke("hosted_sync_enable");
  }, []);

  const disableHostedSync = useCallback(async () => {
    await invoke("hosted_sync_disable");
  }, []);

  const logout = useCallback(async () => {
    await invoke("hosted_auth_logout");
    setAuthState(null);
  }, []);

  const refreshProfile = useCallback(async (): Promise<CloudUser> => {
    const user = await invoke<CloudUser>("cloud_refresh_profile");
    setAuthState((prev) =>
      prev
        ? { ...prev, user }
        : { user, logged_in_at: new Date().toISOString() },
    );
    return user;
  }, []);

  return {
    user: authState?.user ?? null,
    isLoggedIn: authState !== null,
    isLoading,
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
  };
}
