import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:google_fonts/google_fonts.dart';

/// Black Friday promotional badge with spinning outer text ring
///
/// Features:
/// - Black circular badge with "-50% OFF" text
/// - Outer ring with "UNTIL 28TH NOV" and "BIGGEST SALE EVER" rotating text
/// - 8-second continuous spin animation
/// - Positioned at top-right corner of pricing cards
class BlackFridayBadge extends StatefulWidget {
  /// Size of the inner black circle (default: 92px matching original design)
  final double innerCircleSize;

  /// Size of the outer spinning ring (default: 122px matching original design)
  final double outerRingSize;

  /// Rotation angle of the entire badge in degrees (default: -14.731deg)
  final double badgeRotation;

  /// Whether to show the spinning animation (default: true)
  final bool animated;

  const BlackFridayBadge({
    super.key,
    this.innerCircleSize = 92,
    this.outerRingSize = 122,
    this.badgeRotation = -14.731,
    this.animated = true,
  });

  @override
  State<BlackFridayBadge> createState() => _BlackFridayBadgeState();
}

class _BlackFridayBadgeState extends State<BlackFridayBadge>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    _initAnimation();
  }

  void _initAnimation() {
    if (!mounted) return;

    _controller = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    if (widget.animated && mounted) {
      _controller?.repeat();
    }
  }

  @override
  void dispose() {
    _controller?.stop();
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final containerSize = widget.outerRingSize + 30;

    return Transform.rotate(
      angle: widget.badgeRotation * (math.pi / 180),
      child: SizedBox(
        width: containerSize,
        height: containerSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Spinning outer ring with text
            if (_controller != null)
              AnimatedBuilder(
                animation: _controller!,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: (_controller?.value ?? 0) * 2 * math.pi,
                    child: child,
                  );
                },
                child: CustomPaint(
                  size: Size(widget.outerRingSize, widget.outerRingSize),
                  painter: _CircularTextPainter(
                    topText: 'UNTIL 28TH NOV',
                    bottomText: 'BIGGEST SALE EVER',
                    fontSize: 11,
                    letterSpacing: 2.5,
                    textColor: Colors.black,
                  ),
                ),
              ),

            // Inner black circle with "-50% OFF" text
            Transform.rotate(
              angle: -7 * (math.pi / 180),
              child: Container(
                width: widget.innerCircleSize,
                height: widget.innerCircleSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF141414),
                      Color(0xFF000000),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFFA6A6A6),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: Transform.rotate(
                    angle: -14 * (math.pi / 180),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // "-50%" with white stroke effect
                        Stack(
                          children: [
                            Text(
                              '-50%',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w900,
                                height: 1.2,
                                letterSpacing: 3.6,
                                foreground: Paint()
                                  ..style = PaintingStyle.stroke
                                  ..strokeWidth = 1
                                  ..color = Colors.white,
                              ),
                            ),
                            Text(
                              '-50%',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w900,
                                height: 1.2,
                                letterSpacing: 3.6,
                                color: Colors.transparent,
                              ),
                            ),
                          ],
                        ),
                        // "OFF" in solid white
                        Text(
                          'OFF',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                            color: Colors.white,
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
      ),
    );
  }
}

/// Custom painter for circular text around the badge
class _CircularTextPainter extends CustomPainter {
  final String topText;
  final String bottomText;
  final double fontSize;
  final double letterSpacing;
  final Color textColor;

  _CircularTextPainter({
    required this.topText,
    required this.bottomText,
    required this.fontSize,
    required this.letterSpacing,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final center = Offset(radius, radius);

    final textStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      letterSpacing: letterSpacing,
      color: textColor,
      fontFamily: 'Inter',
    );

    // Draw top arc text
    _drawCircularText(
      canvas: canvas,
      center: center,
      radius: radius - 8,
      text: topText,
      textStyle: textStyle,
      isTopArc: true,
    );

    // Draw bottom arc text
    _drawCircularText(
      canvas: canvas,
      center: center,
      radius: radius - 8,
      text: bottomText,
      textStyle: textStyle,
      isTopArc: false,
    );
  }

  void _drawCircularText({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required String text,
    required TextStyle textStyle,
    required bool isTopArc,
  }) {
    double totalWidth = 0;
    final charWidths = <double>[];

    for (int i = 0; i < text.length; i++) {
      final textPainter = TextPainter(
        text: TextSpan(text: text[i], style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      charWidths.add(textPainter.width + letterSpacing);
      totalWidth += textPainter.width + letterSpacing;
    }

    final totalAngle = totalWidth / radius;

    double currentAngle;
    if (isTopArc) {
      currentAngle = -math.pi / 2 - totalAngle / 2;
    } else {
      currentAngle = math.pi / 2 - totalAngle / 2;
    }

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      final charWidth = charWidths[i];
      final charAngle = charWidth / radius;

      final x = center.dx + radius * math.cos(currentAngle + charAngle / 2);
      final y = center.dy + radius * math.sin(currentAngle + charAngle / 2);
      final rotation = currentAngle + charAngle / 2 + (isTopArc ? math.pi / 2 : -math.pi / 2);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      final textPainter = TextPainter(
        text: TextSpan(text: char, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );

      canvas.restore();
      currentAngle += charAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _CircularTextPainter oldDelegate) {
    return oldDelegate.topText != topText ||
        oldDelegate.bottomText != bottomText ||
        oldDelegate.fontSize != fontSize ||
        oldDelegate.textColor != textColor;
  }
}
