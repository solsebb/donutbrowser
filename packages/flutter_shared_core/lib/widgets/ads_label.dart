import 'package:flutter/material.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:google_fonts/google_fonts.dart';

/// A reusable Ads label widget
/// Used to indicate ad-supported features throughout the app
class AdsLabel extends StatelessWidget {
  /// Width of the label container
  final double width;

  /// Height of the label container
  final double height;

  /// Font size of the Ads text
  final double fontSize;

  /// Corner radius of the container
  final double cornerRadius;

  const AdsLabel({
    super.key,
    this.width = 48.0,
    this.height = 28.0,
    this.fontSize = 16.0,
    this.cornerRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: ShapeDecoration(
        color: Colors.black.withAlpha(61), // Black at 24% opacity (61/255)
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: cornerRadius,
            cornerSmoothing: 0.8,
          ),
          side: BorderSide(
            color: Colors.white.withAlpha(51), // 0.2 opacity = 51/255
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
        child: Text(
          'Ads',
          style: GoogleFonts.inter(
            color: Colors.white, // Full white text, 100% opacity
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
            height: 1.0, // Ensure text is perfectly centered
          ),
        ),
      ),
    );
  }
}
