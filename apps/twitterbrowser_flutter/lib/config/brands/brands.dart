import 'package:flutter_shared_core/flutter_shared_core.dart';

import 'twitterbrowser_brand.dart';

void registerTwitterBrowserBrand() {
  BrandRegistry.register(const TwitterBrowserBrand());
  BrandRegistry.setDefault(const TwitterBrowserBrand());
}
