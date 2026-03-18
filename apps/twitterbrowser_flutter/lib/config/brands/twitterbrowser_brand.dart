import 'package:flutter/material.dart';
import 'package:flutter_shared_core/flutter_shared_core.dart';

import 'twitterbrowser_content.dart';

class TwitterBrowserBrand extends BrandConfig {
  const TwitterBrowserBrand();

  @override
  String get brandId => 'twitterbrowser';

  @override
  String get displayName => 'TwitterBrowser';

  @override
  String get primaryDomain => 'localhost';

  @override
  List<String> get domains => const ['localhost', '127.0.0.1'];

  @override
  String get logoLight => 'logo_light.svg';

  @override
  String get logoDark => 'logo_dark.svg';

  @override
  String get logoIcon => 'logo_icon.svg';

  @override
  String get favicon => 'logo_icon_256px.png';

  @override
  Color? get primaryColor => const Color(0xFF9896FF);

  @override
  Color? get secondaryColor => const Color(0xFF6B5CE7);

  @override
  Color? get accentColor => const Color(0xFF9896FF);

  @override
  String get websiteUrl => '';

  @override
  String get supportEmail => 'twitterbrowser9@gmail.com';

  @override
  String get privacyPolicyUrl => '';

  @override
  String get termsOfServiceUrl => '';

  @override
  String get tagline => 'Profiles, clearly visible.';

  @override
  String get metaDescription =>
      'TwitterBrowser companion app for viewing local and hosted browser profiles.';

  @override
  String get shortUrlDomain => 'localhost';

  @override
  String get contactEmail => 'twitterbrowser9@gmail.com';

  @override
  String get dpoEmail => 'twitterbrowser9@gmail.com';

  @override
  String get linkedInCallbackUrl => '';

  @override
  String get twitterCallbackUrl => '';

  @override
  String get notionCallbackUrl => '';

  @override
  String get instagramCallbackUrl => '';

  @override
  String get gscCallbackUrl => '';

  @override
  String get shopifyIntegrationUrl => '';

  @override
  String get webflowIntegrationUrl => '';

  @override
  String? get affiliateUrl => null;

  @override
  String get appTypeId => 'twitterbrowser';

  @override
  BrandContent get content => const TwitterBrowserContent();
}
