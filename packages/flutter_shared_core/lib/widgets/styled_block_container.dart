import 'package:flutter/cupertino.dart';
import 'package:figma_squircle/figma_squircle.dart';

/// A reusable styled container for profile blocks
/// Applies consistent styling (corner radius, shadow, border) to any block content
class StyledBlockContainer extends StatelessWidget {
  /// The child widget to wrap with styling
  final Widget child;

  /// Corner radius percentage (0-50, where 50 is fully circular)
  final int cornerRadius;

  /// Whether to display shadow
  final bool shadow;

  /// Whether to display border
  final bool border;

  /// Border color (if border is true)
  final Color? borderColor;

  /// Border thickness in pixels (1-10)
  final int borderThickness;

  /// Background color for the container
  final Color backgroundColor;

  /// Shadow color
  final Color shadowColor;

  /// Default border color (used when borderColor is null)
  final Color defaultBorderColor;

  /// Width of the container (defaults to full width)
  final double? width;

  /// Height of the container (optional, for dimension-controlled blocks)
  final double? height;

  /// Padding inside the container
  final EdgeInsets padding;

  const StyledBlockContainer({
    super.key,
    required this.child,
    this.cornerRadius = 16,
    this.shadow = true,
    this.border = false,
    this.borderColor,
    this.borderThickness = 2,
    required this.backgroundColor,
    required this.shadowColor,
    required this.defaultBorderColor,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    // Determine final border color
    final finalBorderColor = borderColor ?? defaultBorderColor;

    // Calculate corner radius based on percentage
    // We use a reference width for consistent radius calculation
    const referenceWidth = 390.0;
    final calculatedCornerRadius = (referenceWidth / 2) * (cornerRadius / 50);

    return Container(
      width: width ?? double.infinity,
      height: height, // Use explicit height if provided
      decoration: ShapeDecoration(
        color: backgroundColor,
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: calculatedCornerRadius,
            cornerSmoothing: 0.8,
          ),
          side: border
              ? BorderSide(
                  color: finalBorderColor,
                  width: borderThickness.toDouble(),
                )
              : BorderSide.none,
        ),
        shadows: shadow
            ? [
                BoxShadow(
                  color: shadowColor.withValues(alpha: 0.15),
                  spreadRadius: 0,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: padding,
        child: child,
      ),
    );
  }
}
