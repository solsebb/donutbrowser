import 'package:twitterbrowser_flutter/core/config/app_config.dart';
import 'package:twitterbrowser_flutter/features/profiles/data/models/local_companion_status.dart';
import 'package:twitterbrowser_flutter/features/profiles/data/services/local_companion_discovery.dart';

class _UnsupportedLocalCompanionDiscoveryService
    implements LocalCompanionDiscoveryService {
  @override
  Future<LocalCompanionStatus?> readStatus() async => null;
}

LocalCompanionDiscoveryService createLocalCompanionDiscoveryServiceImpl(
  AppConfig config,
) => _UnsupportedLocalCompanionDiscoveryService();
