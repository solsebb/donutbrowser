use serde::Serialize;
use std::sync::OnceLock;

const DISPLAY_NAME: &str = "TwitterBrowser";
const DEV_DISPLAY_NAME: &str = "TwitterBrowserDev";
const BUNDLE_ID: &str = "com.twitterbrowser";
const GUI_BINARY_NAME: &str = "twitterbrowser";
const DAEMON_BINARY_NAME: &str = "twitter-daemon";
const PROXY_BINARY_NAME: &str = "twitter-proxy";
const LINUX_DESKTOP_FILE_NAME: &str = "twitterbrowser.desktop";
const WINDOWS_PROG_ID: &str = "TwitterBrowser.HTML";
const WINDOWS_REGISTERED_APP_NAME: &str = "TwitterBrowser";
const USER_AGENT_TOKEN: &str = "twitterbrowser";
const EPHEMERAL_VOLUME_NAME: &str = "TwitterBrowserEphemeral";
const EPHEMERAL_BASE_DIR_NAME: &str = "twitterbrowser-ephemeral";

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RuntimeAppConfig {
  pub display_name: String,
  pub dev_display_name: String,
  pub bundle_id: String,
  pub gui_binary_name: String,
  pub daemon_binary_name: String,
  pub proxy_binary_name: String,
  pub linux_desktop_file_name: String,
  pub windows_prog_id: String,
  pub windows_registered_app_name: String,
  pub user_agent_token: String,
  pub ephemeral_volume_name: String,
  pub ephemeral_base_dir_name: String,
  pub homepage_url: Option<String>,
  pub support_url: Option<String>,
  pub account_url: Option<String>,
  pub cloud_api_url: Option<String>,
  pub cloud_sync_url: Option<String>,
  pub releases_api_url: Option<String>,
  pub releases_page_url: Option<String>,
  pub wayfern_metadata_url: Option<String>,
}

#[derive(Debug, Clone, Serialize, PartialEq, Eq)]
pub struct FrontendRuntimeAppConfig {
  pub display_name: String,
  pub homepage_url: Option<String>,
  pub support_url: Option<String>,
  pub account_url: Option<String>,
  pub hosted_cloud_enabled: bool,
  pub updater_enabled: bool,
  pub release_page_base_url: Option<String>,
}

impl RuntimeAppConfig {
  pub fn hosted_cloud_enabled(&self) -> bool {
    self.cloud_api_url.is_some() && self.cloud_sync_url.is_some()
  }

  pub fn updater_enabled(&self) -> bool {
    self.releases_api_url.is_some()
  }

  #[allow(dead_code)]
  pub fn current_display_name(&self) -> &str {
    if cfg!(debug_assertions) {
      &self.dev_display_name
    } else {
      &self.display_name
    }
  }

  pub fn gui_executable_name(&self) -> String {
    executable_name_for_current_platform(&self.gui_binary_name)
  }

  pub fn daemon_executable_name(&self) -> String {
    executable_name_for_current_platform(&self.daemon_binary_name)
  }

  #[allow(dead_code)]
  pub fn proxy_executable_name(&self) -> String {
    executable_name_for_current_platform(&self.proxy_binary_name)
  }

  pub fn frontend_config(&self) -> FrontendRuntimeAppConfig {
    FrontendRuntimeAppConfig {
      display_name: self.display_name.clone(),
      homepage_url: self.homepage_url.clone(),
      support_url: self.support_url.clone(),
      account_url: self.account_url.clone(),
      hosted_cloud_enabled: self.hosted_cloud_enabled(),
      updater_enabled: self.updater_enabled(),
      release_page_base_url: self.releases_page_url.clone(),
    }
  }
}

fn executable_name_for_current_platform(base_name: &str) -> String {
  #[cfg(windows)]
  {
    format!("{base_name}.exe")
  }

  #[cfg(not(windows))]
  {
    base_name.to_string()
  }
}

fn env_lookup(name: &str) -> Option<String> {
  std::env::var(name).ok()
}

fn normalized_optional_env<F>(lookup: &F, name: &str) -> Option<String>
where
  F: Fn(&str) -> Option<String>,
{
  lookup(name).and_then(|value| {
    let trimmed = value.trim();
    if trimmed.is_empty() {
      None
    } else {
      Some(trimmed.to_string())
    }
  })
}

fn compile_time_optional(name: &str) -> Option<String> {
  match name {
    "TWITTERBROWSER_HOMEPAGE_URL" => option_env!("TWITTERBROWSER_HOMEPAGE_URL").map(str::to_string),
    "TWITTERBROWSER_SUPPORT_URL" => option_env!("TWITTERBROWSER_SUPPORT_URL").map(str::to_string),
    "TWITTERBROWSER_ACCOUNT_URL" => option_env!("TWITTERBROWSER_ACCOUNT_URL").map(str::to_string),
    "TWITTERBROWSER_CLOUD_API_URL" => {
      option_env!("TWITTERBROWSER_CLOUD_API_URL").map(str::to_string)
    }
    "TWITTERBROWSER_CLOUD_SYNC_URL" => {
      option_env!("TWITTERBROWSER_CLOUD_SYNC_URL").map(str::to_string)
    }
    "TWITTERBROWSER_RELEASES_API_URL" => {
      option_env!("TWITTERBROWSER_RELEASES_API_URL").map(str::to_string)
    }
    "TWITTERBROWSER_RELEASES_PAGE_URL" => {
      option_env!("TWITTERBROWSER_RELEASES_PAGE_URL").map(str::to_string)
    }
    "TWITTERBROWSER_WAYFERN_METADATA_URL" => {
      option_env!("TWITTERBROWSER_WAYFERN_METADATA_URL").map(str::to_string)
    }
    _ => None,
  }
}

fn optional_setting<F>(lookup: &F, name: &str) -> Option<String>
where
  F: Fn(&str) -> Option<String>,
{
  normalized_optional_env(lookup, name).or_else(|| compile_time_optional(name))
}

pub fn resolve_with_lookup<F>(lookup: F) -> RuntimeAppConfig
where
  F: Fn(&str) -> Option<String>,
{
  RuntimeAppConfig {
    display_name: DISPLAY_NAME.to_string(),
    dev_display_name: DEV_DISPLAY_NAME.to_string(),
    bundle_id: BUNDLE_ID.to_string(),
    gui_binary_name: GUI_BINARY_NAME.to_string(),
    daemon_binary_name: DAEMON_BINARY_NAME.to_string(),
    proxy_binary_name: PROXY_BINARY_NAME.to_string(),
    linux_desktop_file_name: LINUX_DESKTOP_FILE_NAME.to_string(),
    windows_prog_id: WINDOWS_PROG_ID.to_string(),
    windows_registered_app_name: WINDOWS_REGISTERED_APP_NAME.to_string(),
    user_agent_token: USER_AGENT_TOKEN.to_string(),
    ephemeral_volume_name: EPHEMERAL_VOLUME_NAME.to_string(),
    ephemeral_base_dir_name: EPHEMERAL_BASE_DIR_NAME.to_string(),
    homepage_url: optional_setting(&lookup, "TWITTERBROWSER_HOMEPAGE_URL"),
    support_url: optional_setting(&lookup, "TWITTERBROWSER_SUPPORT_URL"),
    account_url: optional_setting(&lookup, "TWITTERBROWSER_ACCOUNT_URL"),
    cloud_api_url: optional_setting(&lookup, "TWITTERBROWSER_CLOUD_API_URL"),
    cloud_sync_url: optional_setting(&lookup, "TWITTERBROWSER_CLOUD_SYNC_URL"),
    releases_api_url: optional_setting(&lookup, "TWITTERBROWSER_RELEASES_API_URL"),
    releases_page_url: optional_setting(&lookup, "TWITTERBROWSER_RELEASES_PAGE_URL"),
    wayfern_metadata_url: optional_setting(&lookup, "TWITTERBROWSER_WAYFERN_METADATA_URL"),
  }
}

pub fn current() -> &'static RuntimeAppConfig {
  static RUNTIME_APP_CONFIG: OnceLock<RuntimeAppConfig> = OnceLock::new();
  RUNTIME_APP_CONFIG.get_or_init(|| resolve_with_lookup(env_lookup))
}

#[tauri::command]
pub fn get_runtime_app_config() -> FrontendRuntimeAppConfig {
  current().frontend_config()
}

#[cfg(test)]
mod tests {
  use super::*;
  use std::collections::HashMap;

  fn resolve_with_map(values: &[(&str, &str)]) -> RuntimeAppConfig {
    let values = values
      .iter()
      .map(|(key, value)| ((*key).to_string(), (*value).to_string()))
      .collect::<HashMap<_, _>>();
    resolve_with_lookup(|name| values.get(name).cloned())
  }

  #[test]
  fn default_config_disables_hosted_cloud_and_updater() {
    let config = resolve_with_map(&[]);
    assert_eq!(config.display_name, DISPLAY_NAME);
    assert_eq!(config.gui_binary_name, GUI_BINARY_NAME);
    assert!(!config.hosted_cloud_enabled());
    assert!(!config.updater_enabled());
    assert_eq!(config.wayfern_metadata_url, None);
  }

  #[test]
  fn runtime_env_enables_hosted_cloud_and_updater() {
    let config = resolve_with_map(&[
      ("TWITTERBROWSER_CLOUD_API_URL", "https://api.example.com"),
      ("TWITTERBROWSER_CLOUD_SYNC_URL", "https://sync.example.com"),
      (
        "TWITTERBROWSER_RELEASES_API_URL",
        "https://api.github.com/repos/example/twitterbrowser/releases",
      ),
      (
        "TWITTERBROWSER_RELEASES_PAGE_URL",
        "https://github.com/example/twitterbrowser/releases",
      ),
      (
        "TWITTERBROWSER_WAYFERN_METADATA_URL",
        "https://metadata.example.com/wayfern.json",
      ),
    ]);

    assert!(config.hosted_cloud_enabled());
    assert!(config.updater_enabled());
    assert_eq!(
      config.wayfern_metadata_url,
      Some("https://metadata.example.com/wayfern.json".to_string())
    );
    assert_eq!(
      config.frontend_config().release_page_base_url,
      Some("https://github.com/example/twitterbrowser/releases".to_string())
    );
  }

  #[test]
  fn blank_env_values_are_treated_as_missing() {
    let config = resolve_with_map(&[
      ("TWITTERBROWSER_CLOUD_API_URL", " "),
      ("TWITTERBROWSER_CLOUD_SYNC_URL", ""),
      ("TWITTERBROWSER_RELEASES_API_URL", "\n\t"),
    ]);

    assert!(!config.hosted_cloud_enabled());
    assert!(!config.updater_enabled());
  }

  #[test]
  fn executable_names_match_platform() {
    let config = resolve_with_map(&[]);

    #[cfg(windows)]
    {
      assert_eq!(config.gui_executable_name(), "twitterbrowser.exe");
      assert_eq!(config.daemon_executable_name(), "twitter-daemon.exe");
      assert_eq!(config.proxy_executable_name(), "twitter-proxy.exe");
    }

    #[cfg(not(windows))]
    {
      assert_eq!(config.gui_executable_name(), "twitterbrowser");
      assert_eq!(config.daemon_executable_name(), "twitter-daemon");
      assert_eq!(config.proxy_executable_name(), "twitter-proxy");
    }
  }
}
