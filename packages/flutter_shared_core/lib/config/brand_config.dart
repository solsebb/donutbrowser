import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'brand_content.dart';
import 'brand_registry.dart';

/// Brand-specific configuration for multi-domain white-labeling.
///
/// Unlike [AppConfig] which defines product-level settings (Supabase, Stripe, etc.),
/// [BrandConfig] defines visual branding that can change at runtime based on domain.
///
/// This enables serving multiple brands (rankpeak.co, blogseo.co, etc.) from
/// a single Flutter web build with runtime brand detection via `Uri.base.host`.
///
/// Example implementation:
/// ```dart
/// class RankPeakBrand implements BrandConfig {
///   @override
///   String get brandId => 'rankpeak';
///
///   @override
///   String get displayName => 'RankPeak';
///
///   @override
///   List<String> get domains => ['rankpeak.co', 'juump.to'];
///   // ... other properties
/// }
/// ```
abstract class BrandConfig {
  /// Const constructor to allow subclasses to be const.
  const BrandConfig();

  /// Unique brand identifier (e.g., 'rankpeak', 'blogseo')
  /// Used for asset paths and logging
  String get brandId;

  /// Display name shown in UI (e.g., 'RankPeak', 'BlogSEO')
  String get displayName;

  /// Primary domain for this brand (e.g., 'rankpeak.co')
  String get primaryDomain;

  /// All domains that should use this brand config.
  /// Include variations like 'juump.to' or 'linkks.co' that map to same brand.
  List<String> get domains;

  // ============ LOGO ASSETS ============
  // Paths relative to assets/brands/{brandId}/

  /// Light mode logo (dark text on light background)
  String get logoLight;

  /// Dark mode logo (light text on dark background)
  String get logoDark;

  /// Square icon version of logo
  String get logoIcon;

  /// Favicon for web
  String get favicon;

  // ============ BRAND COLORS ============
  // Optional overrides - if null, uses AppConfig defaults

  /// Primary brand color (optional override)
  Color? get primaryColor;

  /// Secondary brand color (optional override)
  Color? get secondaryColor;

  /// Accent color (optional override)
  Color? get accentColor;

  // ============ URLS ============

  /// Full website URL (e.g., 'https://rankpeak.co')
  String get websiteUrl;

  /// Support email address
  String get supportEmail;

  /// Privacy policy URL
  String get privacyPolicyUrl;

  /// Terms of service URL
  String get termsOfServiceUrl;

  // ============ SEO / MARKETING ============

  /// Short tagline for the brand
  String get tagline;

  /// Meta description for SEO
  String get metaDescription;

  // ============ FEATURE FLAGS ============

  /// Brand-specific feature flags (optional)
  /// Use to enable/disable features per brand
  Map<String, bool> get brandFeatureFlags => {};

  // ============ SHORT URL CONFIGURATION ============

  /// Short URL domain for links (e.g., 'rankpeak.co', 'blogseo.co')
  String get shortUrlDomain;

  /// URL prefix for link-in-bio profiles (e.g., 'rankpeak.co/')
  String get profileUrlPrefix => '$shortUrlDomain/';

  /// URL prefix for blog posts (e.g., 'rankpeak.co/b/')
  String get blogUrlPrefix => '$shortUrlDomain/b/';

  /// URL prefix for pages (e.g., 'rankpeak.co/p/')
  String get pageUrlPrefix => '$shortUrlDomain/p/';

  // ============ CONTACT EMAILS ============

  /// General contact email (e.g., 'hello@rankpeak.co')
  String get contactEmail;

  /// Data Protection Officer email for GDPR (e.g., 'dpo@rankpeak.co')
  String get dpoEmail;

  // ============ OAUTH CALLBACKS ============

  /// LinkedIn OAuth callback URL
  String get linkedInCallbackUrl;

  /// Twitter/X OAuth callback URL
  String get twitterCallbackUrl;

  /// Notion OAuth callback URL
  String get notionCallbackUrl;

  /// Instagram OAuth callback URL
  String get instagramCallbackUrl;

  /// Google Search Console OAuth callback URL
  String get gscCallbackUrl;

  // ============ INTEGRATION SERVICES ============

  /// Shopify integration OAuth URL (Fly.io service)
  String get shopifyIntegrationUrl;

  /// Webflow integration OAuth URL (Fly.io service)
  String get webflowIntegrationUrl;

  // ============ AFFILIATE PROGRAM ============

  /// FirstPromoter affiliate URL (null if no affiliate program)
  String? get affiliateUrl;

  // ============ APP IDENTIFIER ============

  /// App type identifier for Stripe/backend services (e.g., 'rankpeak', 'blogseo')
  String get appTypeId;

  // ============ BRAND CONTENT ============

  /// Brand-specific content (testimonials, FAQ, etc.)
  BrandContent get content;
}

/// Riverpod provider for the current brand configuration.
///
/// This provider returns the brand detected at app startup via [BrandRegistry].
/// Must be called after [BrandRegistry.detectFromHost] in main.dart.
///
/// Usage:
/// ```dart
/// final brand = ref.watch(brandConfigProvider);
/// Image.asset('assets/brands/${brand.brandId}/${brand.logoLight}');
/// ```
final brandConfigProvider = Provider<BrandConfig>((ref) {
  return BrandRegistry.current;
});

/// Provider for brand-specific logo asset path.
///
/// Pass `true` for dark mode, `false` for light mode.
///
/// Usage:
/// ```dart
/// final logoPath = ref.watch(brandLogoPathProvider(isDarkMode));
/// SvgPicture.asset(logoPath);
/// ```
final brandLogoPathProvider = Provider.family<String, bool>((ref, isDark) {
  final brand = ref.watch(brandConfigProvider);
  final logoFile = isDark ? brand.logoDark : brand.logoLight;
  return 'assets/brands/${brand.brandId}/$logoFile';
});

/// Provider for brand icon asset path.
final brandIconPathProvider = Provider<String>((ref) {
  final brand = ref.watch(brandConfigProvider);
  return 'assets/brands/${brand.brandId}/${brand.logoIcon}';
});

/// Brand colors with fallback to AppConfig.
///
/// If a brand doesn't define custom colors, falls back to product defaults.
class BrandColorScheme {
  final Color primary;
  final Color secondary;
  final Color accent;

  const BrandColorScheme({
    required this.primary,
    required this.secondary,
    required this.accent,
  });
}

// ============ NEW PROVIDERS FOR BRAND-AGNOSTIC CONTENT ============

/// Provider for brand short URL domain (e.g., 'rankpeak.co', 'blogseo.co')
final brandShortUrlDomainProvider = Provider<String>((ref) {
  return ref.watch(brandConfigProvider).shortUrlDomain;
});

/// Provider for brand contact email
final brandContactEmailProvider = Provider<String>((ref) {
  return ref.watch(brandConfigProvider).contactEmail;
});

/// Provider for brand DPO email (GDPR)
final brandDpoEmailProvider = Provider<String>((ref) {
  return ref.watch(brandConfigProvider).dpoEmail;
});

/// Provider for brand testimonials.
///
/// Pass 'auth' for auth screen, 'subscribe' for subscribe screen, 'compact' for side panels.
final brandTestimonialProvider =
    Provider.family<BrandTestimonial, String>((ref, type) {
  final content = ref.watch(brandConfigProvider).content;
  switch (type) {
    case 'auth':
      return content.authTestimonial;
    case 'subscribe':
      return content.subscribeTestimonial;
    case 'compact':
      return content.compactTestimonial;
    default:
      return content.authTestimonial;
  }
});

/// Provider for brand FAQ items
final brandFaqProvider = Provider<List<BrandFaqItem>>((ref) {
  return ref.watch(brandConfigProvider).content.faqItems;
});

/// Provider for brand affiliate URL (null if no affiliate program)
final brandAffiliateUrlProvider = Provider<String?>((ref) {
  return ref.watch(brandConfigProvider).affiliateUrl;
});

/// Provider for brand app type identifier
final brandAppTypeIdProvider = Provider<String>((ref) {
  return ref.watch(brandConfigProvider).appTypeId;
});
