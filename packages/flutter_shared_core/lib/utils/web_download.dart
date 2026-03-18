/// Platform-agnostic web download utilities
/// Uses conditional imports to provide web-only functionality on web
/// and no-op stubs on mobile platforms

export 'web_download_stub.dart' if (dart.library.html) 'web_download_web.dart';
