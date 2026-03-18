import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.hostedSyncUrl,
    required this.supabaseRedirectUrl,
    required this.localApiStatusPathOverride,
  });

  factory AppConfig.test({
    String supabaseUrl = '',
    String supabaseAnonKey = '',
    String hostedSyncUrl = '',
    String supabaseRedirectUrl = '',
    String localApiStatusPathOverride = '',
  }) {
    return AppConfig(
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
      hostedSyncUrl: hostedSyncUrl,
      supabaseRedirectUrl: supabaseRedirectUrl,
      localApiStatusPathOverride: localApiStatusPathOverride,
    );
  }

  static late final AppConfig instance;

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String hostedSyncUrl;
  final String supabaseRedirectUrl;
  final String localApiStatusPathOverride;

  bool get isHostedConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      hostedSyncUrl.isNotEmpty;

  String get macosOAuthRedirectUrl => supabaseRedirectUrl.isNotEmpty
      ? supabaseRedirectUrl
      : 'twitterbrowserflutter://login-callback/';

  String get oauthRedirectUrl {
    if (kIsWeb) {
      return Uri.base.origin;
    }

    return macosOAuthRedirectUrl;
  }

  static Future<void> load() async {
    instance = AppConfig(
      supabaseUrl: _read('TWITTERBROWSER_SUPABASE_URL'),
      supabaseAnonKey: _read('TWITTERBROWSER_SUPABASE_ANON_KEY'),
      hostedSyncUrl: _read('TWITTERBROWSER_CLOUD_SYNC_URL'),
      supabaseRedirectUrl: _read('TWITTERBROWSER_SUPABASE_REDIRECT_URL'),
      localApiStatusPathOverride: _read('TWITTERBROWSER_LOCAL_API_STATUS_PATH'),
    );
  }

  static String _read(String key) {
    final fromDartDefine = switch (key) {
      'TWITTERBROWSER_SUPABASE_URL' => const String.fromEnvironment(
        'TWITTERBROWSER_SUPABASE_URL',
      ),
      'TWITTERBROWSER_SUPABASE_ANON_KEY' => const String.fromEnvironment(
        'TWITTERBROWSER_SUPABASE_ANON_KEY',
      ),
      'TWITTERBROWSER_CLOUD_SYNC_URL' => const String.fromEnvironment(
        'TWITTERBROWSER_CLOUD_SYNC_URL',
      ),
      'TWITTERBROWSER_SUPABASE_REDIRECT_URL' => const String.fromEnvironment(
        'TWITTERBROWSER_SUPABASE_REDIRECT_URL',
      ),
      'TWITTERBROWSER_LOCAL_API_STATUS_PATH' => const String.fromEnvironment(
        'TWITTERBROWSER_LOCAL_API_STATUS_PATH',
      ),
      _ => '',
    };
    if (fromDartDefine.isNotEmpty) {
      return fromDartDefine;
    }

    return dotenv.maybeGet(key)?.trim() ?? '';
  }
}
