/// Shared infrastructure package for multi-product architecture.
///
/// This package contains shared code used by both RankPeak and Liink:
/// - UI widgets
/// - Theme system
/// - Authentication
/// - Subscription/payments
/// - Core services
/// - Utilities
library flutter_shared_core;

// Config
export 'config/app_config.dart';
export 'config/brand_config.dart';
export 'config/brand_content.dart';
export 'config/brand_registry.dart';

// Widgets
export 'widgets/widgets.dart';

// Theme
export 'theme/theme.dart';

// Utils
export 'utils/utils.dart';

// Auth (will be populated as we move auth)
// export 'auth/auth.dart';

// Subscription (will be populated as we move subscription)
// export 'subscription/subscription.dart';

// Services (will be populated as we move services)
// export 'services/services.dart';
