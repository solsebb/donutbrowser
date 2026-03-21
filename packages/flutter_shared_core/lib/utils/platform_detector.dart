import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Utility class for detecting the current platform
class PlatformDetector {
  /// Returns true if running on iOS (mobile app, not web)
  static bool get isIOS {
    return !kIsWeb && Platform.isIOS;
  }

  /// Returns true if running on Android (mobile app, not web)
  static bool get isAndroid {
    return !kIsWeb && Platform.isAndroid;
  }

  /// Returns true if running on web platform
  static bool get isWeb {
    return kIsWeb;
  }

  /// Returns true if running on a mobile platform (iOS or Android)
  static bool get isMobile {
    return isIOS || isAndroid;
  }

  /// Returns a string identifier for the current platform
  static String get platformName {
    if (isIOS) return 'iOS';
    if (isAndroid) return 'Android';
    if (isWeb) return 'Web';
    return 'Unknown';
  }
}
