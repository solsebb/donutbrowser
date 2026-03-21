/// Stub implementation of dart:html types for non-web platforms
/// These are no-op implementations that allow the code to compile on mobile

/// Stub for html.IFrameElement
class IFrameElement {
  String src = '';
  final _Style style = _Style();
  bool allowFullscreen = false;

  void setAttribute(String name, String value) {}
}

/// Stub for style properties
class _Style {
  String border = '';
  String outline = '';
  String margin = '';
  String padding = '';
  String position = '';
  String top = '';
  String left = '';
  String width = '';
  String height = '';
  String boxSizing = '';
  String display = '';
  String overflow = '';
  String objectFit = '';
  String objectPosition = '';
  String verticalAlign = '';
  String lineHeight = '';
  String pointerEvents = '';
}

/// Stub for window operations
class Window {
  final Location location = Location();
  final History history = History();

  void open(String url, String target) {}
  void addEventListener(String type, Function callback) {}
}

class Location {
  String? pathname;
  String href = '';
}

class History {
  void pushState(dynamic data, String title, String url) {}
}

/// Global window stub
final window = Window();
