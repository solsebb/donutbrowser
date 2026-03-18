/// Stub implementation for non-web platforms
/// These functions are no-ops on mobile

/// Get the current URL pathname (web only)
String getLocationPathname() => '/dashboard';

/// Push a new state to browser history (web only)
void pushHistoryState(String path) {
  // No-op on mobile
}

/// Replace current state in browser history (web only)
void replaceHistoryState(String path) {
  // No-op on mobile
}

/// Get the full URL href (web only)
String getLocationHref() => '';

/// Get the location hostname (web only)
String getLocationHostname() => '';

/// Set the location href to navigate (web only)
void setLocationHref(String url) {
  // No-op on mobile - use url_launcher instead
}

/// Open URL in new tab (web only)
void openUrlInNewTab(String url) {
  // No-op on mobile - use url_launcher instead
}

/// Register a message event listener (web only)
void addMessageListener(void Function(dynamic data) onMessage) {
  // No-op on mobile
}

/// Log to console (web only)
void consoleLog(String message) {
  // No-op on mobile - use print or AppLogger instead
}

/// Get user agent string (web only)
String getUserAgent() => '';
