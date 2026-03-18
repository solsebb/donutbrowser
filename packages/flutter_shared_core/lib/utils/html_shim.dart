/// Platform-agnostic HTML utilities
/// Uses conditional imports to provide dart:html on web
/// and stub implementations on mobile platforms

export 'html_stub.dart' if (dart.library.html) 'html_web.dart';
