class LanguageLocale {
  final String languageCode;
  final String countryCode;
  final String languageDisplayName;
  final String countryDisplayName;
  final String flagAssetPath;
  final bool isDefault;

  const LanguageLocale({
    required this.languageCode,
    required this.countryCode,
    required this.languageDisplayName,
    required this.countryDisplayName,
    required this.flagAssetPath,
    this.isDefault = false,
  });

  String get localeCode => languageCode;
  String get displayName => '$languageDisplayName ($countryDisplayName)';

  factory LanguageLocale.fromJson(Map<String, dynamic> json) {
    return LanguageLocale(
      languageCode: json['locale_code'] as String,
      countryCode: json['country_code'] as String,
      languageDisplayName: json['language_display_name'] as String,
      countryDisplayName: json['country_display_name'] as String,
      flagAssetPath: _getFlagAssetPath(json['country_code'] as String),
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'locale_code': languageCode,
      'country_code': countryCode,
      'language_display_name': languageDisplayName,
      'country_display_name': countryDisplayName,
    };
  }

  static String _getFlagAssetPath(String countryCode) {
    // Map country codes to flag asset paths
    final Map<String, String> countryToAsset = {
      'US': 'United States of America',
      'BR': 'Brazil',
      'FR': 'France',
      'ES': 'Spain',
      'SE': 'Sweden',
      'KR': 'South Korea',
      'IN': 'India',
      'ID': 'Indonesia',
      'IT': 'Italy',
      'DE': 'Germany',
      'RU': 'Russia',
      'CN': 'China',
      'JP': 'Japan',
    };

    final assetName = countryToAsset[countryCode] ?? 'United States of America';
    return 'assets/icons/country_flags_svg_icons/$assetName.svg';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LanguageLocale &&
        other.languageCode == languageCode &&
        other.countryCode == countryCode;
  }

  @override
  int get hashCode => languageCode.hashCode ^ countryCode.hashCode;

  @override
  String toString() {
    return 'LanguageLocale(languageCode: $languageCode, countryCode: $countryCode, displayName: $displayName)';
  }

  // Static list of supported languages
  static const List<LanguageLocale> supportedLanguages = [
    LanguageLocale(
      languageCode: 'en',
      countryCode: 'US',
      languageDisplayName: 'English',
      countryDisplayName: 'United States',
      flagAssetPath:
          'assets/icons/country_flags_svg_icons/United States of America.svg',
      isDefault: true,
    ),
    LanguageLocale(
      languageCode: 'ja',
      countryCode: 'JP',
      languageDisplayName: '日本語',
      countryDisplayName: 'Japan',
      flagAssetPath: 'assets/icons/country_flags_svg_icons/Japan.svg',
    ),
    LanguageLocale(
      languageCode: 'pt',
      countryCode: 'BR',
      languageDisplayName: 'Português',
      countryDisplayName: 'Brazil',
      flagAssetPath: 'assets/icons/country_flags_svg_icons/Brazil.svg',
    ),
    LanguageLocale(
      languageCode: 'fr',
      countryCode: 'FR',
      languageDisplayName: 'Français',
      countryDisplayName: 'France',
      flagAssetPath: 'assets/icons/country_flags_svg_icons/France.svg',
    ),
    LanguageLocale(
      languageCode: 'es',
      countryCode: 'ES',
      languageDisplayName: 'Español',
      countryDisplayName: 'Spain',
      flagAssetPath: 'assets/icons/country_flags_svg_icons/Spain.svg',
    ),
    LanguageLocale(
      languageCode: 'sv',
      countryCode: 'SE',
      languageDisplayName: 'Svenska',
      countryDisplayName: 'Sweden',
      flagAssetPath: 'assets/icons/country_flags_svg_icons/Sweden.svg',
    ),
    LanguageLocale(
      languageCode: 'ko',
      countryCode: 'KR',
      languageDisplayName: '한국어',
      countryDisplayName: 'South Korea',
      flagAssetPath: 'assets/icons/country_flags_svg_icons/South Korea.svg',
    ),
    LanguageLocale(
      languageCode: 'hi',
      countryCode: 'IN',
      languageDisplayName: 'हिन्दी',
      countryDisplayName: 'India',
      flagAssetPath: 'assets/icons/country_flags_svg_icons/India.svg',
    ),
    LanguageLocale(
      languageCode: 'id',
      countryCode: 'ID',
      languageDisplayName: 'Bahasa Indonesia',
      countryDisplayName: 'Indonesia',
      flagAssetPath: 'assets/icons/country_flags_svg_icons/Indonesia.svg',
    ),
    LanguageLocale(
      languageCode: 'it',
      countryCode: 'IT',
      languageDisplayName: 'Italiano',
      countryDisplayName: 'Italy',
      flagAssetPath: 'assets/icons/country_flags_svg_icons/Italy.svg',
    ),
    LanguageLocale(
      languageCode: 'de',
      countryCode: 'DE',
      languageDisplayName: 'Deutsch',
      countryDisplayName: 'Germany',
      flagAssetPath: 'assets/icons/country_flags_svg_icons/Germany.svg',
    ),
    LanguageLocale(
      languageCode: 'ru',
      countryCode: 'RU',
      languageDisplayName: 'Русский',
      countryDisplayName: 'Russia',
      flagAssetPath: 'assets/icons/country_flags_svg_icons/Russia.svg',
    ),
    LanguageLocale(
      languageCode: 'zh',
      countryCode: 'CN',
      languageDisplayName: '中文',
      countryDisplayName: 'China',
      flagAssetPath: 'assets/icons/country_flags_svg_icons/China.svg',
    ),
  ];

  static LanguageLocale get defaultLanguage => supportedLanguages.first;

  static LanguageLocale? findByLanguageCode(String languageCode) {
    try {
      return supportedLanguages.firstWhere(
        (locale) => locale.languageCode == languageCode,
      );
    } catch (e) {
      return null;
    }
  }

  static LanguageLocale? findByCountryCode(String countryCode) {
    try {
      return supportedLanguages.firstWhere(
        (locale) => locale.countryCode == countryCode,
      );
    } catch (e) {
      return null;
    }
  }
}
