/// Centralized URL normalization and validation utility
/// Handles various URL formats and normalizes them to valid HTTP(S) URLs
///
/// Examples:
/// - "google.com" → "https://google.com"
/// - "www.example.com" → "https://www.example.com"
/// - "example.com/path" → "https://example.com/path"
/// - "http://test.com" → "http://test.com" (preserves http if specified)
/// - "https://site.com" → "https://site.com" (already valid)
class UrlNormalizer {
  /// Normalize a URL to a valid HTTP(S) URL
  /// Returns null if the URL is invalid
  static String? normalize(String url) {
    if (url.isEmpty) {
      return null;
    }

    // Trim whitespace
    String normalized = url.trim();

    // If already has http:// or https://, validate and return
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return _isValidUrl(normalized) ? normalized : null;
    }

    // Remove common prefixes that users might include
    if (normalized.startsWith('www.')) {
      // Don't remove www., just add https://
      normalized = 'https://$normalized';
    } else {
      // Add https:// prefix for bare domains
      normalized = 'https://$normalized';
    }

    // Validate the normalized URL
    return _isValidUrl(normalized) ? normalized : null;
  }

  /// Validate if a URL is properly formatted
  static bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);

      // Must have a scheme (http or https)
      if (uri.scheme != 'http' && uri.scheme != 'https') {
        return false;
      }

      // Must have a host
      if (uri.host.isEmpty) {
        return false;
      }

      // Host must contain at least one dot (e.g., google.com, localhost is invalid)
      // OR be an IP address
      if (!uri.host.contains('.') && !_isIpAddress(uri.host)) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if a string is a valid IP address
  static bool _isIpAddress(String host) {
    // Simple IPv4 validation
    final ipv4Pattern = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    if (ipv4Pattern.hasMatch(host)) {
      final parts = host.split('.');
      return parts.every((part) {
        final num = int.tryParse(part);
        return num != null && num >= 0 && num <= 255;
      });
    }

    // Simple IPv6 validation (basic check)
    if (host.contains(':')) {
      return true; // Basic IPv6 detection
    }

    return false;
  }

  /// Get user-friendly error message for invalid URLs
  static String getErrorMessage(String url) {
    if (url.isEmpty) {
      return 'URL cannot be empty';
    }

    final normalized = normalize(url);
    if (normalized == null) {
      // Try to give specific feedback
      if (!url.contains('.') && !_isIpAddress(url)) {
        return 'URL must be a valid domain (e.g., google.com)';
      }
      return 'Please enter a valid URL';
    }

    return '';
  }

  /// Display-friendly URL (removes https:// prefix for display)
  static String toDisplayUrl(String url) {
    return url
        .replaceFirst('https://', '')
        .replaceFirst('http://', '');
  }
}
