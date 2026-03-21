import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:figma_squircle/figma_squircle.dart';

/// A responsive container that wraps the app content on web/desktop platforms
/// to display it within an iPad-like container with squircle corners.
class ResponsiveAppContainer extends StatelessWidget {
  final Widget child;

  /// Maximum width for the container (iPad-like width)
  final double maxWidth;

  /// Maximum height for the container (creates padding at top/bottom)
  final double? maxHeight;

  /// Corner radius for the container
  final double cornerRadius;

  /// Background color for the area outside the container
  final Color backgroundColor;

  /// Vertical padding percentage (0.0 to 1.0) to apply at top and bottom
  final double verticalPaddingFactor;

  /// Aspect ratio for the container (width/height)
  /// iPad-like tablets typically use 3/4 or 4/3 depending on orientation
  final double aspectRatio;

  const ResponsiveAppContainer({
    Key? key,
    required this.child,
    this.maxWidth = 1024,
    this.maxHeight,
    this.cornerRadius = 32.0,
    this.backgroundColor = const Color(0xFF121212),
    this.verticalPaddingFactor = 0.05, // 5% padding by default
    this.aspectRatio = 3 / 4, // Portrait tablet aspect ratio (width/height)
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Only apply the container on web
    if (!kIsWeb) {
      return child;
    }

    // Get screen dimensions
    final screenSize = MediaQuery.of(context).size;

    // Calculate container dimensions with padding
    final availableHeight =
        screenSize.height * (1 - (verticalPaddingFactor * 2));

    // Calculate width and height respecting aspect ratio and screen constraints
    final double containerWidth = maxWidth;

    // Determine height based on width and aspect ratio,
    // but don't exceed available height
    final double calculatedHeight = containerWidth / aspectRatio;
    final double containerHeight = maxHeight ??
        (calculatedHeight > availableHeight
            ? availableHeight
            : calculatedHeight);

    return Material(
      color: backgroundColor,
      child: Center(
        child: Container(
          width: containerWidth,
          height: containerHeight,
          margin: EdgeInsets.symmetric(
            vertical: screenSize.height * verticalPaddingFactor,
          ),
          decoration: ShapeDecoration(
            color: CupertinoColors.black,
            shape: SmoothRectangleBorder(
              borderRadius: SmoothBorderRadius(
                cornerRadius: cornerRadius,
                cornerSmoothing: 1.0,
              ),
              side: BorderSide(
                color: Colors.grey.withAlpha(51), // 20% opacity
                width: 0.5,
              ),
            ),
            shadows: [
              // Main shadow
              BoxShadow(
                color: Colors.black.withAlpha(128), // 50% opacity
                blurRadius: 20,
                spreadRadius: 5,
                offset: const Offset(0, 10),
              ),
              // Subtle inner shadow for depth
              BoxShadow(
                color: Colors.white.withAlpha(8), // Very subtle highlight
                blurRadius: 1,
                spreadRadius: -2,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: ClipSmoothRect(
            radius: SmoothBorderRadius(
              cornerRadius: cornerRadius,
              cornerSmoothing: 1.0,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
