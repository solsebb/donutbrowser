import 'package:flutter/foundation.dart';
import 'package:flutter_shared_core/utils/app_logger.dart';
import 'dart:io';
import 'package:flutter/services.dart';

/// Helper class to provide SHA-1 fingerprint verification and diagnostics
/// for Google Sign-In integration.
class FingerprintHelper {
  /// Checks if the device is Android and the app is running with the correct configuration
  /// for Google Sign-In.
  static Future<String?> verifyAndroidFingerprint() async {
    // Skip on web platform - MethodChannel not available
    if (kIsWeb) {
      AppLogger.log('🌐 FingerprintHelper: Skipping fingerprint verification on web platform');
      return null;
    }
    
    if (!Platform.isAndroid) {
      return null; // Not relevant for non-Android platforms
    }

    try {
      // Use platform channel to communicate with native Android code
      const platform = MethodChannel('com.photobase.ainotetaker/fingerprint');
      final String sha1Fingerprint =
          await platform.invokeMethod('getSha1Fingerprint');

      if (sha1Fingerprint.isEmpty) {
        return 'Could not determine app signing SHA-1 fingerprint';
      }

      // Found the fingerprint - provide formatted version for easy copying to Google Cloud Console
      final String formattedFingerprint =
          sha1Fingerprint.replaceAll(':', '').toUpperCase();

      return '''
App is signed with SHA-1 fingerprint:
$sha1Fingerprint

To fix Google Sign-In issues:
1. Add this fingerprint to Google Cloud Console
2. Use this format (without colons): $formattedFingerprint
3. Ensure it matches what's registered for your OAuth client ID
''';
    } catch (e) {
      AppLogger.log('Error checking fingerprint: $e');
      return 'Unable to verify SHA-1 fingerprint: $e';
    }
  }

  /// Provides troubleshooting tips for Google Sign-In issues
  static String getTroubleshootingTips() {
    // Handle web platform
    if (kIsWeb) {
      return '''
Google Sign-In Troubleshooting (Web):
- Verify your web client ID is correctly configured in Google Cloud Console
- Ensure the correct authorized JavaScript origins are set
- Check that the web OAuth client ID matches your configuration
''';
    }
    
    if (Platform.isAndroid) {
      return '''
Google Sign-In Troubleshooting:
- Verify your SHA-1 fingerprint is added in Google Cloud Console
- Make sure the package name is set to "com.photobase.ainotetaker"
- Uninstall the app and reinstall after making changes
- Check that Google Play Services is up to date
- Your SHA-1 fingerprint (94:C8:59:56:F9:7E:8E:AE:E0:05:BD:2D:A1:81:64:6F:92:27:B5:A4) must be added with no colons (94C85956F97E8EAEE005BD2DA181646F9227B5A4)
''';
    } else if (Platform.isIOS) {
      return '''
Google Sign-In Troubleshooting:
- Verify your iOS Bundle ID is correctly registered in Google Cloud Console
- Ensure the correct iOS OAuth client ID is configured
- Check that all required URL schemes are added to Info.plist
''';
    } else {
      return 'Google Sign-In troubleshooting not available for this platform';
    }
  }
}
