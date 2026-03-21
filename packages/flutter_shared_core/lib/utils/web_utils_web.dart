// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web implementation using dart:html

/// Get the current URL pathname
String getLocationPathname() => html.window.location.pathname ?? '/dashboard';

/// Push a new state to browser history
void pushHistoryState(String path) {
  html.window.history.pushState(null, '', path);
}

/// Replace current state in browser history
void replaceHistoryState(String path) {
  html.window.history.replaceState(null, '', path);
}

/// Get the full URL href
String getLocationHref() => html.window.location.href;

/// Get the location hostname
String getLocationHostname() => html.window.location.hostname ?? '';

/// Set the location href to navigate
void setLocationHref(String url) {
  html.window.location.href = url;
}

/// Open URL in new tab
void openUrlInNewTab(String url) {
  html.window.open(url, '_blank');
}

/// Register a message event listener
void addMessageListener(void Function(dynamic data) onMessage) {
  html.window.addEventListener('message', (event) {
    if (event is html.MessageEvent) {
      onMessage(event.data);
    }
  });
}

/// Log to console
void consoleLog(String message) {
  html.window.console.log(message);
}

/// Get user agent string
String getUserAgent() => html.window.navigator.userAgent;
