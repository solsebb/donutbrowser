use directories::BaseDirs;
use std::path::{Path, PathBuf};
use std::sync::OnceLock;

use crate::runtime_app_config;

static BASE_DIRS: OnceLock<BaseDirs> = OnceLock::new();

const LEGACY_RELEASE_APP_NAME: &str = "DonutBrowser";
const LEGACY_DEBUG_APP_NAME: &str = "DonutBrowserDev";
const LEGACY_IMPORT_SENTINEL: &str = ".legacy_donut_import_complete.json";

fn base_dirs() -> &'static BaseDirs {
  BASE_DIRS.get_or_init(|| BaseDirs::new().expect("Failed to get base directories"))
}

fn current_release_app_name() -> &'static str {
  runtime_app_config::current().display_name.as_str()
}

fn current_debug_app_name() -> &'static str {
  runtime_app_config::current().dev_display_name.as_str()
}

fn path_from_env<F>(lookup: &F, key: &str) -> Option<PathBuf>
where
  F: Fn(&str) -> Option<String>,
{
  lookup(key).and_then(|value| {
    let trimmed = value.trim();
    if trimmed.is_empty() {
      None
    } else {
      Some(PathBuf::from(trimmed))
    }
  })
}

fn data_dir_from_env<F>(lookup: &F) -> Option<PathBuf>
where
  F: Fn(&str) -> Option<String>,
{
  path_from_env(lookup, "TWITTERBROWSER_DATA_DIR")
}

fn cache_dir_from_env<F>(lookup: &F) -> Option<PathBuf>
where
  F: Fn(&str) -> Option<String>,
{
  path_from_env(lookup, "TWITTERBROWSER_CACHE_DIR")
}

fn legacy_data_dir_from_env<F>(lookup: &F) -> Option<PathBuf>
where
  F: Fn(&str) -> Option<String>,
{
  path_from_env(lookup, "DONUTBROWSER_DATA_DIR")
}

fn current_app_name_for_build() -> &'static str {
  if cfg!(debug_assertions) {
    current_debug_app_name()
  } else {
    current_release_app_name()
  }
}

fn legacy_app_name_for_build() -> &'static str {
  if cfg!(debug_assertions) {
    LEGACY_DEBUG_APP_NAME
  } else {
    LEGACY_RELEASE_APP_NAME
  }
}

fn alternate_legacy_app_name() -> &'static str {
  if cfg!(debug_assertions) {
    LEGACY_RELEASE_APP_NAME
  } else {
    LEGACY_DEBUG_APP_NAME
  }
}

pub(crate) fn default_data_dir_for_name(name: &str) -> PathBuf {
  base_dirs().data_local_dir().join(name)
}

fn default_cache_dir_for_name(name: &str) -> PathBuf {
  base_dirs().cache_dir().join(name)
}

pub fn app_name() -> &'static str {
  current_app_name_for_build()
}

pub fn data_dir() -> PathBuf {
  #[cfg(test)]
  {
    if let Some(dir) = TEST_DATA_DIR.with(|cell| cell.borrow().clone()) {
      return dir;
    }
  }

  if let Some(dir) = data_dir_from_env(&|name| std::env::var(name).ok()) {
    return dir;
  }

  default_data_dir_for_name(app_name())
}

pub fn cache_dir() -> PathBuf {
  #[cfg(test)]
  {
    if let Some(dir) = TEST_CACHE_DIR.with(|cell| cell.borrow().clone()) {
      return dir;
    }
  }

  if let Some(dir) = cache_dir_from_env(&|name| std::env::var(name).ok()) {
    return dir;
  }

  default_cache_dir_for_name(app_name())
}

pub fn profiles_dir() -> PathBuf {
  data_dir().join("profiles")
}

pub fn binaries_dir() -> PathBuf {
  data_dir().join("binaries")
}

pub fn data_subdir() -> PathBuf {
  data_dir().join("data")
}

pub fn settings_dir() -> PathBuf {
  data_dir().join("settings")
}

pub fn proxies_dir() -> PathBuf {
  data_dir().join("proxies")
}

pub fn proxy_workers_dir() -> PathBuf {
  cache_dir().join("proxy_workers")
}

pub fn vpn_dir() -> PathBuf {
  data_dir().join("vpn")
}

pub fn extensions_dir() -> PathBuf {
  data_dir().join("extensions")
}

pub(crate) fn legacy_import_sentinel_path(data_root: &Path) -> PathBuf {
  data_root.join("settings").join(LEGACY_IMPORT_SENTINEL)
}

fn dedupe_paths(paths: Vec<PathBuf>) -> Vec<PathBuf> {
  let mut unique = Vec::new();

  for path in paths {
    if !unique.iter().any(|existing| existing == &path) {
      unique.push(path);
    }
  }

  unique
}

pub(crate) fn legacy_data_dir_candidates_with<F>(lookup: &F) -> Vec<PathBuf>
where
  F: Fn(&str) -> Option<String>,
{
  dedupe_paths(vec![
    legacy_data_dir_from_env(lookup)
      .unwrap_or_else(|| default_data_dir_for_name(legacy_app_name_for_build())),
    default_data_dir_for_name(legacy_app_name_for_build()),
    default_data_dir_for_name(alternate_legacy_app_name()),
  ])
}

pub(crate) fn isolation_backup_root_for(data_root: &Path) -> PathBuf {
  let backup_dir_name = format!("{}-legacy-import-backups", app_name());
  match data_root.parent() {
    Some(parent) => parent.join(backup_dir_name),
    None => PathBuf::from(backup_dir_name),
  }
}

#[cfg(test)]
thread_local! {
  static TEST_DATA_DIR: std::cell::RefCell<Option<PathBuf>> = const { std::cell::RefCell::new(None) };
  static TEST_CACHE_DIR: std::cell::RefCell<Option<PathBuf>> = const { std::cell::RefCell::new(None) };
}

#[cfg(test)]
pub struct TestDirGuard {
  kind: TestDirKind,
}

#[cfg(test)]
enum TestDirKind {
  Data,
  Cache,
}

#[cfg(test)]
impl Drop for TestDirGuard {
  fn drop(&mut self) {
    match self.kind {
      TestDirKind::Data => TEST_DATA_DIR.with(|cell| *cell.borrow_mut() = None),
      TestDirKind::Cache => TEST_CACHE_DIR.with(|cell| *cell.borrow_mut() = None),
    }
  }
}

#[cfg(test)]
pub fn set_test_data_dir(dir: PathBuf) -> TestDirGuard {
  TEST_DATA_DIR.with(|cell| *cell.borrow_mut() = Some(dir));
  TestDirGuard {
    kind: TestDirKind::Data,
  }
}

#[cfg(test)]
pub fn set_test_cache_dir(dir: PathBuf) -> TestDirGuard {
  TEST_CACHE_DIR.with(|cell| *cell.borrow_mut() = Some(dir));
  TestDirGuard {
    kind: TestDirKind::Cache,
  }
}

#[cfg(test)]
mod tests {
  use super::*;
  use std::collections::HashMap;

  fn lookup_from_map(values: &[(&str, &str)]) -> impl Fn(&str) -> Option<String> {
    let values = values
      .iter()
      .map(|(key, value)| ((*key).to_string(), (*value).to_string()))
      .collect::<HashMap<_, _>>();
    move |name| values.get(name).cloned()
  }

  #[test]
  fn current_app_name_matches_twitterbrowser() {
    let name = app_name();
    assert!(
      name == "TwitterBrowser" || name == "TwitterBrowserDev",
      "app_name should be TwitterBrowser or TwitterBrowserDev, got: {name}"
    );
  }

  #[test]
  fn active_data_dir_only_uses_twitterbrowser_env() {
    let lookup = lookup_from_map(&[("DONUTBROWSER_DATA_DIR", "/tmp/donut-data")]);
    assert_eq!(data_dir_from_env(&lookup), None);
  }

  #[test]
  fn active_cache_dir_only_uses_twitterbrowser_env() {
    let lookup = lookup_from_map(&[("DONUTBROWSER_CACHE_DIR", "/tmp/donut-cache")]);
    assert_eq!(cache_dir_from_env(&lookup), None);
  }

  #[test]
  fn legacy_candidates_still_support_donut_env_for_explicit_imports() {
    let lookup = lookup_from_map(&[("DONUTBROWSER_DATA_DIR", "/tmp/donut-data")]);
    let candidates = legacy_data_dir_candidates_with(&lookup);
    assert_eq!(candidates.first(), Some(&PathBuf::from("/tmp/donut-data")));
  }

  #[test]
  fn sentinel_path_is_stored_in_settings_dir() {
    let root = PathBuf::from("/tmp/TwitterBrowser");
    assert_eq!(
      legacy_import_sentinel_path(&root),
      root.join("settings").join(LEGACY_IMPORT_SENTINEL)
    );
  }

  #[test]
  fn backup_root_uses_app_name_sibling_directory() {
    let root = PathBuf::from("/tmp/TwitterBrowser");
    assert_eq!(
      isolation_backup_root_for(&root),
      PathBuf::from("/tmp").join(format!("{}-legacy-import-backups", app_name()))
    );
  }

  #[test]
  fn legacy_candidates_include_default_release_dir() {
    let lookup = lookup_from_map(&[]);
    let candidates = legacy_data_dir_candidates_with(&lookup);
    assert!(
      candidates.iter().any(
        |path| path.ends_with(LEGACY_RELEASE_APP_NAME) || path.ends_with(LEGACY_DEBUG_APP_NAME)
      )
    );
  }

  #[test]
  fn test_dir_override_still_works() {
    let temp_dir = tempfile::tempdir().unwrap();
    let _guard = set_test_data_dir(temp_dir.path().join("twitter-data"));
    assert_eq!(data_dir(), temp_dir.path().join("twitter-data"));
  }

  #[test]
  fn test_cache_dir_override_still_works() {
    let temp_dir = tempfile::tempdir().unwrap();
    let _guard = set_test_cache_dir(temp_dir.path().join("twitter-cache"));
    assert_eq!(cache_dir(), temp_dir.path().join("twitter-cache"));
  }
}
