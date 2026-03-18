import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:twitterbrowser_flutter/core/config/app_config.dart';

class HostedAccountProfile {
  const HostedAccountProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.avatarUrl,
    required this.hostedSyncEnabled,
    required this.profileLimit,
    required this.cloudProfilesUsed,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final bool hostedSyncEnabled;
  final int profileLimit;
  final int cloudProfilesUsed;

  factory HostedAccountProfile.fromJson(Map<String, dynamic> json) {
    return HostedAccountProfile(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      hostedSyncEnabled: json['hosted_sync_enabled'] as bool? ?? false,
      profileLimit: json['profile_limit'] as int? ?? 0,
      cloudProfilesUsed: json['cloud_profiles_used'] as int? ?? 0,
    );
  }
}

class HostedAuthService {
  HostedAuthService(this.config);

  final AppConfig config;

  SupabaseClient get _client => Supabase.instance.client;

  Session? get currentSession => _client.auth.currentSession;

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo:
          kIsWeb ? Uri.base.origin : config.macosOAuthRedirectUrl,
    );
  }

  Future<void> sendEmailOtp({required String email}) async {
    await _client.auth.signInWithOtp(
      email: email,
      emailRedirectTo: kIsWeb ? Uri.base.origin : config.macosOAuthRedirectUrl,
    );
  }

  Future<void> verifyEmailOtp({
    required String email,
    required String code,
  }) async {
    await _client.auth.verifyOTP(
      email: email,
      token: code,
      type: OtpType.email,
    );
  }

  Future<void> verifySignupOtp({
    required String email,
    required String code,
  }) async {
    await _client.auth.verifyOTP(
      email: email,
      token: code,
      type: OtpType.signup,
    );
  }

  Future<void> sendPasswordResetEmail({
    required String email,
    String? redirectTo,
  }) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo:
          redirectTo ??
          (kIsWeb ? Uri.base.origin : config.macosOAuthRedirectUrl),
    );
  }

  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: config.oauthRedirectUrl,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<HostedAccountProfile?> fetchHostedAccountProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return null;
    }

    final result = await _client
        .from('user_profiles')
        .select(
          'id, email, display_name, avatar_url, hosted_sync_enabled, profile_limit, cloud_profiles_used',
        )
        .eq('id', user.id)
        .maybeSingle();

    if (result == null) {
      return null;
    }

    return HostedAccountProfile.fromJson(result);
  }

  Future<void> enableHostedSync() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('No hosted session is available.');
    }

    await _client
        .from('user_profiles')
        .update({'hosted_sync_enabled': true})
        .eq('id', user.id);
  }

  Future<String> issueSyncToken() async {
    final session = _client.auth.currentSession;
    if (session == null) {
      throw StateError('No hosted session is available.');
    }

    final response = await http.post(
      Uri.parse('${config.supabaseUrl}/functions/v1/issue-sync-token'),
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
        'apikey': config.supabaseAnonKey,
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw StateError(
        body['error'] as String? ?? 'Failed to issue a hosted sync token.',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final syncToken = body['syncToken'] as String?;
    if (syncToken == null || syncToken.isEmpty) {
      throw StateError('Supabase did not return a usable sync token.');
    }

    return syncToken;
  }
}
