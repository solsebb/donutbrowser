import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// A reusable Twitter-style rounded button widget with theme-aware styling
///
/// This button provides a consistent rounded button design used throughout the app,
/// with automatic light/dark theme adaptation and customizable properties.
///
/// Example usage:
/// ```dart
/// RoundedButton(
///   text: 'Create New',
///   onPressed: () => print('Button pressed'),
/// )
/// ```
class RoundedButton extends StatelessWidget {
  /// The text to display on the button
  final String text;

  /// Callback function when button is pressed (null = disabled state)
  final VoidCallback? onPressed;

  /// Optional icon to display before the text
  final IconData? icon;

  /// Optional custom icon widget to display before the text (overrides icon if provided)
  final Widget? iconWidget;

  /// Optional trailing icon to display after the text
  final IconData? trailingIcon;

  /// Optional custom trailing icon widget to display after the text (overrides trailingIcon if provided)
  final Widget? trailingIconWidget;

  /// Button height (defaults to 32)
  final double? height;

  /// Horizontal padding (defaults to 16)
  final double? horizontalPadding;

  /// Border radius (defaults to 24)
  final double? borderRadius;

  /// Font size (defaults to 14)
  final double? fontSize;

  /// Font weight (defaults to FontWeight.w600)
  final FontWeight? fontWeight;

  /// Letter spacing (defaults to -0.3)
  final double? letterSpacing;

  /// Override background color (defaults to theme-aware black/white)
  final Color? backgroundColor;

  /// Override text color (defaults to theme-aware white/black)
  final Color? textColor;

  /// Override border color (defaults to theme-aware)
  final Color? borderColor;

  /// Border width (defaults to 0.5)
  final double? borderWidth;

  /// Whether the button should expand to fill available width
  final bool expanded;

  /// Minimum button width
  final double? minWidth;

  /// Optional max width applied to the text label before ellipsis.
  final double? maxTextWidth;

  const RoundedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.iconWidget,
    this.trailingIcon,
    this.trailingIconWidget,
    this.height,
    this.horizontalPadding,
    this.borderRadius,
    this.fontSize,
    this.fontWeight,
    this.letterSpacing,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.borderWidth,
    this.expanded = false,
    this.minWidth,
    this.maxTextWidth,
  });

  @override
  Widget build(BuildContext context) {
    // Detect current theme
    final brightness = MediaQuery.of(context).platformBrightness;
    final isLightTheme = brightness == Brightness.light;

    // Check if button is disabled
    final isDisabled = onPressed == null;

    // Theme-aware colors
    final bgColor =
        backgroundColor ?? (isLightTheme ? Colors.black : Colors.white);
    final txtColor = textColor ?? (isLightTheme ? Colors.white : Colors.black);
    final brdColor =
        borderColor ??
        (isLightTheme
            ? Colors.black.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.1));

    // Disabled colors (50% opacity)
    final effectiveBgColor =
        isDisabled ? bgColor.withValues(alpha: 0.4) : bgColor;
    final effectiveTxtColor =
        isDisabled ? txtColor.withValues(alpha: 0.5) : txtColor;
    final effectiveBrdColor =
        isDisabled ? brdColor.withValues(alpha: 0.3) : brdColor;

    // Default sizing
    final btnHeight = height ?? 32.0;
    final hPadding = horizontalPadding ?? 16.0;
    final bRadius = borderRadius ?? 24.0;
    final fSize = fontSize ?? 14.0;
    final fWeight = fontWeight ?? FontWeight.w600;
    final lSpacing = letterSpacing ?? -0.3;
    final bWidth = borderWidth ?? 0.5;

    final textWidget = Text(
      text,
      maxLines: maxTextWidth != null ? 1 : null,
      overflow: maxTextWidth != null ? TextOverflow.ellipsis : null,
      style: GoogleFonts.inter(
        color: effectiveTxtColor,
        fontSize: fSize,
        fontWeight: fWeight,
        letterSpacing: lSpacing,
      ),
    );

    final hasText = text.trim().isNotEmpty;

    final buttonContent = Container(
      height: btnHeight,
      constraints:
          minWidth != null ? BoxConstraints(minWidth: minWidth!) : null,
      padding: EdgeInsets.symmetric(horizontal: hPadding),
      decoration: BoxDecoration(
        color: effectiveBgColor,
        borderRadius: BorderRadius.circular(bRadius),
        border: Border.all(color: effectiveBrdColor, width: bWidth),
      ),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (iconWidget != null || icon != null) ...[
            iconWidget ??
                Icon(icon!, size: fSize + 2, color: effectiveTxtColor),
            if (hasText) const SizedBox(width: 6),
          ],
          if (hasText)
            if (maxTextWidth != null)
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxTextWidth!),
                child: textWidget,
              )
            else
              textWidget,
          if (trailingIconWidget != null || trailingIcon != null) ...[
            if (hasText) const SizedBox(width: 6),
            trailingIconWidget ??
                Icon(trailingIcon!, size: fSize + 2, color: effectiveTxtColor),
          ],
        ],
      ),
    );

    final button =
        isDisabled
            ? buttonContent
            : CupertinoButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                onPressed!();
              },
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              child: buttonContent,
            );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
