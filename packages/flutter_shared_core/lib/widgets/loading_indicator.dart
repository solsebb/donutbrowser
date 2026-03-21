import 'package:flutter/cupertino.dart';
import 'dart:math' as math;

class LoadingIndicator extends StatefulWidget {
  final double size;
  final Color color;
  final bool maintainState;

  const LoadingIndicator({
    super.key,
    this.size = 36.0,
    this.color = const Color(0xFF918DF6), // Purple color
    this.maintainState = true, // Keep animation state when parent rebuilds
  });

  @override
  State<LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use RepaintBoundary to prevent parent rebuilds from affecting this widget
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.rotate(
            angle: _controller.value * 2 * math.pi,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: _LoadingPainter(
                  color: widget.color,
                  thickness: widget.size / 10,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LoadingPainter extends CustomPainter {
  final Color color;
  final double thickness;

  _LoadingPainter({
    required this.color,
    required this.thickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final Rect rect = Rect.fromLTWH(
      thickness / 2,
      thickness / 2,
      size.width - thickness,
      size.height - thickness,
    );

    // Draw a full circle with reduced opacity
    paint.color = color.withValues(alpha: 0.3 * 255);
    canvas.drawArc(rect, 0, 2 * math.pi, false, paint);

    // Draw the active arc
    paint.color = color;
    canvas.drawArc(rect, -math.pi / 2, math.pi, false, paint);
  }

  @override
  bool shouldRepaint(_LoadingPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.thickness != thickness;
}
