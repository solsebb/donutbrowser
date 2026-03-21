import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter_shared_core/theme/providers/theme_provider.dart';

/// A responsive container specifically designed for onboarding screens on web/desktop.
/// Displays content within an iPad-like container with squircle corners.
class ResponsiveOnboardingContainer extends ConsumerWidget {
  final Widget child;

  /// Whether this is a modal/overlay (affects background and padding)
  final bool isModal;

  /// Maximum width for the container (iPad Pro 11" width by default)
  final double maxWidth;

  /// Maximum height for the container (iPad Pro 11" height by default)
  final double maxHeight;

  /// Corner radius for the container
  final double cornerRadius;

  /// Corner smoothing for the squircle effect (0.0 to 1.0)
  final double cornerSmoothing;

  /// Vertical padding in pixels
  final double verticalPadding;

  /// Whether to show border
  final bool showBorder;

  /// Whether to show shadow
  final bool showShadow;

  /// Minimum screen width to activate desktop container
  final double desktopBreakpoint;

  const ResponsiveOnboardingContainer({
    Key? key,
    required this.child,
    this.isModal = false,
    this.maxWidth = 834, // iPad Pro 11" width
    this.maxHeight = 1194, // iPad Pro 11" height
    this.cornerRadius = 30,
    this.cornerSmoothing = 0.9,
    this.verticalPadding = 40,
    this.showBorder = true,
    this.showShadow = true,
    this.desktopBreakpoint = 1024,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeColorsProvider);

    // Get screen dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Check if we should show desktop container
    final isDesktop = kIsWeb && screenWidth > desktopBreakpoint;

    // On mobile or if not desktop, return child directly
    if (!isDesktop) {
      return child;
    }

    // Calculate container height with padding constraint
    final availableHeight = screenHeight - (verticalPadding * 2);
    final containerHeight =
        availableHeight > maxHeight ? maxHeight : availableHeight;

    // Build the desktop container
    Widget container = Container(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        maxHeight: containerHeight,
      ),
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: isModal ? colors.modalBackground : colors.primaryBackground,
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: cornerRadius,
            cornerSmoothing: cornerSmoothing,
          ),
          side: showBorder
              ? BorderSide(
                  color: colors.primaryBorder,
                  width: 1,
                )
              : BorderSide.none,
        ),
        shadows: showShadow
            ? [
                BoxShadow(
                  color: colors.shadowColor.withValues(alpha: 0.1),
                  blurRadius: 40,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: ClipSmoothRect(
        radius: SmoothBorderRadius(
          cornerRadius: cornerRadius,
          cornerSmoothing: cornerSmoothing,
        ),
        child: child,
      ),
    );

    // Wrap with centering and padding
    return Container(
      color: colors.secondaryBackground,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: verticalPadding),
          child: container,
        ),
      ),
    );
  }
}

/// Extension to easily wrap any widget with responsive onboarding container
extension ResponsiveOnboardingExtension on Widget {
  Widget withResponsiveOnboarding({
    bool isModal = false,
    double? maxWidth,
    double? maxHeight,
    double? cornerRadius,
    double? verticalPadding,
  }) {
    return ResponsiveOnboardingContainer(
      isModal: isModal,
      maxWidth: maxWidth ?? 834,
      maxHeight: maxHeight ?? 1194,
      cornerRadius: cornerRadius ?? 30,
      verticalPadding: verticalPadding ?? 40,
      child: this,
    );
  }
}
