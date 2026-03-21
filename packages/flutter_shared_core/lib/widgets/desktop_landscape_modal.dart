import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart' show Colors, BoxShadow, showDialog, Dialog, Material, MaterialType, DefaultTextStyle;
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_shared_core/theme/providers/theme_provider.dart';
import 'dart:ui';

/// Enum to define button layout mode for desktop modal
enum DesktopModalButtonLayout {
  stacked, // Buttons take full width and stack vertically
  row, // Buttons are side-by-side in a row
}

/// A desktop-specific landscape modal component (16:9 aspect ratio)
/// Designed for desktop responsive layouts with centered positioning
/// Note: Header removed - content uses full dimensions with floating close button
class DesktopLandscapeModal extends ConsumerWidget {
  /// Title (kept for backward compatibility, not displayed)
  final dynamic title;

  /// Subtitle (kept for backward compatibility, not displayed)
  final String subtitle;

  /// Primary action button (used when buttons is null)
  final Widget? primaryButton;

  /// List of buttons for more complex layouts
  final List<Widget>? buttons;

  /// Button layout mode
  final DesktopModalButtonLayout buttonLayout;

  /// Content to display in the modal
  final Widget? content;

  /// Optional close button widget (typically an X button)
  final Widget? closeButton;

  /// Optional callback when close button is pressed
  final VoidCallback? onClose;

  /// Whether to use haptic feedback on interactions
  final bool useHaptics;

  /// Content padding
  final EdgeInsetsGeometry padding;

  /// Whether to show the close button
  final bool showCloseButton;

  /// Maximum width for the modal (defaults to responsive based on screen)
  final double? maxWidth;

  /// Optional floating widget positioned below close button (e.g. currency selector)
  final Widget? floatingTopRightWidget;

  const DesktopLandscapeModal({
    super.key,
    this.title, // Optional, not displayed (kept for backward compatibility)
    this.subtitle = '', // Optional, not displayed (kept for backward compatibility)
    this.primaryButton,
    this.buttons,
    this.buttonLayout = DesktopModalButtonLayout.stacked,
    this.content,
    this.closeButton,
    this.onClose,
    this.useHaptics = true,
    this.padding = const EdgeInsets.all(24),
    this.showCloseButton = true,
    this.maxWidth,
    this.floatingTopRightWidget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeColorsProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Detect light mode to use white background
    final themeMode = ref.watch(themeModeProvider);
    final brightness = MediaQuery.of(context).platformBrightness;
    final isLightMode = themeMode == AppThemeMode.light ||
        (themeMode == AppThemeMode.system && brightness == Brightness.light);

    // Calculate 16:9 aspect ratio dimensions
    // Use 80% of screen width as base, then calculate height
    final modalWidth = maxWidth ?? (screenWidth * 0.8).clamp(800.0, 1400.0);
    final modalHeight = (modalWidth / 16 * 9).clamp(
      screenHeight * 0.5, // Minimum height
      screenHeight * 0.85, // Maximum height (85% of screen)
    );

    return Container(
      width: modalWidth,
      height: modalHeight,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: isLightMode ? Colors.white : colors.modalBackground,
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: 32,
            cornerSmoothing: 0.9,
          ),
          side: BorderSide(
            color: colors.primaryBorder.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        shadows: [
          BoxShadow(
            color: colors.shadowColor,
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipSmoothRect(
        radius: SmoothBorderRadius(
          cornerRadius: 32,
          cornerSmoothing: 0.9,
        ),
        child: Stack(
          children: [
            // Content section (full dimensions - scrollable)
            SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Content (if provided)
                  if (content != null) content!,

                  // Only show buttons section if buttons or primaryButton are provided
                  if (buttons != null || primaryButton != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          const SizedBox(height: 32),

                          // Buttons
                          if (buttons != null) ...[
                            if (buttonLayout == DesktopModalButtonLayout.row) ...[
                              // Row layout for multiple buttons
                              Row(
                                children: [
                                  for (int i = 0; i < buttons!.length; i++) ...[
                                    Expanded(
                                      child: _StyledDesktopModalButton(child: buttons![i]),
                                    ),
                                    if (i < buttons!.length - 1)
                                      const SizedBox(width: 16),
                                  ],
                                ],
                              ),
                            ] else ...[
                              // Stacked layout for multiple buttons
                              for (int i = 0; i < buttons!.length; i++) ...[
                                SizedBox(
                                  width: double.infinity,
                                  child: _StyledDesktopModalButton(child: buttons![i]),
                                ),
                                if (i < buttons!.length - 1)
                                  const SizedBox(height: 16),
                              ],
                            ],
                          ] else if (primaryButton != null) ...[
                            // Single primary button (backward compatibility)
                            SizedBox(
                              width: double.infinity,
                              child: _StyledDesktopModalButton(child: primaryButton!),
                            ),
                          ],

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Floating close button (top-right corner, positioned OVER content)
            if (showCloseButton)
              Positioned(
                top: 20,
                right: 20,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    if (useHaptics) HapticFeedback.mediumImpact();
                    // Only use the onClose handler if provided, otherwise just pop
                    if (onClose != null) {
                      onClose!();
                    } else {
                      // Default behavior if no custom handler provided
                      Navigator.of(context).pop();
                    }
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.tertiaryText.withValues(alpha: 0.12),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/icons/arrow_2_Rounded_fill.svg',
                        width: 10, // Match bottom modal icon size
                        height: 10, // Match bottom modal icon size
                        colorFilter: ColorFilter.mode(
                          colors.tertiaryText,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Optional floating widget below close button (e.g. currency selector)
            if (floatingTopRightWidget != null)
              Positioned(
                top: 56, // Below close button (20 + 24 + 12)
                right: 20,
                child: floatingTopRightWidget!,
              ),
          ],
        ),
      ),
    );
  }
}

/// Shows a desktop landscape modal as a centered dialog with 16:9 aspect ratio
/// Designed specifically for desktop responsive layouts
/// Note: title and subtitle are kept for backward compatibility but not displayed
Future<T?> showDesktopLandscapeModal<T>({
  required BuildContext context,
  dynamic title, // Kept for backward compatibility, not displayed
  String subtitle = '', // Kept for backward compatibility, not displayed
  Widget? primaryButton,
  List<Widget>? buttons,
  DesktopModalButtonLayout buttonLayout = DesktopModalButtonLayout.stacked,
  Widget? content,
  Widget? closeButton,
  VoidCallback? onClose,
  bool useHaptics = true,
  EdgeInsetsGeometry padding = const EdgeInsets.all(24),
  bool showCloseButton = true,
  bool isDismissible = true,
  double? maxWidth,
  Widget? floatingTopRightWidget,
}) {
  if (useHaptics) {
    HapticFeedback.lightImpact();
  }

  return showDialog<T>(
    context: context,
    barrierDismissible: isDismissible,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (BuildContext dialogContext) {
      // CRITICAL: Use dialogContext (not parent context) to avoid "deactivated widget" errors
      // When logout/navigation happens, parent context may be disposed but dialog is still building
      final mediaQueryData = MediaQuery.of(dialogContext);

      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
          child: MediaQuery(
            data: mediaQueryData,
            child: Material(
              type: MaterialType.transparency,
              child: DefaultTextStyle(
                // Use dialogContext to safely access inherited widgets during navigation
                style: DefaultTextStyle.of(dialogContext).style,
                child: GestureDetector(
                  // Prevent tap on modal from closing it
                  behavior: HitTestBehavior.opaque,
                  onTap: () {}, // No-op to prevent modal from closing on tap
                  child: DesktopLandscapeModal(
                    title: title,
                    subtitle: subtitle,
                    primaryButton: primaryButton,
                    buttons: buttons,
                    buttonLayout: buttonLayout,
                    content: content,
                    closeButton: closeButton,
                    onClose: onClose ?? () => Navigator.of(dialogContext).pop(),
                    useHaptics: useHaptics,
                    padding: padding,
                    showCloseButton: showCloseButton,
                    maxWidth: maxWidth,
                    floatingTopRightWidget: floatingTopRightWidget,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// A widget that wraps desktop modal buttons to apply consistent squircle styling
class _StyledDesktopModalButton extends StatelessWidget {
  final Widget child;

  const _StyledDesktopModalButton({required this.child});

  @override
  Widget build(BuildContext context) {
    // If the child is a CupertinoButton, we need to wrap it in a ClipSmoothRect
    if (child is CupertinoButton) {
      return ClipSmoothRect(
        radius: SmoothBorderRadius(
          cornerRadius: 160,
          cornerSmoothing: 0.8,
        ),
        child: child,
      );
    }

    // For other widgets, return as-is
    return child;
  }
}

/// A button widget for desktop modals with consistent styling
class DesktopModalButton extends ConsumerWidget {
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool isLoading;
  final bool isDisabled;
  final bool useHaptics;

  const DesktopModalButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
    this.isLoading = false,
    this.isDisabled = false,
    this.useHaptics = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeColorsProvider);
    final isButtonDisabled = isLoading || isDisabled;

    // Detect light mode
    final brightness = MediaQuery.of(context).platformBrightness;
    final themeMode = ref.watch(themeModeProvider);
    final isLightMode = themeMode == AppThemeMode.light ||
                        (themeMode == AppThemeMode.system && brightness == Brightness.light);

    // Use same logic as bottom modal:
    // Primary button: primaryText background + primaryBackground text
    // This gives: Light = black bg + white text, Dark = white bg + black text
    final primaryBgColor = colors.primaryText;
    final primaryHeaderColor = colors.primaryBackground;
    final secondaryBgColor = colors.cardBackground;
    final secondaryTextColor = colors.primaryText;
    final borderColorPrimary = colors.primaryText.withValues(alpha: 0.2);
    final borderColorSecondary = isLightMode
        ? const Color(0xFFE5E5EA)
        : colors.primaryBorder.withValues(alpha: 0.3);

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: isButtonDisabled
          ? null
          : () {
              if (useHaptics) HapticFeedback.selectionClick();
              onTap();
            },
      child: Container(
        height: 54,
        decoration: ShapeDecoration(
          color: isButtonDisabled
              ? (isPrimary
                  ? primaryBgColor.withValues(alpha: 0.5)
                  : secondaryBgColor.withValues(alpha: 0.4))
              : (isPrimary ? primaryBgColor : secondaryBgColor),
          shape: SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius(
              cornerRadius: 160,
              cornerSmoothing: 0.8,
            ),
            side: BorderSide(
              color: isButtonDisabled
                  ? colors.primaryBorder.withValues(alpha: 0.2)
                  : (isPrimary ? borderColorPrimary : borderColorSecondary),
              width: 1,
            ),
          ),
        ),
        child: Center(
          child: isLoading
              ? CupertinoActivityIndicator(
                  color: isPrimary ? primaryHeaderColor : secondaryTextColor,
                )
              : Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isButtonDisabled
                        ? (isPrimary ? primaryHeaderColor : colors.tertiaryText)
                        : (isPrimary ? primaryHeaderColor : secondaryTextColor),
                  ),
                ),
        ),
      ),
    );
  }
}
