import 'package:flutter/cupertino.dart';
import 'package:flutter_shared_core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_theme.dart';

// Provider for SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences not initialized');
});

// Provider for theme mode
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, AppThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs);
});

// Provider for current theme colors
final themeColorsProvider = Provider<AppThemeColors>((ref) {
  final themeMode = ref.watch(themeModeProvider);
  final brightness =
      WidgetsBinding.instance.platformDispatcher.platformBrightness;

  AppLogger.log('🎨 themeColorsProvider: themeMode=$themeMode, platformBrightness=$brightness');

  switch (themeMode) {
    case AppThemeMode.light:
      AppLogger.log('🎨 themeColorsProvider: Returning LIGHT theme colors');
      return AppThemeColors.light;
    case AppThemeMode.dark:
      AppLogger.log('🎨 themeColorsProvider: Returning DARK theme colors');
      return AppThemeColors.dark;
    case AppThemeMode.system:
      final result = brightness == Brightness.light
          ? AppThemeColors.light
          : AppThemeColors.dark;
      AppLogger.log('🎨 themeColorsProvider: System mode - returning ${brightness == Brightness.light ? "LIGHT" : "DARK"} theme colors');
      return result;
  }
});

// Theme mode notifier
class ThemeModeNotifier extends StateNotifier<AppThemeMode> {
  final SharedPreferences _prefs;
  static const String _themeModeKey = 'theme_mode';

  ThemeModeNotifier(this._prefs) : super(_loadThemeMode(_prefs));

  static AppThemeMode _loadThemeMode(SharedPreferences prefs) {
    final savedMode = prefs.getString(_themeModeKey);

    // If no saved theme preference exists, set a sensible default and save it
    if (savedMode == null) {
      // Default to light mode for better UX (most apps default to light)
      // This ensures consistent theme across OAuth redirects for new users
      AppLogger.log('🎨 ThemeMode: No saved preference, defaulting to LIGHT mode');
      prefs.setString(_themeModeKey, 'light');
      return AppThemeMode.light;
    }

    switch (savedMode) {
      case 'light':
        AppLogger.log('🎨 ThemeMode: Loaded LIGHT mode from SharedPreferences');
        return AppThemeMode.light;
      case 'dark':
        AppLogger.log('🎨 ThemeMode: Loaded DARK mode from SharedPreferences');
        return AppThemeMode.dark;
      case 'system':
        AppLogger.log('🎨 ThemeMode: Loaded SYSTEM mode from SharedPreferences');
        return AppThemeMode.system;
      default:
        AppLogger.log('🎨 ThemeMode: Unknown mode "$savedMode", defaulting to LIGHT');
        prefs.setString(_themeModeKey, 'light');
        return AppThemeMode.light;
    }
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    AppLogger.log('🎨 ThemeMode: Setting theme to $mode and persisting to SharedPreferences');
    state = mode;
    await _prefs.setString(_themeModeKey, mode.name);
    AppLogger.log('🎨 ThemeMode: Theme successfully saved to SharedPreferences');
  }
}

// Enum for theme modes
enum AppThemeMode {
  light,
  dark,
  system,
}
