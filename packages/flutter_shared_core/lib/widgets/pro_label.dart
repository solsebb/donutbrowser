import 'package:flutter/material.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:google_fonts/google_fonts.dart';

/// A reusable Pro label widget with gradient text
/// Used to indicate premium features throughout the app
class ProLabel extends StatelessWidget {
  /// Width of the label container
  final double width;

  /// Height of the label container
  final double height;

  /// Font size of the Pro text
  final double fontSize;

  /// Corner radius of the container.
  final double cornerRadius;

  /// Whether to use solid color design (purple background with white text)
  /// instead of the default gradient design (white background with gradient text)
  final bool solidColor;

  const ProLabel({
    super.key,
    this.width = 48.0,
    this.height = 28.0,
    this.fontSize = 18.0,
    this.cornerRadius = 8.0,
    this.solidColor = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: ShapeDecoration(
        color: solidColor ? const Color(0xFF918DF6) : Colors.white,
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: cornerRadius,
            cornerSmoothing: 1.0,
          ),
          side: BorderSide(
            color: solidColor
                ? Colors.transparent
                : Colors.white.withAlpha(51), // 0.2 opacity = 51/255
            width: 0.5, // Thinner border for a more refined look
          ),
        ),
        shadows: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: solidColor
            ? Text(
                'Pro',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                  height: 1.0, // Ensure text is perfectly centered
                ),
              )
            : ShaderMask(
                shaderCallback: (Rect bounds) {
                  return const LinearGradient(
                    colors: [
                      Color(0xFF786DF6), // Start color from Figma
                      Color(0xFFC763F7), // End color from Figma
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ).createShader(bounds);
                },
                child: Text(
                  'Pro',
                  style: GoogleFonts.inter(
                    color:
                        Colors.white, // This will be overridden by the gradient
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                    height: 1.0, // Ensure text is perfectly centered
                  ),
                ),
              ),
      ),
    );
  }
}
