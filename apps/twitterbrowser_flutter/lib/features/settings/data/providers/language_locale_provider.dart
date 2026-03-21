import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_shared_core/theme/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twitterbrowser_flutter/features/settings/data/models/language_locale.dart';

const _languageCodePrefKey = 'twitterbrowser_flutter_language_code';

final currentLocaleProvider = Provider<Locale>((ref) {
  final language = ref.watch(languageLocaleProvider);
  return Locale(language.languageCode, language.countryCode);
});

final languageLocaleProvider =
    StateNotifierProvider<LanguageLocaleNotifier, LanguageLocale>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return LanguageLocaleNotifier(prefs);
    });

class LanguageLocaleNotifier extends StateNotifier<LanguageLocale> {
  LanguageLocaleNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static LanguageLocale _load(SharedPreferences prefs) {
    final savedLanguageCode = prefs.getString(_languageCodePrefKey);
    if (savedLanguageCode == null) {
      return LanguageLocale.defaultLanguage;
    }

    return LanguageLocale.findByLanguageCode(savedLanguageCode) ??
        LanguageLocale.defaultLanguage;
  }

  Future<void> changeLocale(LanguageLocale locale) async {
    state = locale;
    await _prefs.setString(_languageCodePrefKey, locale.languageCode);
  }
}
