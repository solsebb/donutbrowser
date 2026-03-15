#[cfg(any(target_os = "macos", target_os = "linux"))]
use std::fs;
use std::io;
use std::path::PathBuf;

fn daemon_service_label() -> String {
  format!("{}.daemon", crate::runtime_app_config::current().bundle_id)
}

fn daemon_binary_name() -> String {
  #[cfg(windows)]
  {
    format!(
      "{}.exe",
      crate::runtime_app_config::current().daemon_binary_name
    )
  }

  #[cfg(not(windows))]
  {
    crate::runtime_app_config::current()
      .daemon_binary_name
      .to_string()
  }
}

#[cfg(target_os = "windows")]
fn daemon_registry_value_name() -> String {
  crate::runtime_app_config::current()
    .daemon_binary_name
    .replace('-', "_")
}

fn get_daemon_path() -> Option<PathBuf> {
  // First try to find the daemon binary in the same directory as the current executable
  if let Ok(current_exe) = std::env::current_exe() {
    let daemon_path = current_exe.parent()?.join(daemon_binary_name());
    if daemon_path.exists() {
      return Some(daemon_path);
    }
  }

  // Try common installation paths
  #[cfg(target_os = "macos")]
  {
    let config = crate::runtime_app_config::current();
    let paths = [
      PathBuf::from(format!(
        "/Applications/{}.app/Contents/MacOS/{}",
        config.display_name,
        daemon_binary_name()
      )),
      dirs::home_dir()?.join(format!(
        "Applications/{}.app/Contents/MacOS/{}",
        config.display_name,
        daemon_binary_name()
      )),
    ];
    for path in paths {
      if path.exists() {
        return Some(path);
      }
    }
  }

  #[cfg(target_os = "windows")]
  {
    let config = crate::runtime_app_config::current();
    let paths = [
      dirs::data_local_dir()?
        .join(config.display_name.as_str())
        .join(daemon_binary_name()),
      PathBuf::from(format!(
        "C:\\Program Files\\{}\\{}",
        config.display_name,
        daemon_binary_name()
      )),
    ];
    for path in paths {
      if path.exists() {
        return Some(path);
      }
    }
  }

  #[cfg(target_os = "linux")]
  {
    let paths = [
      PathBuf::from(format!("/usr/bin/{}", daemon_binary_name())),
      PathBuf::from(format!("/usr/local/bin/{}", daemon_binary_name())),
      dirs::home_dir()?.join(format!(".local/bin/{}", daemon_binary_name())),
    ];
    for path in paths {
      if path.exists() {
        return Some(path);
      }
    }
  }

  None
}

#[cfg(target_os = "macos")]
pub fn enable_autostart() -> io::Result<()> {
  let daemon_path = get_daemon_path()
    .ok_or_else(|| io::Error::new(io::ErrorKind::NotFound, "Daemon binary not found"))?;

  let plist_dir = dirs::home_dir()
    .ok_or_else(|| io::Error::new(io::ErrorKind::NotFound, "Home directory not found"))?
    .join("Library/LaunchAgents");

  fs::create_dir_all(&plist_dir)?;

  let plist_path = plist_dir.join(format!("{}.plist", daemon_service_label()));

  // Get log directory (use data directory instead of /tmp)
  let log_dir = get_data_dir()
    .unwrap_or_else(|| PathBuf::from("/tmp"))
    .join("logs");
  fs::create_dir_all(&log_dir)?;

  let plist_content = format!(
    r#"<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>{service_label}</string>
    <key>ProgramArguments</key>
    <array>
        <string>{daemon_path}</string>
        <string>run</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>LimitLoadToSessionType</key>
    <string>Aqua</string>
    <key>ProcessType</key>
    <string>Interactive</string>
    <key>StandardOutPath</key>
    <string>{log_dir}/daemon.out.log</string>
    <key>StandardErrorPath</key>
    <string>{log_dir}/daemon.err.log</string>
</dict>
</plist>
"#,
    daemon_path = daemon_path.display(),
    log_dir = log_dir.display(),
    service_label = daemon_service_label()
  );

  fs::write(&plist_path, plist_content)?;

  log::info!("Created launch agent at {:?}", plist_path);
  Ok(())
}

#[cfg(target_os = "macos")]
pub fn get_plist_path() -> Option<PathBuf> {
  dirs::home_dir().map(|h| {
    h.join(format!(
      "Library/LaunchAgents/{}.plist",
      daemon_service_label()
    ))
  })
}

#[cfg(target_os = "macos")]
pub fn disable_autostart() -> io::Result<()> {
  let plist_path = get_plist_path()
    .ok_or_else(|| io::Error::new(io::ErrorKind::NotFound, "Home directory not found"))?;

  if plist_path.exists() {
    // First unload the launch agent if it's loaded
    let _ = unload_launch_agent();
    fs::remove_file(&plist_path)?;
    log::info!("Removed launch agent at {:?}", plist_path);
  }

  Ok(())
}

#[cfg(target_os = "macos")]
pub fn is_autostart_enabled() -> bool {
  get_plist_path().is_some_and(|p| p.exists())
}

#[cfg(target_os = "macos")]
pub fn load_launch_agent() -> io::Result<()> {
  use std::process::Command;

  let plist_path = get_plist_path()
    .ok_or_else(|| io::Error::new(io::ErrorKind::NotFound, "Could not determine plist path"))?;

  if !plist_path.exists() {
    return Err(io::Error::new(
      io::ErrorKind::NotFound,
      "Launch agent plist does not exist",
    ));
  }

  // Use launchctl load to start the daemon via launchd
  // The -w flag writes the "disabled" key to the override plist
  let output = Command::new("launchctl")
    .args(["load", "-w"])
    .arg(&plist_path)
    .output()?;

  if !output.status.success() {
    let stderr = String::from_utf8_lossy(&output.stderr);
    // "already loaded" is not an error condition for us
    if !stderr.contains("already loaded") {
      return Err(io::Error::other(format!(
        "launchctl load failed: {}",
        stderr
      )));
    }
  }

  log::info!("Loaded launch agent via launchctl");
  Ok(())
}

#[cfg(target_os = "macos")]
pub fn start_launch_agent() -> io::Result<()> {
  use std::process::Command;

  let output = Command::new("launchctl")
    .args(["start", &daemon_service_label()])
    .output()?;

  if !output.status.success() {
    let stderr = String::from_utf8_lossy(&output.stderr);
    return Err(io::Error::other(format!(
      "launchctl start failed: {}",
      stderr
    )));
  }

  log::info!("Started launch agent via launchctl");
  Ok(())
}

#[cfg(target_os = "macos")]
pub fn unload_launch_agent() -> io::Result<()> {
  use std::process::Command;

  let plist_path = get_plist_path()
    .ok_or_else(|| io::Error::new(io::ErrorKind::NotFound, "Could not determine plist path"))?;

  if !plist_path.exists() {
    return Ok(());
  }

  let output = Command::new("launchctl")
    .args(["unload"])
    .arg(&plist_path)
    .output()?;

  if !output.status.success() {
    let stderr = String::from_utf8_lossy(&output.stderr);
    // Not being loaded is not an error
    if !stderr.contains("Could not find specified service") {
      log::warn!("launchctl unload warning: {}", stderr);
    }
  }

  log::info!("Unloaded launch agent via launchctl");
  Ok(())
}

#[cfg(target_os = "linux")]
pub fn enable_autostart() -> io::Result<()> {
  let daemon_path = get_daemon_path()
    .ok_or_else(|| io::Error::new(io::ErrorKind::NotFound, "Daemon binary not found"))?;

  let autostart_dir = dirs::config_dir()
    .ok_or_else(|| io::Error::new(io::ErrorKind::NotFound, "Config directory not found"))?
    .join("autostart");

  fs::create_dir_all(&autostart_dir)?;

  let desktop_path = autostart_dir.join(format!("{}.desktop", daemon_binary_name()));

  let escaped_daemon_path = daemon_path
    .display()
    .to_string()
    .replace('\\', "\\\\")
    .replace('"', "\\\"")
    .replace('`', "\\`")
    .replace('$', "\\$");
  let desktop_content = format!(
    r#"[Desktop Entry]
Type=Application
Name={} Daemon
Exec="{escaped_daemon_path}" run
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
"#,
    crate::runtime_app_config::current().display_name,
  );

  fs::write(&desktop_path, desktop_content)?;

  log::info!("Created autostart entry at {:?}", desktop_path);
  Ok(())
}

#[cfg(target_os = "linux")]
pub fn disable_autostart() -> io::Result<()> {
  let desktop_path = dirs::config_dir()
    .ok_or_else(|| io::Error::new(io::ErrorKind::NotFound, "Config directory not found"))?
    .join(format!("autostart/{}.desktop", daemon_binary_name()));

  if desktop_path.exists() {
    fs::remove_file(&desktop_path)?;
    log::info!("Removed autostart entry at {:?}", desktop_path);
  }

  Ok(())
}

#[cfg(target_os = "linux")]
pub fn is_autostart_enabled() -> bool {
  dirs::config_dir()
    .map(|c| {
      c.join(format!("autostart/{}.desktop", daemon_binary_name()))
        .exists()
    })
    .unwrap_or(false)
}

#[cfg(target_os = "windows")]
pub fn enable_autostart() -> io::Result<()> {
  use winreg::enums::HKEY_CURRENT_USER;
  use winreg::RegKey;

  let daemon_path = get_daemon_path()
    .ok_or_else(|| io::Error::new(io::ErrorKind::NotFound, "Daemon binary not found"))?;

  let hkcu = RegKey::predef(HKEY_CURRENT_USER);
  let (key, _) = hkcu.create_subkey("Software\\Microsoft\\Windows\\CurrentVersion\\Run")?;
  let registry_value_name = daemon_registry_value_name();

  key.set_value(
    registry_value_name,
    &format!("\"{}\" run", daemon_path.display()),
  )?;

  log::info!("Added registry autostart entry");
  Ok(())
}

#[cfg(target_os = "windows")]
pub fn disable_autostart() -> io::Result<()> {
  use winreg::enums::HKEY_CURRENT_USER;
  use winreg::RegKey;

  let hkcu = RegKey::predef(HKEY_CURRENT_USER);
  if let Ok(key) = hkcu.open_subkey_with_flags(
    "Software\\Microsoft\\Windows\\CurrentVersion\\Run",
    winreg::enums::KEY_WRITE,
  ) {
    let _ = key.delete_value(daemon_registry_value_name());
    log::info!("Removed registry autostart entry");
  }

  Ok(())
}

#[cfg(target_os = "windows")]
pub fn is_autostart_enabled() -> bool {
  use winreg::enums::HKEY_CURRENT_USER;
  use winreg::RegKey;

  let hkcu = RegKey::predef(HKEY_CURRENT_USER);
  if let Ok(key) = hkcu.open_subkey("Software\\Microsoft\\Windows\\CurrentVersion\\Run") {
    key
      .get_value::<String, _>(daemon_registry_value_name())
      .is_ok()
  } else {
    false
  }
}

pub fn get_data_dir() -> Option<PathBuf> {
  Some(crate::app_dirs::data_dir())
}
