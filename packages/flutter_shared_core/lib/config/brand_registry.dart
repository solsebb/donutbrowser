import 'brand_config.dart';

/// Central registry for multi-brand domain detection.
///
/// Provides O(1) domain-to-brand lookup for runtime brand detection in Flutter web.
///
/// Usage in main.dart:
/// ```dart
/// void main() async {
///   // 1. Register all brands early in startup
///   BrandRegistry.register(RankPeakBrand());
///   BrandRegistry.register(BlogSeoBrand());
///   BrandRegistry.setDefault(RankPeakBrand());
///
///   // 2. Detect brand from current domain (web only)
///   if (kIsWeb) {
///     BrandRegistry.detectFromHost(Uri.base.host);
///   }
///
///   // 3. Now BrandRegistry.current is available throughout the app
/// }
/// ```
class BrandRegistry {
  BrandRegistry._();

  /// Map of domain -> BrandConfig for O(1) lookup
  static final Map<String, BrandConfig> _domainToBrand = {};

  /// Map of brandId -> BrandConfig
  static final Map<String, BrandConfig> _idToBrand = {};

  /// Currently active brand (set by detectFromHost)
  static BrandConfig? _currentBrand;

  /// Default brand for unknown domains
  static BrandConfig? _defaultBrand;

  /// Register a brand configuration.
  ///
  /// Automatically maps all domains (including www. variants) to the brand.
  static void register(BrandConfig config) {
    _idToBrand[config.brandId] = config;

    for (final domain in config.domains) {
      // Register domain without www
      _domainToBrand[domain.toLowerCase()] = config;
      // Also register www. variant
      _domainToBrand['www.${domain.toLowerCase()}'] = config;
    }
  }

  /// Set the default brand for unknown domains.
  ///
  /// This brand is used when:
  /// - Domain is not recognized (e.g., localhost in development)
  /// - detectFromHost hasn't been called yet
  static void setDefault(BrandConfig config) {
    _defaultBrand = config;
    // If no current brand is set, use default
    _currentBrand ??= config;
  }

  /// Detect brand from hostname and set as current.
  ///
  /// Call this early in main.dart after registering all brands.
  /// Returns the detected (or default) brand.
  ///
  /// [hostname] - The hostname from Uri.base.host (e.g., "www.rankpeak.co")
  static BrandConfig detectFromHost(String hostname) {
    // Clean hostname: remove www., strip port, lowercase
    final cleanHost = hostname
        .replaceFirst(RegExp(r'^www\.', caseSensitive: false), '')
        .split(':')[0]
        .toLowerCase();

    _currentBrand = _domainToBrand[cleanHost] ?? _defaultBrand;

    if (_currentBrand == null) {
      throw StateError(
        'BrandRegistry: No brand found for domain "$cleanHost" and no default set. '
        'Call BrandRegistry.setDefault() before detectFromHost().',
      );
    }

    return _currentBrand!;
  }

  /// Get the currently active brand.
  ///
  /// Throws if no brand has been set (via detectFromHost or setDefault).
  static BrandConfig get current {
    if (_currentBrand != null) return _currentBrand!;
    if (_defaultBrand != null) return _defaultBrand!;

    throw StateError(
      'BrandRegistry: No brand configured. '
      'Call BrandRegistry.register() and BrandRegistry.setDefault() in main.dart.',
    );
  }

  /// Check if a brand has been set.
  static bool get isConfigured => _currentBrand != null || _defaultBrand != null;

  /// Get brand by ID (returns null if not found).
  static BrandConfig? getById(String brandId) => _idToBrand[brandId];

  /// Get brand by domain (returns null if not found).
  static BrandConfig? getByDomain(String domain) {
    final cleanHost = domain
        .replaceFirst(RegExp(r'^www\.', caseSensitive: false), '')
        .toLowerCase();
    return _domainToBrand[cleanHost];
  }

  /// Get all registered brands.
  static List<BrandConfig> get allBrands => _idToBrand.values.toList();

  /// Get all registered brand IDs.
  static List<String> get allBrandIds => _idToBrand.keys.toList();

  /// Reset registry (mainly for testing).
  static void reset() {
    _domainToBrand.clear();
    _idToBrand.clear();
    _currentBrand = null;
    _defaultBrand = null;
  }
}
