import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_shared_core/theme/providers/theme_provider.dart';
import 'package:twitterbrowser_flutter/shared/widgets/hover_tooltip.dart';
import 'package:twitterbrowser_flutter/shared/widgets/rounded_button.dart';

class SelectorTriggerButton extends ConsumerWidget {
  const SelectorTriggerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leading,
    this.trailing,
    this.tooltip,
    this.compact = false,
    this.height = 34,
    this.minWidth = 110,
    this.maxLabelWidth,
    this.horizontalPadding = 14,
    this.borderRadius = 18,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final Widget? trailing;
  final String? tooltip;
  final bool compact;
  final double height;
  final double? minWidth;
  final double? maxLabelWidth;
  final double horizontalPadding;
  final double borderRadius;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeColorsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final brightness = MediaQuery.of(context).platformBrightness;
    final isLightTheme =
        themeMode == AppThemeMode.light ||
        (themeMode == AppThemeMode.system && brightness == Brightness.light);

    Widget buildButton(double effectiveMaxLabelWidth) {
      return RoundedButton(
        text: compact ? '' : label,
        onPressed: enabled ? onPressed : null,
        iconWidget: compact ? null : leading,
        trailingIconWidget:
            trailing ??
            Transform.rotate(
              angle: 1.5708,
              child: SvgPicture.asset(
                'assets/icons/chevron_right_RoundedFill.svg',
                width: 22,
                height: 22,
                colorFilter: ColorFilter.mode(colors.secondaryText, BlendMode.srcIn),
              ),
            ),
        height: height,
        minWidth: compact ? null : minWidth,
        horizontalPadding: compact ? 10 : horizontalPadding,
        borderRadius: borderRadius,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        backgroundColor: colors.secondaryBackground.withValues(
          alpha: isLightTheme ? 0.72 : 0.42,
        ),
        textColor: colors.primaryText.withValues(alpha: 0.96),
        borderColor: colors.primaryBorder.withValues(
          alpha: isLightTheme ? 0.75 : 0.52,
        ),
        borderWidth: 0.8,
        maxTextWidth: compact ? null : effectiveMaxLabelWidth,
      );
    }

    final button = LayoutBuilder(
      builder: (context, constraints) {
        const trailingWidth = 30.0;
        const layoutSlack = 4.0;
        final leadingWidth = (!compact && leading != null) ? 28.0 : 0.0;
        final boundedWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth -
                horizontalPadding * 2 -
                trailingWidth -
                leadingWidth -
                layoutSlack
            : 260.0;
        final boundedLabelWidth = boundedWidth.clamp(72.0, 420.0).toDouble();
        final effectiveMaxLabelWidth = maxLabelWidth != null
            ? (boundedLabelWidth < maxLabelWidth! ? boundedLabelWidth : maxLabelWidth!)
            : boundedLabelWidth;
        return buildButton(effectiveMaxLabelWidth);
      },
    );

    if (tooltip == null || tooltip!.trim().isEmpty) {
      return button;
    }

    return HoverTooltip(
      message: tooltip!,
      topOffset: 34,
      leftOffset: compact ? -8 : -20,
      child: button,
    );
  }
}
