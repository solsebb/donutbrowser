use serde::Serialize;
use std::fs;
use std::path::{Path, PathBuf};

use crate::{app_dirs, events};

const QUARANTINE_MANIFEST_FILE: &str = "quarantine-manifest.json";
const IMPORTABLE_DATA_FILES: &[&str] = &["tags.json", "groups.json", "extension_groups.json"];
const QUARANTINE_ENTRY_NAMES: &[&str] = &[
  "settings",
  "profiles",
  "proxies",
  "vpn",
  "extensions",
  "data",
  "binaries",
  "daemon-state.json",
];

#[derive(Debug, Clone, Serialize, PartialEq, Eq)]
pub struct DataIsolationStatus {
  pub active_data_dir: String,
  pub active_cache_dir: String,
  pub legacy_data_dir: Option<String>,
  pub legacy_data_present: bool,
  pub prior_auto_import_detected: bool,
  pub quarantine_backup_exists: bool,
  pub latest_quarantine_backup_dir: Option<String>,
}

#[derive(Debug, Clone, Serialize, PartialEq, Eq)]
pub struct LegacyImportResult {
  pub source_data_dir: String,
  pub target_data_dir: String,
  pub imported_items: usize,
  pub skipped_items: usize,
}

fn is_non_empty_dir(path: &Path) -> bool {
  match fs::read_dir(path) {
    Ok(mut entries) => entries.next().is_some(),
    Err(_) => false,
  }
}

fn detect_legacy_data_dir_with<F>(lookup: &F) -> Option<PathBuf>
where
  F: Fn(&str) -> Option<String>,
{
  app_dirs::legacy_data_dir_candidates_with(lookup)
    .into_iter()
    .find(|candidate| candidate.exists() && is_non_empty_dir(candidate))
}

fn latest_quarantine_backup_dir_for(data_root: &Path) -> Option<PathBuf> {
  let backup_root = app_dirs::isolation_backup_root_for(data_root);
  let entries = fs::read_dir(backup_root).ok()?;

  entries
    .filter_map(Result::ok)
    .filter(|entry| entry.file_type().map(|ft| ft.is_dir()).unwrap_or(false))
    .map(|entry| entry.path())
    .max()
}

fn create_quarantine_backup_dir(data_root: &Path) -> Result<PathBuf, String> {
  let backup_root = app_dirs::isolation_backup_root_for(data_root);
  fs::create_dir_all(&backup_root).map_err(|e| {
    format!(
      "Failed to create quarantine backup root {}: {e}",
      backup_root.display()
    )
  })?;

  let timestamp = std::time::SystemTime::now()
    .duration_since(std::time::UNIX_EPOCH)
    .map_err(|e| format!("Failed to compute quarantine timestamp: {e}"))?
    .as_secs();

  for attempt in 0..1000 {
    let suffix = if attempt == 0 {
      timestamp.to_string()
    } else {
      format!("{timestamp}-{attempt}")
    };
    let candidate = backup_root.join(format!("quarantine-{suffix}"));
    if !candidate.exists() {
      fs::create_dir_all(&candidate).map_err(|e| {
        format!(
          "Failed to create quarantine backup directory {}: {e}",
          candidate.display()
        )
      })?;
      return Ok(candidate);
    }
  }

  Err("Failed to allocate a unique quarantine backup directory".to_string())
}

fn move_into_backup(
  target_data_dir: &Path,
  backup_dir: &Path,
  entry_name: &str,
  moved_entries: &mut Vec<String>,
) -> Result<(), String> {
  let source = target_data_dir.join(entry_name);
  if !source.exists() {
    return Ok(());
  }

  let destination = backup_dir.join(entry_name);
  if let Some(parent) = destination.parent() {
    fs::create_dir_all(parent).map_err(|e| {
      format!(
        "Failed to create quarantine directory {}: {e}",
        parent.display()
      )
    })?;
  }

  fs::rename(&source, &destination).map_err(|e| {
    format!(
      "Failed to move {} to quarantine {}: {e}",
      source.display(),
      destination.display()
    )
  })?;

  moved_entries.push(entry_name.to_string());
  Ok(())
}

fn write_quarantine_manifest(
  target_data_dir: &Path,
  backup_dir: &Path,
  moved_entries: &[String],
) -> Result<(), String> {
  let manifest_path = backup_dir.join(QUARANTINE_MANIFEST_FILE);
  let payload = serde_json::json!({
    "source_data_dir": target_data_dir,
    "quarantined_at": std::time::SystemTime::now()
      .duration_since(std::time::UNIX_EPOCH)
      .map_err(|e| format!("Failed to compute quarantine timestamp: {e}"))?
      .as_secs(),
    "moved_entries": moved_entries,
  });

  fs::write(
    &manifest_path,
    serde_json::to_string_pretty(&payload)
      .map_err(|e| format!("Failed to serialize quarantine manifest: {e}"))?,
  )
  .map_err(|e| {
    format!(
      "Failed to write quarantine manifest {}: {e}",
      manifest_path.display()
    )
  })
}

fn quarantine_auto_imported_store_if_needed_with(
  target_data_dir: &Path,
) -> Result<Option<PathBuf>, String> {
  let sentinel_path = app_dirs::legacy_import_sentinel_path(target_data_dir);
  if !sentinel_path.exists() {
    return Ok(None);
  }

  let backup_dir = create_quarantine_backup_dir(target_data_dir)?;
  let mut moved_entries = Vec::new();

  for entry_name in QUARANTINE_ENTRY_NAMES {
    move_into_backup(target_data_dir, &backup_dir, entry_name, &mut moved_entries)?;
  }

  fs::create_dir_all(target_data_dir).map_err(|e| {
    format!(
      "Failed to recreate active data directory {}: {e}",
      target_data_dir.display()
    )
  })?;

  write_quarantine_manifest(target_data_dir, &backup_dir, &moved_entries)?;
  Ok(Some(backup_dir))
}

pub fn bootstrap_data_isolation() -> Result<Option<PathBuf>, String> {
  quarantine_auto_imported_store_if_needed_with(&app_dirs::data_dir())
}

fn copy_dir_recursive(src: &Path, dst: &Path) -> Result<(), String> {
  fs::create_dir_all(dst).map_err(|e| {
    format!(
      "Failed to create destination directory {}: {e}",
      dst.display()
    )
  })?;

  for entry in fs::read_dir(src)
    .map_err(|e| format!("Failed to read source directory {}: {e}", src.display()))?
  {
    let entry = entry.map_err(|e| format!("Failed to read directory entry: {e}"))?;
    let source_path = entry.path();
    let destination_path = dst.join(entry.file_name());
    let file_type = entry.file_type().map_err(|e| {
      format!(
        "Failed to read file type for {}: {e}",
        source_path.display()
      )
    })?;

    if file_type.is_dir() {
      copy_dir_recursive(&source_path, &destination_path)?;
    } else if file_type.is_file() {
      if let Some(parent) = destination_path.parent() {
        fs::create_dir_all(parent).map_err(|e| {
          format!(
            "Failed to create parent directory {}: {e}",
            parent.display()
          )
        })?;
      }
      fs::copy(&source_path, &destination_path).map_err(|e| {
        format!(
          "Failed to copy {} to {}: {e}",
          source_path.display(),
          destination_path.display()
        )
      })?;
    }
  }

  Ok(())
}

fn import_child_entries(
  source_dir: &Path,
  target_dir: &Path,
  imported_items: &mut usize,
  skipped_items: &mut usize,
) -> Result<(), String> {
  if !source_dir.exists() {
    return Ok(());
  }

  fs::create_dir_all(target_dir).map_err(|e| {
    format!(
      "Failed to create import target directory {}: {e}",
      target_dir.display()
    )
  })?;

  for entry in fs::read_dir(source_dir)
    .map_err(|e| format!("Failed to read import source {}: {e}", source_dir.display()))?
  {
    let entry = entry.map_err(|e| format!("Failed to read import entry: {e}"))?;
    let source_path = entry.path();
    let destination_path = target_dir.join(entry.file_name());

    if destination_path.exists() {
      *skipped_items += 1;
      continue;
    }

    if entry
      .file_type()
      .map_err(|e| {
        format!(
          "Failed to read file type for {}: {e}",
          source_path.display()
        )
      })?
      .is_dir()
    {
      copy_dir_recursive(&source_path, &destination_path)?;
    } else {
      fs::copy(&source_path, &destination_path).map_err(|e| {
        format!(
          "Failed to copy {} to {}: {e}",
          source_path.display(),
          destination_path.display()
        )
      })?;
    }

    *imported_items += 1;
  }

  Ok(())
}

fn import_selected_data_files(
  source_data_dir: &Path,
  target_data_dir: &Path,
  imported_items: &mut usize,
  skipped_items: &mut usize,
) -> Result<(), String> {
  if !source_data_dir.exists() {
    return Ok(());
  }

  fs::create_dir_all(target_data_dir).map_err(|e| {
    format!(
      "Failed to create target data directory {}: {e}",
      target_data_dir.display()
    )
  })?;

  for file_name in IMPORTABLE_DATA_FILES {
    let source_path = source_data_dir.join(file_name);
    if !source_path.exists() {
      continue;
    }

    let destination_path = target_data_dir.join(file_name);
    if destination_path.exists() {
      *skipped_items += 1;
      continue;
    }

    fs::copy(&source_path, &destination_path).map_err(|e| {
      format!(
        "Failed to copy {} to {}: {e}",
        source_path.display(),
        destination_path.display()
      )
    })?;

    *imported_items += 1;
  }

  Ok(())
}

fn import_legacy_donut_data_with<F>(
  lookup: &F,
  target_data_dir: &Path,
) -> Result<LegacyImportResult, String>
where
  F: Fn(&str) -> Option<String>,
{
  let source_data_dir = detect_legacy_data_dir_with(lookup)
    .ok_or_else(|| "No DonutBrowser data store was found for import".to_string())?;

  if source_data_dir == target_data_dir {
    return Err("Refusing to import from the active TwitterBrowser data directory".to_string());
  }

  fs::create_dir_all(target_data_dir).map_err(|e| {
    format!(
      "Failed to create active data directory {}: {e}",
      target_data_dir.display()
    )
  })?;

  let mut imported_items = 0usize;
  let mut skipped_items = 0usize;

  import_child_entries(
    &source_data_dir.join("profiles"),
    &target_data_dir.join("profiles"),
    &mut imported_items,
    &mut skipped_items,
  )?;
  import_child_entries(
    &source_data_dir.join("proxies"),
    &target_data_dir.join("proxies"),
    &mut imported_items,
    &mut skipped_items,
  )?;
  import_child_entries(
    &source_data_dir.join("extensions"),
    &target_data_dir.join("extensions"),
    &mut imported_items,
    &mut skipped_items,
  )?;
  import_child_entries(
    &source_data_dir.join("vpn"),
    &target_data_dir.join("vpn"),
    &mut imported_items,
    &mut skipped_items,
  )?;
  import_selected_data_files(
    &source_data_dir.join("data"),
    &target_data_dir.join("data"),
    &mut imported_items,
    &mut skipped_items,
  )?;

  Ok(LegacyImportResult {
    source_data_dir: source_data_dir.display().to_string(),
    target_data_dir: target_data_dir.display().to_string(),
    imported_items,
    skipped_items,
  })
}

fn emit_import_events() {
  let _ = events::emit_empty("profiles-changed");
  let _ = events::emit_empty("stored-proxies-changed");
  let _ = events::emit_empty("groups-changed");
  let _ = events::emit_empty("vpn-configs-changed");
  let _ = events::emit_empty("extensions-changed");
}

fn data_isolation_status_with<F>(
  lookup: &F,
  active_data_dir: &Path,
  active_cache_dir: &Path,
) -> DataIsolationStatus
where
  F: Fn(&str) -> Option<String>,
{
  let legacy_data_dir = detect_legacy_data_dir_with(lookup);
  let latest_backup_dir = latest_quarantine_backup_dir_for(active_data_dir);
  let active_sentinel_present = app_dirs::legacy_import_sentinel_path(active_data_dir).exists();

  DataIsolationStatus {
    active_data_dir: active_data_dir.display().to_string(),
    active_cache_dir: active_cache_dir.display().to_string(),
    legacy_data_dir: legacy_data_dir
      .as_ref()
      .map(|path| path.display().to_string()),
    legacy_data_present: legacy_data_dir.is_some(),
    prior_auto_import_detected: active_sentinel_present || latest_backup_dir.is_some(),
    quarantine_backup_exists: latest_backup_dir.is_some(),
    latest_quarantine_backup_dir: latest_backup_dir
      .as_ref()
      .map(|path| path.display().to_string()),
  }
}

#[tauri::command]
pub fn get_data_isolation_status() -> Result<DataIsolationStatus, String> {
  Ok(data_isolation_status_with(
    &|name| std::env::var(name).ok(),
    &app_dirs::data_dir(),
    &app_dirs::cache_dir(),
  ))
}

#[tauri::command]
pub fn import_legacy_donut_data() -> Result<LegacyImportResult, String> {
  let result =
    import_legacy_donut_data_with(&|name| std::env::var(name).ok(), &app_dirs::data_dir())?;
  emit_import_events();
  Ok(result)
}

#[cfg(test)]
mod tests {
  use super::*;
  use serde_json::Value;
  use std::collections::HashMap;

  fn lookup_from_map(values: &[(&str, &str)]) -> impl Fn(&str) -> Option<String> {
    let values = values
      .iter()
      .map(|(key, value)| ((*key).to_string(), (*value).to_string()))
      .collect::<HashMap<_, _>>();
    move |name| values.get(name).cloned()
  }

  fn create_auto_imported_target(target_data_dir: &Path) {
    fs::create_dir_all(target_data_dir.join("settings")).unwrap();
    fs::create_dir_all(target_data_dir.join("profiles").join("profile-a")).unwrap();
    fs::create_dir_all(target_data_dir.join("data")).unwrap();
    fs::write(
      app_dirs::legacy_import_sentinel_path(target_data_dir),
      "{\"imported_from\":\"/tmp/DonutBrowser\"}",
    )
    .unwrap();
    fs::write(
      target_data_dir.join("settings").join("app_settings.json"),
      "{\"sync_server_url\":\"https://example.com\"}",
    )
    .unwrap();
    fs::write(
      target_data_dir.join("settings").join("sync_token.dat"),
      b"token-bytes",
    )
    .unwrap();
    fs::write(
      target_data_dir.join("data").join("tags.json"),
      "[\"tag-a\"]",
    )
    .unwrap();
    fs::write(
      target_data_dir
        .join("profiles")
        .join("profile-a")
        .join("metadata.json"),
      "{}",
    )
    .unwrap();
  }

  #[test]
  fn quarantine_resets_auto_imported_store_and_preserves_backup() {
    let temp_dir = tempfile::tempdir().unwrap();
    let target_data_dir = temp_dir.path().join("TwitterBrowser");
    create_auto_imported_target(&target_data_dir);

    let backup_dir = quarantine_auto_imported_store_if_needed_with(&target_data_dir)
      .unwrap()
      .unwrap();

    assert!(backup_dir
      .join("settings")
      .join("app_settings.json")
      .exists());
    assert!(backup_dir.join("profiles").join("profile-a").exists());
    assert!(!app_dirs::legacy_import_sentinel_path(&target_data_dir).exists());
    assert!(!target_data_dir
      .join("settings")
      .join("sync_token.dat")
      .exists());
    assert!(!target_data_dir.join("profiles").join("profile-a").exists());
  }

  #[test]
  fn import_copies_allowed_data_without_settings_or_tokens() {
    let temp_dir = tempfile::tempdir().unwrap();
    let source_data_dir = temp_dir.path().join("DonutBrowser");
    let target_data_dir = temp_dir.path().join("TwitterBrowser");

    fs::create_dir_all(source_data_dir.join("profiles").join("profile-a")).unwrap();
    fs::create_dir_all(source_data_dir.join("proxies")).unwrap();
    fs::create_dir_all(source_data_dir.join("extensions")).unwrap();
    fs::create_dir_all(source_data_dir.join("vpn")).unwrap();
    fs::create_dir_all(source_data_dir.join("data")).unwrap();
    fs::create_dir_all(source_data_dir.join("settings")).unwrap();
    fs::write(
      source_data_dir
        .join("profiles")
        .join("profile-a")
        .join("metadata.json"),
      "{}",
    )
    .unwrap();
    fs::write(
      source_data_dir.join("proxies").join("proxy-a.json"),
      "{\"id\":\"proxy-a\"}",
    )
    .unwrap();
    fs::write(
      source_data_dir.join("extensions").join("extension-a.json"),
      "{}",
    )
    .unwrap();
    fs::write(source_data_dir.join("vpn").join("vpn_configs.json"), "{}").unwrap();
    fs::write(source_data_dir.join("vpn").join(".vpn_key"), b"vpn-key").unwrap();
    fs::write(
      source_data_dir.join("data").join("tags.json"),
      "[\"tag-a\"]",
    )
    .unwrap();
    fs::write(source_data_dir.join("data").join("groups.json"), "[]").unwrap();
    fs::write(
      source_data_dir.join("data").join("extension_groups.json"),
      "[]",
    )
    .unwrap();
    fs::write(
      source_data_dir
        .join("data")
        .join("downloaded_browsers.json"),
      "{\"camoufox\":true}",
    )
    .unwrap();
    fs::write(
      source_data_dir.join("settings").join("app_settings.json"),
      "{\"theme\":\"system\"}",
    )
    .unwrap();
    fs::write(
      source_data_dir.join("settings").join("sync_token.dat"),
      b"token",
    )
    .unwrap();
    fs::write(
      source_data_dir
        .join("settings")
        .join("cloud_auth_state.json"),
      "{\"user\":{}}",
    )
    .unwrap();

    let source_data_dir_string = source_data_dir.display().to_string();
    let lookup = lookup_from_map(&[("DONUTBROWSER_DATA_DIR", &source_data_dir_string)]);
    let result = import_legacy_donut_data_with(&lookup, &target_data_dir).unwrap();

    assert_eq!(result.imported_items, 8);
    assert!(target_data_dir
      .join("profiles")
      .join("profile-a")
      .join("metadata.json")
      .exists());
    assert!(target_data_dir
      .join("proxies")
      .join("proxy-a.json")
      .exists());
    assert!(target_data_dir
      .join("extensions")
      .join("extension-a.json")
      .exists());
    assert!(target_data_dir
      .join("vpn")
      .join("vpn_configs.json")
      .exists());
    assert!(target_data_dir.join("vpn").join(".vpn_key").exists());
    assert!(target_data_dir.join("data").join("tags.json").exists());
    assert!(target_data_dir.join("data").join("groups.json").exists());
    assert!(target_data_dir
      .join("data")
      .join("extension_groups.json")
      .exists());
    assert!(!target_data_dir
      .join("settings")
      .join("app_settings.json")
      .exists());
    assert!(!target_data_dir
      .join("settings")
      .join("sync_token.dat")
      .exists());
    assert!(!target_data_dir
      .join("data")
      .join("downloaded_browsers.json")
      .exists());
  }

  #[test]
  fn import_skips_existing_entities_without_overwriting() {
    let temp_dir = tempfile::tempdir().unwrap();
    let source_data_dir = temp_dir.path().join("DonutBrowser");
    let target_data_dir = temp_dir.path().join("TwitterBrowser");

    fs::create_dir_all(source_data_dir.join("profiles").join("profile-a")).unwrap();
    fs::create_dir_all(target_data_dir.join("profiles").join("profile-a")).unwrap();
    fs::write(
      source_data_dir
        .join("profiles")
        .join("profile-a")
        .join("metadata.json"),
      "{\"source\":true}",
    )
    .unwrap();
    fs::write(
      target_data_dir
        .join("profiles")
        .join("profile-a")
        .join("metadata.json"),
      "{\"target\":true}",
    )
    .unwrap();

    let source_data_dir_string = source_data_dir.display().to_string();
    let lookup = lookup_from_map(&[("DONUTBROWSER_DATA_DIR", &source_data_dir_string)]);
    let result = import_legacy_donut_data_with(&lookup, &target_data_dir).unwrap();

    assert_eq!(result.imported_items, 0);
    assert_eq!(result.skipped_items, 1);
    assert_eq!(
      fs::read_to_string(
        target_data_dir
          .join("profiles")
          .join("profile-a")
          .join("metadata.json"),
      )
      .unwrap(),
      "{\"target\":true}"
    );
  }

  #[test]
  fn status_reports_legacy_source_and_quarantine_backup() {
    let temp_dir = tempfile::tempdir().unwrap();
    let target_data_dir = temp_dir.path().join("TwitterBrowser");
    let cache_dir = temp_dir.path().join("TwitterBrowserCache");
    let source_data_dir = temp_dir.path().join("DonutBrowser");
    let backup_root = app_dirs::isolation_backup_root_for(&target_data_dir);
    let backup_dir = backup_root.join("quarantine-123");

    fs::create_dir_all(&source_data_dir).unwrap();
    fs::write(source_data_dir.join("marker.json"), "{}").unwrap();
    fs::create_dir_all(&backup_dir).unwrap();

    let source_data_dir_string = source_data_dir.display().to_string();
    let lookup = lookup_from_map(&[("DONUTBROWSER_DATA_DIR", &source_data_dir_string)]);
    let status = data_isolation_status_with(&lookup, &target_data_dir, &cache_dir);

    assert!(status.legacy_data_present);
    assert!(status.prior_auto_import_detected);
    assert!(status.quarantine_backup_exists);
    assert_eq!(
      status.legacy_data_dir,
      Some(source_data_dir.display().to_string())
    );
    assert_eq!(
      status.latest_quarantine_backup_dir,
      Some(backup_dir.display().to_string())
    );
  }

  #[test]
  fn quarantine_manifest_records_moved_entries() {
    let temp_dir = tempfile::tempdir().unwrap();
    let target_data_dir = temp_dir.path().join("TwitterBrowser");
    create_auto_imported_target(&target_data_dir);

    let backup_dir = quarantine_auto_imported_store_if_needed_with(&target_data_dir)
      .unwrap()
      .unwrap();
    let manifest: Value =
      serde_json::from_str(&fs::read_to_string(backup_dir.join(QUARANTINE_MANIFEST_FILE)).unwrap())
        .unwrap();

    let moved_entries = manifest["moved_entries"].as_array().unwrap();
    assert!(moved_entries
      .iter()
      .any(|value| value.as_str() == Some("settings")));
    assert!(moved_entries
      .iter()
      .any(|value| value.as_str() == Some("profiles")));
  }
}
