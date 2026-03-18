use crate::app_dirs;
use serde::Serialize;
use std::fs;
use std::path::PathBuf;

#[derive(Debug, Serialize)]
struct LocalApiCompanionStatus<'a> {
  port: u16,
  token: &'a str,
  base_url: String,
  updated_at: String,
}

pub fn status_file_path() -> PathBuf {
  app_dirs::settings_dir().join("local_api_companion.json")
}

pub fn write_status(port: u16, token: &str) -> Result<(), String> {
  let path = status_file_path();
  if let Some(parent) = path.parent() {
    fs::create_dir_all(parent)
      .map_err(|e| format!("Failed to create companion status directory: {e}"))?;
  }

  let payload = LocalApiCompanionStatus {
    port,
    token,
    base_url: format!("http://127.0.0.1:{port}"),
    updated_at: chrono::Utc::now().to_rfc3339(),
  };

  let json = serde_json::to_string_pretty(&payload)
    .map_err(|e| format!("Failed to serialize companion status file: {e}"))?;
  fs::write(&path, json).map_err(|e| format!("Failed to write companion status file: {e}"))?;

  #[cfg(unix)]
  {
    use std::os::unix::fs::PermissionsExt;
    let _ = fs::set_permissions(&path, fs::Permissions::from_mode(0o600));
  }

  Ok(())
}

pub fn clear_status() -> Result<(), String> {
  let path = status_file_path();
  if path.exists() {
    fs::remove_file(path).map_err(|e| format!("Failed to remove companion status file: {e}"))?;
  }
  Ok(())
}
