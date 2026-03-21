/// Stub implementation of dart:js types for non-web platforms
/// These are no-op implementations that allow the code to compile on mobile

/// Stub for JsObject
class JsObject {
  JsObject(dynamic constructor, [List? arguments]);
  JsObject.fromBrowserObject(dynamic object);

  dynamic operator [](dynamic property) => null;
  void operator []=(dynamic property, dynamic value) {}

  dynamic callMethod(String method, [List? args]) => null;
  bool hasProperty(dynamic property) => false;
  void deleteProperty(dynamic property) {}
}

/// Stub for JsFunction
class JsFunction extends JsObject {
  JsFunction.withThis(Function f) : super(null);

  dynamic apply(List args, {dynamic thisArg}) => null;
}

/// Stub for JsArray
class JsArray<E> extends JsObject {
  JsArray() : super(null);
  JsArray.from(Iterable<E> other) : super(null);

  @override
  dynamic operator [](dynamic index) => null;
  @override
  void operator []=(dynamic index, dynamic value) {}

  int get length => 0;
  void add(E value) {}
}

/// Stub for context
final JsObject context = JsObject(null);

/// Stub for allowInterop
F allowInterop<F extends Function>(F f) => f;

/// Stub for allowInteropCaptureThis
Function allowInteropCaptureThis(Function f) => f;
