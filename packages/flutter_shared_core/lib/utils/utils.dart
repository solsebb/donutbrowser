/// Shared utilities for RankPeak and Liink
library;

export 'app_logger.dart';
export 'fingerprint_helper.dart';
export 'html_shim.dart';
export 'js_shim.dart';
export 'platform_detector.dart';
// Note: ui_web_shim.dart is NOT exported here to avoid EventListener conflict with html_shim.dart
// Consumers should import it directly: import 'package:flutter_shared_core/utils/ui_web_shim.dart' as ui_web;
export 'url_normalizer.dart';
// Hide openUrlInNewTab from web_download since it's already exported from web_utils
export 'web_download.dart' hide openUrlInNewTab;
export 'web_utils.dart';
