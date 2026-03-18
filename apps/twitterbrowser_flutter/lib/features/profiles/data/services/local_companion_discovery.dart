import 'package:twitterbrowser_flutter/core/config/app_config.dart';
import 'package:twitterbrowser_flutter/features/profiles/data/models/local_companion_status.dart';
import 'local_companion_discovery_stub.dart'
    if (dart.library.io) 'local_companion_discovery_io.dart';

abstract class LocalCompanionDiscoveryService {
  Future<LocalCompanionStatus?> readStatus();
}

LocalCompanionDiscoveryService createLocalCompanionDiscoveryService(
  AppConfig config,
) => createLocalCompanionDiscoveryServiceImpl(config);
