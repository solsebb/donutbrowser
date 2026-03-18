import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_shared_core/theme/models/app_theme.dart';
import 'package:flutter_shared_core/theme/providers/theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:twitterbrowser_flutter/config/brands/brands.dart';
import 'package:twitterbrowser_flutter/core/config/app_config.dart';
import 'package:twitterbrowser_flutter/core/router/app_router.dart';
import 'package:twitterbrowser_flutter/features/settings/data/models/language_locale.dart';
import 'package:twitterbrowser_flutter/features/settings/data/providers/language_locale_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  registerTwitterBrowserBrand();

  try {
    await dotenv.load(fileName: '.env', isOptional: true);
  } catch (_) {
    // Dart defines remain a valid fallback when no .env file is present.
  }

  await AppConfig.load();
  final sharedPreferences = await SharedPreferences.getInstance();

  if (AppConfig.instance.isHostedConfigured) {
    await Supabase.initialize(
      url: AppConfig.instance.supabaseUrl,
      anonKey: AppConfig.instance.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const TwitterBrowserCompanionApp(),
    ),
  );
}

class TwitterBrowserCompanionApp extends ConsumerWidget {
  const TwitterBrowserCompanionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(currentLocaleProvider);
    final themeMode = ref.watch(themeModeProvider);
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDarkMode =
        themeMode == AppThemeMode.dark ||
        (themeMode == AppThemeMode.system && brightness == Brightness.dark);
    final colors = isDarkMode ? AppThemeColors.dark : AppThemeColors.light;

    return CupertinoApp.router(
      title: 'TwitterBrowser Companion',
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
        primaryColor: colors.accentPrimary,
        scaffoldBackgroundColor: colors.primaryBackground,
        barBackgroundColor: colors.navigationBarBackground,
        textTheme: CupertinoTextThemeData(
          navLargeTitleTextStyle: GoogleFonts.inter(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: colors.primaryText,
            height: 1.1,
            letterSpacing: -0.5,
          ).copyWith(inherit: false),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            color: colors.primaryText,
            letterSpacing: -0.3,
          ).copyWith(inherit: false),
          navTitleTextStyle: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: colors.primaryText,
            letterSpacing: -0.5,
          ).copyWith(inherit: false),
          actionTextStyle: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: colors.accentPrimary,
            letterSpacing: -0.5,
          ).copyWith(inherit: false),
          tabLabelTextStyle: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: colors.primaryText,
            letterSpacing: -0.3,
          ).copyWith(inherit: false),
        ),
      ),
      locale: locale,
      supportedLocales: LanguageLocale.supportedLanguages
          .map((language) => Locale(language.languageCode, language.countryCode))
          .toList(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
