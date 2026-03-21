import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_shared_core/theme/providers/theme_provider.dart';

class CustomBackButton extends ConsumerWidget {
  final double size;
  final double opacity;
  final VoidCallback? onPressed;
  final Color? color;

  const CustomBackButton({
    super.key,
    this.size = 28,
    this.opacity = 0.8,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeColorsProvider);

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed ??
          () {
            Navigator.of(context).pop();
          },
      child: SvgPicture.asset(
        'assets/icons/arrow_Rounded_fill.svg',
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(
          color?.withOpacity(opacity) ??
              colors.primaryText.withOpacity(opacity),
          BlendMode.srcIn,
        ),
      ),
    );
  }
}
