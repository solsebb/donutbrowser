import 'package:flutter/foundation.dart';

/// Centralized logging utility for the entire application
///
/// **Production Behavior:**
/// - On non-local web domains, ALL logs are suppressed
/// - Zero debug output in browser console for security
///
/// **Development Behavior:**
/// - On localhost, ALL logs are printed normally
/// - Full debug visibility for development
///
/// **Environment Detection:**
/// - Automatically detects production vs development
/// - Uses Uri.base.host to determine environment
/// - Supports explicit override with APP_DEBUG_LOGS=true or ?debug_logs=1
/// - No manual configuration needed
///
/// **Usage:**
/// ```dart
/// // Replace all debugPrint() with AppLogger.log()
/// AppLogger.log('User authenticated successfully');
/// AppLogger.log('Error: ${error.toString()}');
/// AppLogger.log('🔍 Debug info: $debugData');
/// ```
class AppLogger {
  /// Private constructor - this is a utility class
  AppLogger._();

  /// Cache the production check to avoid repeated Uri.base calls
  static bool? _isProduction;

  /// Explicit override for enabling logs, useful for production debugging.
  static const bool _debugLogsOverride = bool.fromEnvironment(
    'APP_DEBUG_LOGS',
    defaultValue: false,
  );

  static bool _isLocalHost(String host) {
    final normalizedHost = host.trim().toLowerCase();
    if (normalizedHost.isEmpty) return true;

    if (normalizedHost == 'localhost' ||
        normalizedHost == '127.0.0.1' ||
        normalizedHost == '::1' ||
        normalizedHost.endsWith('.local')) {
      return true;
    }

    // Private IPv4 ranges:
    // - 10.0.0.0/8
    // - 172.16.0.0/12
    // - 192.168.0.0/16
    final ipv4Match = RegExp(r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$')
        .firstMatch(normalizedHost);
    if (ipv4Match != null) {
      final octets = List<int>.generate(4, (i) {
        return int.tryParse(ipv4Match.group(i + 1) ?? '') ?? -1;
      });

      final isValid = octets.every((octet) => octet >= 0 && octet <= 255);
      if (!isValid) return false;

      if (octets[0] == 10) return true;
      if (octets[0] == 192 && octets[1] == 168) return true;
      if (octets[0] == 172 && octets[1] >= 16 && octets[1] <= 31) return true;
    }

    return false;
  }

  static bool _hasDebugLogsQueryOverride() {
    if (!kIsWeb) return false;

    final rawValue = Uri.base.queryParameters['debug_logs'];
    if (rawValue == null) return false;

    final normalized = rawValue.trim().toLowerCase();
    return normalized == '1' || normalized == 'true' || normalized == 'yes';
  }

  /// Determine if we're running in production environment
  ///
  /// **Development:**
  /// - localhost
  /// - 127.0.0.1
  /// - Any local IP (192.168.x.x, 10.0.x.x)
  static bool get isProduction {
    // Cache the result to avoid repeated Uri.base calls
    if (_isProduction != null) {
      return _isProduction!;
    }

    if (_debugLogsOverride || _hasDebugLogsQueryOverride()) {
      _isProduction = false;
      return _isProduction!;
    }

    // Only check on web platform
    if (kIsWeb) {
      final host = Uri.base.host.split(':').first.toLowerCase();
      _isProduction = !_isLocalHost(host);
    } else {
      // Mobile/desktop apps - always allow logging in debug mode
      _isProduction = kReleaseMode;
    }

    return _isProduction!;
  }

  /// Log a message (only in development)
  ///
  /// **Parameters:**
  /// - [message] - The message to log
  ///
  /// **Behavior:**
  /// - Production: Silently discarded (zero output)
  /// - Development: Printed to console via debugPrint
  ///
  /// **Example:**
  /// ```dart
  /// AppLogger.log('User signed in: ${user.id}');
  /// AppLogger.log('🚀 STARTUP: Calendar V2 initialized');
  /// AppLogger.log('❌ Error fetching data: ${error.toString()}');
  /// ```
  static void log(String message) {
    if (!isProduction) {
      debugPrint(message);
    }
    // Production: Do nothing (zero output)
  }

  /// Log a message with a prefix/tag for categorization
  ///
  /// **Parameters:**
  /// - [tag] - Category/prefix for the log (e.g., 'AUTH', 'DATABASE', 'API')
  /// - [message] - The message to log
  ///
  /// **Example:**
  /// ```dart
  /// AppLogger.logTagged('AUTH', 'User authenticated successfully');
  /// AppLogger.logTagged('DATABASE', 'Query executed in 45ms');
  /// AppLogger.logTagged('ERROR', 'Failed to fetch user data');
  /// ```
  static void logTagged(String tag, String message) {
    if (!isProduction) {
      debugPrint('[$tag] $message');
    }
    // Production: Do nothing (zero output)
  }

  /// Log an error with optional stack trace (only in development)
  ///
  /// **Parameters:**
  /// - [message] - Error description
  /// - [error] - The error object (optional)
  /// - [stackTrace] - Stack trace (optional)
  ///
  /// **Example:**
  /// ```dart
  /// try {
  ///   await riskyOperation();
  /// } catch (e, stackTrace) {
  ///   AppLogger.logError('Operation failed', e, stackTrace);
  /// }
  /// ```
  static void logError(String message, [Object? error, StackTrace? stackTrace]) {
    if (!isProduction) {
      debugPrint('❌ ERROR: $message');
      if (error != null) {
        debugPrint('   Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('   Stack: $stackTrace');
      }
    }
    // Production: Do nothing (zero output)
  }

  /// Log a warning message (only in development)
  ///
  /// **Parameters:**
  /// - [message] - Warning message
  ///
  /// **Example:**
  /// ```dart
  /// AppLogger.logWarning('Session expires in 5 minutes');
  /// AppLogger.logWarning('API rate limit approaching');
  /// ```
  static void logWarning(String message) {
    if (!isProduction) {
      debugPrint('⚠️ WARNING: $message');
    }
    // Production: Do nothing (zero output)
  }

  /// Log a success message (only in development)
  ///
  /// **Parameters:**
  /// - [message] - Success message
  ///
  /// **Example:**
  /// ```dart
  /// AppLogger.logSuccess('User profile updated successfully');
  /// AppLogger.logSuccess('Payment processed');
  /// ```
  static void logSuccess(String message) {
    if (!isProduction) {
      debugPrint('✅ SUCCESS: $message');
    }
    // Production: Do nothing (zero output)
  }

  /// Log debug information (only in development)
  ///
  /// **Parameters:**
  /// - [message] - Debug message
  ///
  /// **Example:**
  /// ```dart
  /// AppLogger.logDebug('Current state: $state');
  /// AppLogger.logDebug('API response: $response');
  /// ```
  static void logDebug(String message) {
    if (!isProduction) {
      debugPrint('🔍 DEBUG: $message');
    }
    // Production: Do nothing (zero output)
  }

  /// Reset the production cache (useful for testing)
  ///
  /// **Warning:** Only use in tests, never in production code!
  @visibleForTesting
  static void resetCache() {
    _isProduction = null;
  }

  // ============================================================================
  // STRUCTURED LOGGING (Senior-level, production-ready)
  // ============================================================================

  /// Debug log with structured data (internal states, processing steps)
  ///
  /// **Format:** `<area>_<action>_<stage>`
  ///
  /// **Example:**
  /// ```dart
  /// AppLogger.debug('drag_position_calculated', {
  ///   'blockId': block.id,
  ///   'row': 0.5,
  ///   'column': 1,
  ///   'operation': 'onDragUpdate',
  /// });
  /// ```
  static void debug(String event, Map<String, dynamic> data) {
    if (!isProduction) {
      debugPrint('🔍 DEBUG: $event');
      data.forEach((key, value) {
        debugPrint('  $key: $value');
      });
    }
  }

  /// Info log with structured data (successful operations, lifecycle events)
  ///
  /// **Format:** `<area>_<action>_<result>`
  ///
  /// **Example:**
  /// ```dart
  /// AppLogger.info('drag_drop_success', {
  ///   'blockId': block.id,
  ///   'fromPosition': '0,0',
  ///   'toPosition': '1,0',
  ///   'overlappingBlocks': 2,
  /// });
  /// ```
  static void info(String event, Map<String, dynamic> data) {
    if (!isProduction) {
      debugPrint('ℹ️ INFO: $event');
      data.forEach((key, value) {
        debugPrint('  $key: $value');
      });
    }
  }

  /// Warning log with structured data (unexpected but non-breaking edge cases)
  ///
  /// **Format:** `<area>_<issue>_<context>`
  ///
  /// **Example:**
  /// ```dart
  /// AppLogger.warn('drag_position_clamped', {
  ///   'blockId': block.id,
  ///   'requestedPosition': '5,0',
  ///   'clampedPosition': '3,0',
  ///   'reason': 'out_of_bounds',
  /// });
  /// ```
  static void warn(String event, Map<String, dynamic> data) {
    if (!isProduction) {
      debugPrint('⚠️ WARN: $event');
      data.forEach((key, value) {
        debugPrint('  $key: $value');
      });
    }
  }

  /// Error log with structured data (operation failures, exceptions)
  ///
  /// **Format:** `<area>_<action>_error`
  ///
  /// **Example:**
  /// ```dart
  /// try {
  ///   await saveBlockPosition();
  /// } catch (e) {
  ///   AppLogger.error('drag_save_error', {
  ///     'blockId': block.id,
  ///     'position': '1,0',
  ///     'tableName': 'profile_blocks',
  ///   }, e);
  /// }
  /// ```
  static void error(String event, Map<String, dynamic> data, [Object? err]) {
    if (!isProduction) {
      debugPrint('❌ ERROR: $event');
      data.forEach((key, value) {
        debugPrint('  $key: $value');
      });
      if (err != null) {
        debugPrint('  exception: $err');
      }
    }
  }
}
