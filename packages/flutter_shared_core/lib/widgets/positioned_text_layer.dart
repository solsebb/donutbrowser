import 'package:flutter/cupertino.dart';
import 'package:flutter_shared_core/utils/app_logger.dart';
import 'package:flutter/material.dart' show Colors, Material, MaterialType;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'dart:math' show pi;
import 'package:google_fonts/google_fonts.dart';

/// A widget that displays text that can be positioned by dragging.
class PositionedTextLayer extends ConsumerStatefulWidget {
  /// The text to display
  final String text;

  /// The style of the text
  final TextStyle textStyle;

  /// The current position of the text (normalized 0.0-1.0 coordinates)
  final Offset position;

  /// The current rotation of the text in radians
  final double rotation;

  /// Called when the text position changes
  final Function(Offset position) onPositionChanged;

  /// Called when dragging starts
  final VoidCallback? onDragStart;

  /// Called when dragging ends
  final VoidCallback? onDragEnd;

  /// Called when the text size changes through pinch gesture
  final Function(double newSize)? onSizeChanged;

  /// Called when the text rotation changes through rotation gesture
  final Function(double newRotation)? onRotationChanged;

  /// Whether the text is currently being dragged
  final bool isDragging;

  /// Whether the text should respond to drag gestures
  final bool enableDrag;

  /// Whether text resizing through pinch gesture is enabled
  final bool enableResize;

  /// Whether text rotation through rotation gesture is enabled
  final bool enableRotation;

  const PositionedTextLayer({
    super.key,
    required this.text,
    required this.textStyle,
    required this.position,
    this.rotation = 0.0,
    required this.onPositionChanged,
    this.onDragStart,
    this.onDragEnd,
    this.onSizeChanged,
    this.onRotationChanged,
    this.isDragging = false,
    this.enableDrag = true,
    this.enableResize = true,
    this.enableRotation = true,
  });

  @override
  ConsumerState<PositionedTextLayer> createState() =>
      _PositionedTextLayerState();
}

class _PositionedTextLayerState extends ConsumerState<PositionedTextLayer> {
  // Track whether we're currently handling a drag operation
  bool _isDragging = false;

  // Track whether we're currently handling a scale operation
  bool _isScaling = false;

  // Track whether we're currently handling a rotation operation
  bool _isRotating = false;

  // Keep track of the current scale value during a scale gesture
  double _currentScale = 1.0;

  // Keep track of the current rotation value during a rotation gesture
  double _currentRotation = 0.0;

  // Initial font size when scale gesture starts
  double? _initialFontSize;

  // Initial rotation when gesture starts
  double? _initialRotation;

  // Initial position when the gesture starts
  Offset? _initialPosition;

  // Track if we've notified about drag start
  bool _hasDragStarted = false;

  // Improved hit testing for text layer
  bool get _canHandleGestures =>
      widget.enableDrag || widget.enableResize || widget.enableRotation;

  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder outside of the Stack to get constraints
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate absolute position from normalized coordinates
        final textX = widget.position.dx * constraints.maxWidth;
        final textY = widget.position.dy * constraints.maxHeight;

        // Calculate the expected text size
        final textWidth = widget.text.length * widget.textStyle.fontSize! * 0.6;
        final textHeight = widget.textStyle.fontSize! * 1.2;

        // Define the gesture handling function for reuse
        void handleScaleStart(ScaleStartDetails details) {
          // Store the initial values
          _initialFontSize = widget.textStyle.fontSize;
          _initialPosition = widget.position;
          _initialRotation = widget.rotation;
          _currentScale = 1.0;
          _currentRotation = 0.0;
          _hasDragStarted = false;

          // Provide subtle feedback when the gesture starts
          HapticFeedback.selectionClick();
          AppLogger.log('🔄 TEXT LAYER GESTURE STARTED');
        }

        void handleScaleUpdate(ScaleUpdateDetails details) {
          // Handle multi-finger gestures (scale and/or rotation)
          if (details.pointerCount >= 2) {
            // Reset single-finger drag state if we were dragging
            if (_isDragging) {
              _isDragging = false;
            }

            // HANDLE SCALING (pinch to zoom)
            if (widget.enableResize) {
              // Only apply size changes if scale factor changed significantly
              if (_initialFontSize != null &&
                  (details.scale - _currentScale).abs() > 0.02) {
                _isScaling = true;
                _currentScale = details.scale;

                // Calculate new font size
                final newSize = (_initialFontSize! * details.scale)
                    .clamp(20.0, 120.0); // Limit min/max size

                // Call the callback if defined
                if (widget.onSizeChanged != null) {
                  widget.onSizeChanged!(newSize);

                  // Provide subtle haptic feedback for each size increment
                  if ((newSize * 10).round() % 5 == 0) {
                    HapticFeedback.selectionClick();
                  }
                }

                AppLogger.log(
                    '🔍 SCALING: scale=${details.scale.toStringAsFixed(2)}, '
                    'new size=${newSize.toStringAsFixed(1)}');
              }
            }

            // HANDLE ROTATION
            if (widget.enableRotation) {
              // Only apply rotation changes if rotation changed significantly
              if (_initialRotation != null && details.rotation.abs() > 0.02) {
                _isRotating = true;

                // Calculate the new rotation (add to the initial rotation)
                final newRotation = _initialRotation! + details.rotation;

                // Call the callback if defined
                if (widget.onRotationChanged != null) {
                  widget.onRotationChanged!(newRotation);

                  // Provide subtle haptic feedback for each 15-degree increment
                  if ((newRotation * 180 / pi).round() % 15 == 0) {
                    HapticFeedback.selectionClick();
                  }
                }

                AppLogger.log(
                    '🔄 ROTATING: rotation=${(details.rotation * 180 / pi).toStringAsFixed(1)}°, '
                    'new rotation=${(newRotation * 180 / pi).toStringAsFixed(1)}°');
              }
            }
          }
          // Handle single-finger drag gesture
          else if (details.pointerCount == 1 && widget.enableDrag) {
            // We're dragging, not scaling or rotating
            _isDragging = true;
            _isScaling = false;
            _isRotating = false;

            // If this is the first drag update, notify drag started
            if (!_hasDragStarted) {
              _hasDragStarted = true;

              if (widget.onDragStart != null) {
                widget.onDragStart!();
              }

              // Light impact when drag starts
              HapticFeedback.lightImpact();
              AppLogger.log('🔶 DRAG STARTED IN TEXT LAYER 🔶');
            }

            // Get the normalized delta from the focal point delta
            final normalizedDx =
                details.focalPointDelta.dx / constraints.maxWidth;
            final normalizedDy =
                details.focalPointDelta.dy / constraints.maxHeight;

            // Calculate new position, clamping to stay within bounds
            final newPosition = Offset(
              (widget.position.dx + normalizedDx).clamp(0.0, 1.0),
              (widget.position.dy + normalizedDy).clamp(0.0, 1.0),
            );

            // Update via callback
            widget.onPositionChanged(newPosition);
          }
        }

        void handleScaleEnd(ScaleEndDetails details) {
          bool needsEndCallback = false;

          // If we were dragging, notify drag ended
          if (_isDragging) {
            _isDragging = false;
            needsEndCallback = true;
            AppLogger.log('🔶 DRAG ENDED IN TEXT LAYER 🔶');
          }

          // If we were scaling or rotating, reset the state
          if (_isScaling || _isRotating) {
            _isScaling = false;
            _isRotating = false;
            needsEndCallback = true;
            AppLogger.log('🔍 SCALE/ROTATION ENDED');
          }

          // Call the drag end callback only once if needed
          if (needsEndCallback && widget.onDragEnd != null) {
            widget.onDragEnd!();
            HapticFeedback.mediumImpact();
          }

          // Reset all gesture tracking variables
          _initialFontSize = null;
          _initialRotation = null;
          _initialPosition = null;
          _hasDragStarted = false;
        }

        // Return the properly structured widget tree with Positioned as direct child of Stack
        return SizedBox.expand(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: textX,
                top: textY,
                child: Transform.translate(
                  offset: Offset(
                    // Center the text around the coordinate more accurately
                    -textWidth / 2, // Better text centering
                    -textHeight / 2, // Better vertical centering
                  ),
                  child: Transform.rotate(
                    // Apply the rotation around the center of the text
                    angle: widget.rotation,
                    child: GestureDetector(
                      // Make the touch area more reliable with translucent behavior
                      behavior: HitTestBehavior.translucent,

                      // Use scale gesture recognizer to handle drag, pinch, and rotation
                      onScaleStart:
                          _canHandleGestures ? handleScaleStart : null,
                      onScaleUpdate:
                          _canHandleGestures ? handleScaleUpdate : null,
                      onScaleEnd: _canHandleGestures ? handleScaleEnd : null,

                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // The main container with text - pure, minimalist approach
                          Transform.scale(
                            // Subtle scale for visual feedback based on active gesture
                            scale: _isScaling
                                ? 1.05
                                : (_isRotating
                                    ? 1.03
                                    : (widget.isDragging ? 1.02 : 1.0)),
                            child: AnimatedOpacity(
                              // Almost imperceptible opacity change for visual feedback
                              opacity:
                                  _isScaling || _isRotating || widget.isDragging
                                      ? 0.95
                                      : 1.0,
                              duration: const Duration(milliseconds: 150),
                              curve: Curves.easeOutCubic,
                              child: Container(
                                // Increase touch target with invisible padding
                                padding: const EdgeInsets.all(40),
                                child: Text(
                                  widget.text,
                                  style: widget.textStyle,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),

                          // Size indicator (only shown during scaling)
                          if (_isScaling && _initialFontSize != null)
                            Align(
                              alignment: Alignment.topRight,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                margin:
                                    const EdgeInsets.only(top: -20, right: -10),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${(widget.textStyle.fontSize!).round()}',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                          // Rotation indicator (only shown during rotation)
                          if (_isRotating)
                            Align(
                              alignment: Alignment.topLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                margin:
                                    const EdgeInsets.only(top: -20, left: -10),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${((widget.rotation * 180 / pi) % 360).round()}°',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
