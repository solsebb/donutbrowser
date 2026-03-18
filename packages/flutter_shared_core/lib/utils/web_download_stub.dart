import 'dart:typed_data';

/// Stub implementation for non-web platforms
/// Download functionality is web-only, these are no-ops on mobile

/// Download file - no-op on mobile (use share sheet or file picker instead)
void downloadFile(Uint8List bytes, String fileName, String mimeType) {
  // No-op on mobile - use platform-specific sharing/saving
}

/// Create object URL from blob - returns empty string on mobile
String createObjectUrlFromBlob(List<int> bytes, String mimeType) {
  return '';
}

/// Revoke object URL - no-op on mobile
void revokeObjectUrl(String url) {
  // No-op on mobile
}

/// Download CSV data - no-op on mobile
void downloadCSV(String csvContent, String fileName) {
  // No-op on mobile
}

/// Open URL in new tab - no-op on mobile (use url_launcher instead)
void openUrlInNewTab(String url) {
  // No-op on mobile - use url_launcher instead
}
