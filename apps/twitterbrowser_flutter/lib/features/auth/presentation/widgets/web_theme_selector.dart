import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_shared_core/theme/providers/theme_provider.dart';

class WebThemeSelector extends ConsumerWidget {
  const WebThemeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeModeProvider);
    final colors = ref.watch(themeColorsProvider);

    IconData getThemeIcon(AppThemeMode mode) {
      switch (mode) {
        case AppThemeMode.light:
          return CupertinoIcons.sun_max_fill;
        case AppThemeMode.dark:
          return CupertinoIcons.moon_fill;
        case AppThemeMode.system:
          return CupertinoIcons.device_laptop;
      }
    }

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        // Cycle through themes: light -> dark -> system -> light
        final nextTheme = currentTheme == AppThemeMode.light
            ? AppThemeMode.dark
            : currentTheme == AppThemeMode.dark
                ? AppThemeMode.system
                : AppThemeMode.light;
        ref.read(themeModeProvider.notifier).setThemeMode(nextTheme);
      },
      child: Icon(
        getThemeIcon(currentTheme),
        size: 20,
        color: colors.primaryText.withValues(alpha: 0.7),
      ),
    );
  }
}
