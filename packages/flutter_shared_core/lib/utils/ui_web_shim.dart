/// Platform-agnostic ui_web utilities
/// Uses conditional imports to provide dart:ui_web on web
/// and stub implementations on mobile platforms

export 'ui_web_stub.dart' if (dart.library.html) 'ui_web_web.dart';
