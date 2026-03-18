import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_shared_core/theme/providers/theme_provider.dart';
import 'package:flutter/material.dart' show Colors;

/// A shared modal dialog component that provides consistent styling and behavior
/// for various modal dialogs in the app.
class AppModal extends StatelessWidget {
  /// Title displayed in the header
  final String title;

  /// Content to display in the modal
  final Widget child;

  /// Optional content to display above the main content (e.g., image preview)
  final Widget? topContent;

  /// Whether to use haptic feedback on interactions
  final bool useHaptics;

  /// Background color of the modal (used as a tint for the glass effect)
  final Color backgroundColor;

  /// Width of the modal (defaults to screen width - 64)
  final double? width;

  /// Padding for the content area
  final EdgeInsetsGeometry contentPadding;

  /// Optional callback when close button is pressed
  final VoidCallback? onClose;

  const AppModal({
    super.key,
    required this.title,
    required this.child,
    this.topContent,
    this.useHaptics = true,
    this.backgroundColor = const Color(0xFF2A2520), // Warm beige-dark color
    this.width,
    this.contentPadding = const EdgeInsets.all(16),
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate modal width based on screen size if not provided
    final calculatedWidth = width ?? MediaQuery.of(context).size.width - 64;

    // Create a container with modal background as a backdrop filter
    return BackdropFilter(
      filter: ImageFilter.blur(
          sigmaX: 30, sigmaY: 30), // Increased blur for iOS 18 true tone effect
      child: Center(
        child: ClipSmoothRect(
          radius: SmoothBorderRadius(
            cornerRadius: 24,
            cornerSmoothing: 1,
          ),
          child: Container(
            width: calculatedWidth,
            margin: const EdgeInsets.symmetric(horizontal: 32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: ShapeDecoration(
                  // Warm beige iOS 18 glass effect with ultra-low opacity background
                  color: const Color(0xFF2A2520)
                      .withAlpha(77), // Warm beige with 30% opacity
                  shape: SmoothRectangleBorder(
                    borderRadius: SmoothBorderRadius(
                      cornerRadius: 24,
                      cornerSmoothing: 1,
                    ),
                    side: BorderSide(
                      color: const Color(0xFFF2ECE4).withAlpha(
                          51), // Warm light beige border (20% opacity)
                      width: 0.5,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              if (useHaptics) HapticFeedback.lightImpact();
                              if (onClose != null) {
                                onClose!();
                              } else {
                                Navigator.of(context).pop();
                              }
                            },
                            child: Icon(
                              CupertinoIcons.xmark,
                              color: CupertinoColors.white.withAlpha(180),
                              size: 20,
                            ),
                          ),
                          Text(
                            title,
                            style: GoogleFonts.inter(
                              color: CupertinoColors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 44), // Balance for close button
                        ],
                      ),
                    ),
                    Container(
                      height: 1,
                      color: const Color(0xFFCBC3B9)
                          .withAlpha(51), // Warm beige divider
                    ),

                    // Top content (e.g., image preview)
                    if (topContent != null) topContent!,

                    // Main content
                    Padding(
                      padding: contentPadding,
                      child: child,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Enum to define button layout mode
enum ButtonLayoutMode {
  stacked, // Buttons take full width and stack vertically
  row, // Buttons are side-by-side in a row
}

/// A shared button style for option buttons in modals
class AppModalOptionButton extends ConsumerWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool useHaptics;
  final ButtonLayoutMode layoutMode;
  final bool
      isPrimary; // For row layout, determines if this is the primary action
  final bool isLoading; // Show loading indicator instead of label

  const AppModalOptionButton({
    super.key,
    required this.label,
    this.icon,
    required this.onTap,
    this.isDestructive = false,
    this.useHaptics = true,
    this.layoutMode = ButtonLayoutMode.stacked,
    this.isPrimary = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeColorsProvider);

    // Detect light mode for border colors
    final brightness = MediaQuery.of(context).platformBrightness;
    final themeMode = ref.watch(themeModeProvider);
    final isLightMode = themeMode == AppThemeMode.light ||
                        (themeMode == AppThemeMode.system && brightness == Brightness.light);

    // Determine colors - pixel-perfect black/white like BottomModalButton
    Color backgroundColor;
    Color borderColor;
    Color textColor;

    if (isDestructive) {
      // Destructive button: red text on light background
      backgroundColor = Colors.transparent;
      borderColor = isLightMode
          ? const Color(0xFFE5E5EA)
          : colors.primaryBorder.withValues(alpha: 0.3);
      textColor = CupertinoColors.systemRed;
    } else {
      // Normal button: pure black/white
      backgroundColor = colors.primaryText;
      borderColor = colors.primaryText.withValues(alpha: 0.2);
      textColor = colors.primaryBackground;
    }

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: isLoading
          ? null
          : () {
              if (useHaptics) HapticFeedback.selectionClick();
              onTap();
            },
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: ShapeDecoration(
          color: backgroundColor,
          shape: SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius(
              cornerRadius: 160,
              cornerSmoothing: 0.8,
            ),
            side: BorderSide(
              color: borderColor,
              width: 1,
            ),
          ),
        ),
        child: Center(
          child: isLoading
              ? CupertinoActivityIndicator(color: textColor)
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    if (icon != null)
                      Icon(
                        icon!,
                        color: textColor,
                        size: 20,
                      ),
                    if (icon != null) const SizedBox(width: 8),
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// A container widget for button rows
class AppModalButtonRow extends StatelessWidget {
  final List<Widget> buttons;
  final double spacing;

  const AppModalButtonRow({
    super.key,
    required this.buttons,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < buttons.length; i++) ...[
          Expanded(child: buttons[i]),
          if (i < buttons.length - 1) SizedBox(width: spacing),
        ],
      ],
    );
  }
}
