/// Platform-agnostic web utilities
/// Uses conditional imports to provide web-specific functionality on web
/// and no-op stubs on mobile platforms

export 'web_utils_stub.dart' if (dart.library.html) 'web_utils_web.dart';
