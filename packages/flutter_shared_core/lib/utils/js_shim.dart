/// Platform-agnostic js utilities
/// Uses conditional imports to provide dart:js on web
/// and stub implementations on mobile platforms

export 'js_stub.dart' if (dart.library.html) 'js_web.dart';
