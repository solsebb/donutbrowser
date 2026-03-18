import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Abstract configuration interface that each product app must implement.
///
/// This allows shared code to access product-specific values without
/// knowing which product is running.
///
/// Example usage in main.dart:
/// ```dart
/// void main() {
///   runApp(
///     ProviderScope(
///       overrides: [
///         appConfigProvider.overrideWithValue(RankPeakConfig()),
///       ],
///       child: const MyApp(),
///     ),
///   );
/// }
/// ```
abstract class AppConfig {
  /// The display name of the app (e.g., "RankPeak", "Liink")
  String get appName;

  /// The product identifier used for analytics and logging
  String get productId;

  /// Supabase project URL
  String get supabaseUrl;

  /// Supabase anonymous key
  String get supabaseAnonKey;

  /// Stripe publishable key (for web payments)
  String get stripePublishableKey;

  /// RevenueCat API key (for iOS/Android subscriptions)
  String get revenueCatApiKey;

  /// Firebase project ID
  String get firebaseProjectId;

  /// Primary brand color
  Color get primaryColor;

  /// Secondary brand color
  Color get secondaryColor;

  /// Accent color
  Color get accentColor;

  /// App website URL (for links, sharing, etc.)
  String get websiteUrl;

  /// Support email address
  String get supportEmail;

  /// Privacy policy URL
  String get privacyPolicyUrl;

  /// Terms of service URL
  String get termsOfServiceUrl;

  /// Whether to enable analytics in this environment
  bool get analyticsEnabled;

  /// Whether this is a production build
  bool get isProduction;

  /// Feature flags for the product
  Map<String, bool> get featureFlags;
}

/// Riverpod provider for AppConfig.
///
/// This MUST be overridden in each product's main.dart.
/// If not overridden, accessing this provider will throw an error.
final appConfigProvider = Provider<AppConfig>((ref) {
  throw UnimplementedError(
    'appConfigProvider must be overridden in ProviderScope. '
    'Add: appConfigProvider.overrideWithValue(YourAppConfig()) '
    'to your ProviderScope overrides in main.dart',
  );
});

/// Convenience provider to access product-specific colors
final brandColorsProvider = Provider<BrandColors>((ref) {
  final config = ref.watch(appConfigProvider);
  return BrandColors(
    primary: config.primaryColor,
    secondary: config.secondaryColor,
    accent: config.accentColor,
  );
});

/// Brand colors container
class BrandColors {
  final Color primary;
  final Color secondary;
  final Color accent;

  const BrandColors({
    required this.primary,
    required this.secondary,
    required this.accent,
  });
}

/// Helper extension to check feature flags
extension AppConfigFeatures on AppConfig {
  bool hasFeature(String featureName) {
    return featureFlags[featureName] ?? false;
  }
}
