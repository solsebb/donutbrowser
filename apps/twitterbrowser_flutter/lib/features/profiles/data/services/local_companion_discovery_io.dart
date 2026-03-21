import 'dart:convert';
import 'dart:io';

import 'package:twitterbrowser_flutter/core/config/app_config.dart';
import 'package:twitterbrowser_flutter/features/profiles/data/models/local_companion_status.dart';
import 'package:twitterbrowser_flutter/features/profiles/data/services/local_companion_discovery.dart';

class _IoLocalCompanionDiscoveryService
    implements LocalCompanionDiscoveryService {
  _IoLocalCompanionDiscoveryService(this.config);

  final AppConfig config;

  @override
  Future<LocalCompanionStatus?> readStatus() async {
    for (final path in _candidatePaths()) {
      final file = File(path);
      if (!await file.exists()) {
        continue;
      }

      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return LocalCompanionStatus.fromJson(json, filePath: path);
    }

    return null;
  }

  List<String> _candidatePaths() {
    if (config.localApiStatusPathOverride.isNotEmpty) {
      return [config.localApiStatusPathOverride];
    }

    final home = Platform.environment['HOME'];
    if (home == null || home.isEmpty) {
      return const [];
    }

    const appNames = [
      'TwitterBrowser',
      'TwitterBrowserDev',
      'TwitterBrowserLocalDev',
    ];

    return appNames
        .map(
          (name) =>
              '$home/Library/Application Support/$name/settings/local_api_companion.json',
        )
        .toList();
  }
}

LocalCompanionDiscoveryService createLocalCompanionDiscoveryServiceImpl(
  AppConfig config,
) => _IoLocalCompanionDiscoveryService(config);
