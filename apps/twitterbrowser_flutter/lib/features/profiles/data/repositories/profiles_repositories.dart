import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:twitterbrowser_flutter/core/config/app_config.dart';
import 'package:twitterbrowser_flutter/features/auth/data/services/hosted_auth_service.dart';
import 'package:twitterbrowser_flutter/features/profiles/data/models/browser_profile_summary.dart';
import 'package:twitterbrowser_flutter/features/profiles/data/models/local_companion_status.dart';
import 'package:twitterbrowser_flutter/features/profiles/data/services/local_companion_discovery.dart';

abstract class ProfilesRepository {
  Future<List<BrowserProfileSummary>> fetchProfiles();

  Future<BrowserProfileSummary> fetchProfile(String id);
}

class ProfilesRepositoryException implements Exception {
  const ProfilesRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LocalProfilesRepository implements ProfilesRepository {
  LocalProfilesRepository(this.discoveryService, {http.Client? client})
    : client = client ?? http.Client();

  final LocalCompanionDiscoveryService discoveryService;
  final http.Client client;

  Future<LocalCompanionStatus> getCompanionStatus() async {
    final status = await discoveryService.readStatus();
    if (status == null) {
      throw const ProfilesRepositoryException(
        'Local TwitterBrowser API is unavailable. Open TwitterBrowser, then enable the Local API Server in Integrations.',
      );
    }
    return status;
  }

  @override
  Future<List<BrowserProfileSummary>> fetchProfiles() async {
    final status = await getCompanionStatus();
    final response = await client.get(
      Uri.parse('${status.baseUrl}/v1/profiles'),
      headers: {'Authorization': 'Bearer ${status.token}'},
    );

    if (response.statusCode != 200) {
      throw ProfilesRepositoryException(
        'The local TwitterBrowser API returned ${response.statusCode}. Make sure the desktop app is running and the API token is current.',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final profiles = (body['profiles'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(BrowserProfileSummary.fromLocalJson)
        .toList();
    return profiles;
  }

  @override
  Future<BrowserProfileSummary> fetchProfile(String id) async {
    final status = await getCompanionStatus();
    final response = await client.get(
      Uri.parse('${status.baseUrl}/v1/profiles/$id'),
      headers: {'Authorization': 'Bearer ${status.token}'},
    );

    if (response.statusCode != 200) {
      throw const ProfilesRepositoryException(
        'Unable to load the selected local profile.',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return BrowserProfileSummary.fromLocalJson(
      body['profile'] as Map<String, dynamic>,
    );
  }
}

class HostedProfilesRepository implements ProfilesRepository {
  HostedProfilesRepository(this.authService, this.config, {http.Client? client})
    : client = client ?? http.Client();

  final HostedAuthService authService;
  final AppConfig config;
  final http.Client client;

  @override
  Future<List<BrowserProfileSummary>> fetchProfiles() async {
    final token = await authService.issueSyncToken();
    final response = await client.get(
      Uri.parse('${config.hostedSyncUrl}/v1/profiles'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw const ProfilesRepositoryException(
        'Unable to load hosted profiles.',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['profiles'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(BrowserProfileSummary.fromHostedJson)
        .toList();
  }

  @override
  Future<BrowserProfileSummary> fetchProfile(String id) async {
    final token = await authService.issueSyncToken();
    final response = await client.get(
      Uri.parse('${config.hostedSyncUrl}/v1/profiles/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw const ProfilesRepositoryException(
        'Unable to load the selected hosted profile.',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return BrowserProfileSummary.fromHostedJson(
      body['profile'] as Map<String, dynamic>,
    );
  }
}
