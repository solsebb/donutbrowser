import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart'
    show Colors, BoxShadow, showModalBottomSheet, showDialog, Dialog;
import 'package:flutter/physics.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_shared_core/theme/providers/theme_provider.dart';
import 'package:flutter_shared_core/theme/models/app_theme.dart';
import 'dart:ui';

/// Enum to define button layout mode
enum BottomModalButtonLayout {
  stacked, // Buttons take full width and stack vertically
  row, // Buttons are side-by-side in a row
}

/// A shared modal dialog component that provides consistent styling and behavior
/// similar to the design in the reference image - a card at the bottom of the screen.
class BottomAppModal extends ConsumerWidget {
  /// Title displayed in the header (can be a String or Widget)
  final dynamic title;

  /// Subtitle displayed below the title
  final String subtitle;

  /// Primary action button (used when buttons is null)
  final Widget? primaryButton;

  /// List of buttons for more complex layouts
  final List<Widget>? buttons;

  /// Button layout mode
  final BottomModalButtonLayout buttonLayout;

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

  const BottomAppModal({
    super.key,
    required this.title,
    required this.subtitle,
    this.primaryButton,
    this.buttons,
    this.buttonLayout = BottomModalButtonLayout.stacked,
    this.content,
    this.closeButton,
    this.onClose,
    this.useHaptics = true,
    this.padding = const EdgeInsets.all(16),
    this.showCloseButton = true,
  }) : assert(title is String || title is Widget,
            'Title must be either a String or a Widget');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get screen dimensions and safe area
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    final colors = ref.watch(themeColorsProvider);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: colors.modalBackground,
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
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipSmoothRect(
        radius: SmoothBorderRadius(
          cornerRadius: 32,
          cornerSmoothing: 0.9,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8, // Increased from 0.6 to 0.8
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
            children: [
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with title and close button
                    Stack(
                      children: [
                        // Title section centered
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Container(
                              width: double.infinity,
                              // Add horizontal padding to prevent overlap with the close button
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 36),
                              child: Column(
                                children: [
                                  if (title is String)
                                    Text(
                                      title as String,
                                      style: GoogleFonts.inter(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: colors.primaryText,
                                      ),
                                      textAlign: TextAlign.center,
                                    )
                                  else if (title is Widget)
                                    title as Widget,
                                  if (subtitle.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      subtitle,
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        color: colors.secondaryText,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Close button positioned in corner
                        if (showCloseButton)
                          Positioned(
                            left: 0,
                            top: 0,
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
                                  color: colors.tertiaryText
                                      .withValues(alpha: 0.12),
                                ),
                                child: Center(
                                  child: SvgPicture.asset(
                                    'assets/icons/arrow_2_Rounded_fill.svg',
                                    width: 10,
                                    height: 10,
                                    colorFilter: ColorFilter.mode(
                                      colors.tertiaryText,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Content (if provided)
                    if (content != null) content!,

                    // Only show buttons section if buttons or primaryButton are provided
                    if (buttons != null || primaryButton != null) ...[
                      const SizedBox(height: 24),

                      // Buttons
                      if (buttons != null) ...[
                        if (buttonLayout == BottomModalButtonLayout.row) ...[
                          // Row layout for multiple buttons
                          Row(
                            children: [
                              for (int i = 0; i < buttons!.length; i++) ...[
                                Expanded(
                                  child: _StyledModalButton(child: buttons![i]),
                                ),
                                if (i < buttons!.length - 1)
                                  const SizedBox(width: 12),
                              ],
                            ],
                          ),
                        ] else ...[
                          // Stacked layout for multiple buttons
                          for (int i = 0; i < buttons!.length; i++) ...[
                            SizedBox(
                              width: double.infinity,
                              child: _StyledModalButton(child: buttons![i]),
                            ),
                            if (i < buttons!.length - 1)
                              const SizedBox(height: 12),
                          ],
                        ],
                      ] else if (primaryButton != null) ...[
                        // Single primary button (backward compatibility)
                        SizedBox(
                          width: double.infinity,
                          child: _StyledModalButton(child: primaryButton!),
                        ),
                      ],
                    ],
                  ],
                ),
              ),

              // Add bottom safe area padding to ensure consistent margins with the bottom of the screen
              SizedBox(height: bottomSafeArea),
            ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper function to wrap BottomAppModal with light mode override if needed
Widget _wrapModalWithTheme({
  required bool forceLightMode,
  required dynamic title,
  required String subtitle,
  required Widget? primaryButton,
  required List<Widget>? buttons,
  required BottomModalButtonLayout buttonLayout,
  required Widget? content,
  required Widget? closeButton,
  required VoidCallback onClose,
  required bool useHaptics,
  required EdgeInsetsGeometry padding,
  required bool showCloseButton,
}) {
  final modal = BottomAppModal(
    title: title,
    subtitle: subtitle,
    primaryButton: primaryButton,
    buttons: buttons,
    buttonLayout: buttonLayout,
    content: content,
    closeButton: closeButton,
    onClose: onClose,
    useHaptics: useHaptics,
    padding: padding,
    showCloseButton: showCloseButton,
  );

  return forceLightMode
      ? ProviderScope(
          overrides: [
            // Force light mode colors
            themeColorsProvider.overrideWith((ref) => AppThemeColors.light),
          ],
          child: modal,
        )
      : modal;
}

/// Shows a bottom app modal as a dialog positioned at the bottom or center
Future<T?> showBottomAppModal<T>({
  required BuildContext context,
  required dynamic title,
  required String subtitle,
  Widget? primaryButton,
  List<Widget>? buttons,
  BottomModalButtonLayout buttonLayout = BottomModalButtonLayout.stacked,
  Widget? content,
  Widget? closeButton,
  VoidCallback? onClose,
  bool useHaptics = true,
  EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  bool showCloseButton = true,
  bool isDismissible = true,
  bool enableDrag = true,
  bool bounceOnDrag = false,
  bool centerModal = false, // New parameter to center the modal
  double? maxWidth, // Custom max width for web-specific sizing
  bool forceLightMode = false, // Force light mode colors regardless of theme
}) {
  assert(title is String || title is Widget,
      'Title must be either a String or a Widget');
  if (useHaptics) {
    HapticFeedback.lightImpact();
  }

  // Create a unified blur overlay effect for the entire screen
  // Use Dialog for center positioning, BottomSheet for bottom positioning
  if (centerModal) {
    return showDialog<T>(
      context: context,
      barrierDismissible: isDismissible,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth ?? 500, // Use custom max width or default to 500
                maxHeight: MediaQuery.of(context).size.height * 0.9, // Increased to 90% of screen
              ),
              child: _wrapModalWithTheme(
                forceLightMode: forceLightMode,
                title: title,
                subtitle: subtitle,
                primaryButton: primaryButton,
                buttons: buttons,
                buttonLayout: buttonLayout,
                content: content,
                closeButton: closeButton,
                onClose: onClose ?? () => Navigator.of(context).pop(),
                useHaptics: useHaptics,
                padding: padding,
                showCloseButton: showCloseButton,
              ),
            ),
          ),
        );
      },
    );
  } else {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: isDismissible, // This enables tapping outside to dismiss
      enableDrag: enableDrag && !bounceOnDrag,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      useSafeArea: false, // Set to false to handle safe area manually
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: SafeArea(
              top: false,
              bottom: true, // Apply safe area at bottom for proper padding
              child: Stack(
                children: [
                  // Fullscreen-sized transparent touch handler to close the modal
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: isDismissible
                          ? () {
                              // Close the modal when tapping outside
                              if (useHaptics) HapticFeedback.lightImpact();

                              // First check if a custom close handler is provided
                              if (onClose != null) {
                                // Call the custom close handler first
                                onClose();
                                // Don't automatically pop - let the handler decide
                                // if it wants to navigate
                              } else {
                                // Default behavior if no custom handler provided
                                Navigator.of(context).pop();
                              }
                            }
                          : null, // Disable tap if not dismissible
                    ),
                  ),
                  // The actual modal content at the bottom
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: bounceOnDrag
                        ? _BouncingModalWrapper(
                            child: _wrapModalWithTheme(
                              forceLightMode: forceLightMode,
                              title: title,
                              subtitle: subtitle,
                              primaryButton: primaryButton,
                              buttons: buttons,
                              buttonLayout: buttonLayout,
                              content: content,
                              closeButton: closeButton,
                              onClose:
                                  onClose ?? () => Navigator.of(context).pop(),
                              useHaptics: useHaptics,
                              padding: padding,
                              showCloseButton: showCloseButton,
                            ),
                          )
                        : GestureDetector(
                            // This prevents taps on the modal from closing it
                            behavior: HitTestBehavior.opaque,
                            onTap:
                                () {}, // No-op to prevent the modal from closing on tap
                            child: _wrapModalWithTheme(
                              forceLightMode: forceLightMode,
                              title: title,
                              subtitle: subtitle,
                              primaryButton: primaryButton,
                              buttons: buttons,
                              buttonLayout: buttonLayout,
                              content: content,
                              closeButton: closeButton,
                              onClose:
                                  onClose ?? () => Navigator.of(context).pop(),
                              useHaptics: useHaptics,
                              padding: padding,
                              showCloseButton: showCloseButton,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Spring physics parameters matching static_overlay_modal
const double kSpringMass = 0.8;
const double kSpringStiffness = 180.0;
const double kSpringDampingRatio = 0.65;
const double kUpwardResistance = 0.8;
const double kDownwardResistance = 0.7;

/// A wrapper widget that adds bouncing drag behavior to a modal
class _BouncingModalWrapper extends StatefulWidget {
  final Widget child;

  const _BouncingModalWrapper({
    required this.child,
  });

  @override
  State<_BouncingModalWrapper> createState() => _BouncingModalWrapperState();
}

class _BouncingModalWrapperState extends State<_BouncingModalWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _springAnimationController;
  SpringSimulation? _springSimulation;
  double _dragOffset = 0.0;
  bool _isAnimatingSpring = false;

  @override
  void initState() {
    super.initState();
    _springAnimationController = AnimationController.unbounded(vsync: this);
    _springAnimationController.addListener(() {
      if (!_isAnimatingSpring) return;
      setState(() {
        _dragOffset = _springAnimationController.value;
      });
    });
  }

  @override
  void dispose() {
    _springAnimationController.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_isAnimatingSpring) {
      _springAnimationController.stop();
      _isAnimatingSpring = false;
    }

    setState(() {
      // Apply resistance based on direction (matching static_overlay_modal)
      if (details.primaryDelta! < 0) {
        // Dragging up - apply more resistance
        _dragOffset += details.primaryDelta! * (1.0 - kUpwardResistance);
      } else {
        // Dragging down - apply less resistance
        _dragOffset += details.primaryDelta! * (1.0 - kDownwardResistance);
      }

      // Clamp to prevent excessive dragging
      _dragOffset = _dragOffset.clamp(-50.0, 300.0);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    // Always spring back to original position
    _isAnimatingSpring = true;

    final SpringDescription spring = SpringDescription.withDampingRatio(
      mass: kSpringMass,
      stiffness: kSpringStiffness,
      ratio: kSpringDampingRatio,
    );

    // Calculate velocity for spring simulation
    double springVelocity = details.velocity.pixelsPerSecond.dy / 100.0;

    _springSimulation =
        SpringSimulation(spring, _dragOffset, 0.0, -springVelocity);
    _springAnimationController.value = _dragOffset;

    _springAnimationController
        .animateWith(_springSimulation!)
        .whenCompleteOrCancel(() {
      if (mounted) {
        setState(() {
          _dragOffset = 0.0;
          _isAnimatingSpring = false;
        });
      }
    });

    // Add haptic feedback
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: _handleDragUpdate,
      onVerticalDragEnd: _handleDragEnd,
      onTap: () {}, // Prevent tap from closing
      child: Transform.translate(
        offset: Offset(0, _dragOffset),
        child: widget.child,
      ),
    );
  }
}

/// A widget that wraps modal buttons to apply consistent rounded styling
class _StyledModalButton extends StatelessWidget {
  final Widget child;

  const _StyledModalButton({required this.child});

  @override
  Widget build(BuildContext context) {
    // If the child is a CupertinoButton, wrap it in a simple rounded ClipRRect
    if (child is CupertinoButton) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(80),
        child: child,
      );
    }

    // For other widgets, return as-is
    return child;
  }
}

/// A button widget for bottom modals with consistent styling
class BottomModalButton extends ConsumerWidget {
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool isLoading;
  final bool isDisabled;
  final bool useHaptics;

  const BottomModalButton({
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

    // Use same logic as "Create New Link in Bio" button:
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
        height: 50,
        decoration: BoxDecoration(
          color: isButtonDisabled
              ? (isPrimary
                  ? primaryBgColor.withValues(alpha: 0.5)
                  : secondaryBgColor.withValues(alpha: 0.4))
              : (isPrimary ? primaryBgColor : secondaryBgColor),
          borderRadius: BorderRadius.circular(80),
          border: Border.all(
            color: isButtonDisabled
                ? colors.primaryBorder.withValues(alpha: 0.2)
                : (isPrimary ? borderColorPrimary : borderColorSecondary),
            width: 1,
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
                    fontSize: 16,
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
