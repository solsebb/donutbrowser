import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A custom gauge slider that uses SVG assets for the track and thumb
class GaugeSlider extends StatefulWidget {
  /// Current value of the slider
  final double value;

  /// Minimum possible value
  final double min;

  /// Maximum possible value
  final double max;

  /// Number of discrete divisions
  final int? divisions;

  /// Called when the user starts dragging
  final VoidCallback? onChangeStart;

  /// Called during drag operations
  final ValueChanged<double> onChanged;

  /// Called when the user is done dragging
  final ValueChanged<double>? onChangeEnd;

  /// Size of the gauge track
  final double gaugeSize;

  /// Size of the thumb/handle
  final double thumbSize;

  const GaugeSlider({
    Key? key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.onChangeStart,
    this.onChangeEnd,
    this.gaugeSize = 36,
    this.thumbSize = 28,
  }) : super(key: key);

  @override
  State<GaugeSlider> createState() => _GaugeSliderState();
}

class _GaugeSliderState extends State<GaugeSlider>
    with SingleTickerProviderStateMixin {
  bool _isDragging = false;
  late double _currentValue;
  late AnimationController _animationController;
  late Animation<double> _thumbAnimation;

  // For absolute positioning of the thumb
  double _thumbLeftPosition = 0;

  // Store the track width for calculations
  double _trackWidth = 0;

  // CRITICAL: These values define the exact visual edges of the gauge SVG
  // These have been calibrated exactly to match the design screenshots
  final double _leftVisualEdge = 30.0; // Left edge of visible gauge
  final double _rightVisualEdge =
      56.0; // Right edge greatly increased to match design screenshot

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _animationController.addListener(() {
      if (_thumbAnimation != null) {
        setState(() {
          _thumbLeftPosition = _thumbAnimation.value;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(GaugeSlider oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.value != widget.value && !_isDragging) {
      _currentValue = widget.value;
      if (_trackWidth > 0) {
        // Position the thumb based on the current value
        _updateThumbPositionFromValue();
      }
    }
  }

  // Calculate the minimum allowed position for the thumb
  double get _minThumbPosition => _leftVisualEdge;

  // Calculate the maximum allowed position for the thumb
  double get _maxThumbPosition =>
      _trackWidth - _rightVisualEdge - widget.thumbSize;

  // Convert a value to a thumb position, ensuring it stays within bounds
  double _valueToPosition(double value) {
    // Get the range of values and positions
    final valueRange = widget.max - widget.min;
    final positionRange = _maxThumbPosition - _minThumbPosition;

    // Calculate the position based on the value's percentage through the range
    final valuePercent = (value - widget.min) / valueRange;
    return _minThumbPosition + (valuePercent * positionRange);
  }

  // Convert a thumb position to a value
  double _positionToValue(double position) {
    // Calculate the usable range
    final valueRange = widget.max - widget.min;
    final positionRange = _maxThumbPosition - _minThumbPosition;

    // Calculate what percentage of the position range we're at
    final positionPercent = (position - _minThumbPosition) / positionRange;
    double value = widget.min + (positionPercent * valueRange);

    // Apply divisions if needed
    if (widget.divisions != null && widget.divisions! > 0) {
      final step = valueRange / widget.divisions!;
      value = ((value - widget.min) / step).round() * step + widget.min;
    }

    return value.clamp(widget.min, widget.max);
  }

  // Update the thumb position based on the current value
  void _updateThumbPositionFromValue() {
    if (_trackWidth <= 0) return;

    setState(() {
      _thumbLeftPosition = _valueToPosition(_currentValue);
    });
  }

  // Update the value based on thumb position
  void _updateValueFromThumbPosition() {
    _currentValue = _positionToValue(_thumbLeftPosition);
  }

  // Animate the thumb to a specific position
  void _animateThumbToPosition(double targetPosition) {
    if (_animationController.isAnimating) {
      _animationController.stop();
    }

    _thumbAnimation = Tween<double>(
      begin: _thumbLeftPosition,
      end: targetPosition,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.reset();
    _animationController.forward().then((_) {
      // Update the value when animation completes
      _updateValueFromThumbPosition();
    });
  }

  // Animate the thumb to a specific value
  void _animateToValue(double value) {
    if (_trackWidth <= 0) return;

    final targetPosition = _valueToPosition(value);
    _animateThumbToPosition(targetPosition);
  }

  // Handle the drag start event
  void _handleDragStart(DragStartDetails details) {
    if (_animationController.isAnimating) {
      _animationController.stop();
    }

    _isDragging = true;

    if (widget.onChangeStart != null) {
      widget.onChangeStart!();
    }

    HapticFeedback.selectionClick();
  }

  // Handle the drag update event
  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    // Update position with strict boundaries
    setState(() {
      _thumbLeftPosition = (_thumbLeftPosition + details.delta.dx)
          .clamp(_minThumbPosition, _maxThumbPosition);

      _updateValueFromThumbPosition();
    });

    // Notify of value change
    widget.onChanged(_currentValue);

    // Haptic feedback at division points
    if (widget.divisions != null && widget.divisions! > 0) {
      final step = (widget.max - widget.min) / widget.divisions!;
      if ((_currentValue - widget.min) % step < 0.001 ||
          step - ((_currentValue - widget.min) % step) < 0.001) {
        HapticFeedback.lightImpact();
      }
    }
  }

  // Handle the drag end event
  void _handleDragEnd(DragEndDetails details) {
    if (!_isDragging) return;

    _isDragging = false;

    // Snap to divisions if needed
    if (widget.divisions != null && widget.divisions! > 0) {
      _animateToValue(_currentValue);
    }

    if (widget.onChangeEnd != null) {
      widget.onChangeEnd!(_currentValue);
    }

    HapticFeedback.mediumImpact();
  }

  // Handle tap down on the track
  void _handleTapDown(TapDownDetails details) {
    // Ensure the tap is within the visible gauge area
    final tapX = details.localPosition.dx;
    if (tapX < _leftVisualEdge || tapX > _trackWidth - _rightVisualEdge) {
      return;
    }

    // Calculate thumb center position accounting for thumb width
    final thumbCenter = tapX - (widget.thumbSize / 2);
    final constrainedPosition =
        thumbCenter.clamp(_minThumbPosition, _maxThumbPosition);

    // Animate to the new position
    _animateThumbToPosition(constrainedPosition);

    // Update the value and notify
    setState(() {
      _thumbLeftPosition = constrainedPosition;
      _updateValueFromThumbPosition();
    });

    widget.onChanged(_currentValue);
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      // Store the track width for calculations
      _trackWidth = constraints.maxWidth;

      // Initialize the thumb position if needed
      if (_thumbLeftPosition == 0) {
        _thumbLeftPosition = _valueToPosition(_currentValue);
      }

      return SizedBox(
        height: widget.gaugeSize,
        width: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Debug visualization for track bounds (uncomment for debugging)
            /*
              Positioned(
                left: _leftVisualEdge,
                top: 0,
                bottom: 0,
                width: 2,
                child: Container(color: Colors.red),
              ),
              Positioned(
                right: _rightVisualEdge,
                top: 0,
                bottom: 0,
                width: 2,
                child: Container(color: Colors.red),
              ),
              */

            // Tappable area (full width)
            Positioned.fill(
              child: GestureDetector(
                onTapDown: _handleTapDown,
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),

            // Gauge track
            Center(
              child: SvgPicture.asset(
                'assets/icons/gauge_Rounded_fill.svg',
                width: _trackWidth,
                height: widget.gaugeSize,
                fit: BoxFit.fill,
              ),
            ),

            // Thumb - position strictly constrained to visual track
            Positioned(
              left: _thumbLeftPosition,
              top: (widget.gaugeSize - widget.thumbSize) /
                  2, // Center vertically
              child: GestureDetector(
                onHorizontalDragStart: _handleDragStart,
                onHorizontalDragUpdate: _handleDragUpdate,
                onHorizontalDragEnd: _handleDragEnd,
                child: SvgPicture.asset(
                  'assets/icons/white_ellipse_Rounded_fill.svg',
                  width: widget.thumbSize,
                  height: widget.thumbSize,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
