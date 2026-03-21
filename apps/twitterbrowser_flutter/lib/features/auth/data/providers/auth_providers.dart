import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:twitterbrowser_flutter/core/config/app_config.dart';
import 'package:twitterbrowser_flutter/features/auth/data/services/hosted_auth_service.dart';

enum ProfileSourceMode { local, hosted }

final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.instance);

final profileSourceModeProvider = StateProvider<ProfileSourceMode>((ref) {
  return kIsWeb ? ProfileSourceMode.hosted : ProfileSourceMode.local;
});

final hostedAuthServiceProvider = Provider<HostedAuthService>((ref) {
  final config = ref.watch(appConfigProvider);
  return HostedAuthService(config);
});

final authSessionProvider = StreamProvider<Session?>((ref) async* {
  final config = ref.watch(appConfigProvider);
  if (!config.isHostedConfigured) {
    yield null;
    return;
  }

  final client = Supabase.instance.client;
  yield client.auth.currentSession;
  yield* client.auth.onAuthStateChange.map((state) => state.session);
});

final hostedAccountProfileProvider = FutureProvider<HostedAccountProfile?>((
  ref,
) async {
  final mode = ref.watch(profileSourceModeProvider);
  final config = ref.watch(appConfigProvider);

  if (mode != ProfileSourceMode.hosted || !config.isHostedConfigured) {
    return null;
  }

  final service = ref.watch(hostedAuthServiceProvider);
  return service.fetchHostedAccountProfile();
});
