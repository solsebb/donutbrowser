import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:twitterbrowser_flutter/features/auth/data/providers/auth_providers.dart';
import 'package:twitterbrowser_flutter/features/auth/presentation/screens/source_entry_screen.dart';
import 'package:twitterbrowser_flutter/features/auth/presentation/screens/web_auth_screen.dart';
import 'package:twitterbrowser_flutter/features/auth/presentation/screens/web_email_otp_verification_screen.dart';
import 'package:twitterbrowser_flutter/features/navigation/presentation/screens/main_navigation_screen.dart';
import 'package:twitterbrowser_flutter/features/profiles/presentation/screens/profiles_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

final appRouterProvider = Provider<GoRouter>((ref) {
  final config = ref.watch(appConfigProvider);
  final sourceMode = ref.watch(profileSourceModeProvider);

  return GoRouter(
    initialLocation: kIsWeb ? '/auth' : '/source',
    refreshListenable: config.isHostedConfigured
        ? GoRouterRefreshStream(Supabase.instance.client.auth.onAuthStateChange)
        : null,
    redirect: (context, state) {
      final inApp = state.matchedLocation.startsWith('/app');
      final inAuth = state.matchedLocation.startsWith('/auth');
      final inSource = state.matchedLocation == '/source';
      final hostedSession = config.isHostedConfigured
          ? Supabase.instance.client.auth.currentSession
          : null;

      if (inApp &&
          sourceMode == ProfileSourceMode.hosted &&
          hostedSession == null) {
        return '/auth';
      }

      if (!kIsWeb && inAuth && sourceMode == ProfileSourceMode.local) {
        return '/app/profiles';
      }

      if (inAuth &&
          sourceMode == ProfileSourceMode.hosted &&
          hostedSession != null) {
        return '/app/profiles';
      }

      if (kIsWeb && inSource) {
        return '/auth';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/source',
        builder: (context, state) => const SourceEntryScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const WebAuthScreen(isSignUp: false),
      ),
      GoRoute(
        path: '/signin',
        builder: (context, state) => const WebAuthScreen(isSignUp: false),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const WebAuthScreen(isSignUp: true),
      ),
      GoRoute(
        path: '/auth/otp',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return WebEmailOtpVerificationScreen(email: email);
        },
      ),
      ShellRoute(
        builder: (context, state, child) => MainNavigationScreen(child: child),
        routes: [
          GoRoute(
            path: '/app/profiles',
            builder: (context, state) => const ProfilesScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => CupertinoPageScaffold(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            state.error?.toString() ?? 'Unknown navigation error',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
