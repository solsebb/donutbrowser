/// Stub implementation of dart:ui_web types for non-web platforms
/// These are no-op implementations that allow the code to compile on mobile

/// Stub for platformViewRegistry
class _PlatformViewRegistry {
  void registerViewFactory(String viewType, dynamic Function(int viewId) viewFactory) {
    // No-op on mobile - platform views are registered differently
  }
}

/// Global platformViewRegistry stub
final platformViewRegistry = _PlatformViewRegistry();
