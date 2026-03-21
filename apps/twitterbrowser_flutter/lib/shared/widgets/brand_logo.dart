import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_shared_core/flutter_shared_core.dart';

/// A brand-aware logo widget that automatically displays the correct logo
/// based on the current brand and theme mode.
///
/// Usage:
/// ```dart
/// // Full logo (auto-detects light/dark mode)
/// BrandLogo(width: 120)
///
/// // Icon version
/// BrandLogo.icon(size: 32)
///
/// // Force dark mode logo
/// BrandLogo(width: 120, forceDark: true)
/// ```
class BrandLogo extends ConsumerWidget {
  /// Width of the logo (height auto-scales)
  final double? width;

  /// Height of the logo (width auto-scales)
  final double? height;

  /// Force dark mode logo regardless of theme
  final bool? forceDark;

  /// Force light mode logo regardless of theme
  final bool? forceLight;

  /// Use icon variant instead of full logo
  final bool useIcon;

  /// Color filter to apply (optional)
  final Color? colorFilter;

  /// Semantic label for accessibility
  final String? semanticLabel;

  const BrandLogo({
    super.key,
    this.width,
    this.height,
    this.forceDark,
    this.forceLight,
    this.colorFilter,
    this.semanticLabel,
  }) : useIcon = false;

  /// Creates an icon variant of the brand logo.
  const BrandLogo.icon({
    super.key,
    double? size,
    this.colorFilter,
    this.semanticLabel,
  })  : width = size,
        height = size,
        forceDark = null,
        forceLight = null,
        useIcon = true;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(brandConfigProvider);
    final themeMode = ref.watch(themeModeProvider);
    final brightness = MediaQuery.of(context).platformBrightness;

    // Determine if we should use dark-colored logo (for light backgrounds)
    // When theme is dark → use light-colored logo (logoLight) for visibility
    // When theme is light → use dark-colored logo (logoDark) for visibility
    bool useDarkLogo;
    if (forceDark == true) {
      useDarkLogo = true; // Force dark-colored logo
    } else if (forceLight == true) {
      useDarkLogo = false; // Force light-colored logo
    } else {
      // Auto-detect based on theme
      final isThemeDark = themeMode == AppThemeMode.dark ||
          (themeMode == AppThemeMode.system && brightness == Brightness.dark);
      useDarkLogo = !isThemeDark; // Dark theme → light logo, Light theme → dark logo
    }

    // Build asset path
    final String logoFile;
    if (useIcon) {
      logoFile = brand.logoIcon;
    } else {
      // logoDark = dark-colored logo (black) for light backgrounds
      // logoLight = light-colored logo (white) for dark backgrounds
      logoFile = useDarkLogo ? brand.logoDark : brand.logoLight;
    }

    final assetPath = 'assets/brands/${brand.brandId}/$logoFile';

    // Handle different file types
    if (logoFile.endsWith('.svg')) {
      return SvgPicture.asset(
        assetPath,
        width: width,
        height: height,
        semanticsLabel: semanticLabel ?? '${brand.displayName} logo',
        colorFilter: colorFilter != null
            ? ColorFilter.mode(colorFilter!, BlendMode.srcIn)
            : null,
      );
    } else {
      // PNG, JPG, etc.
      return Image.asset(
        assetPath,
        width: width,
        height: height,
        semanticLabel: semanticLabel ?? '${brand.displayName} logo',
        color: colorFilter,
      );
    }
  }
}

/// A brand-aware favicon widget for web tab icons.
///
/// Note: This widget is mainly for displaying favicon in-app.
/// For the actual browser tab favicon, use index.html script.
class BrandFavicon extends ConsumerWidget {
  final double size;

  const BrandFavicon({
    super.key,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(brandConfigProvider);
    final assetPath = 'assets/brands/${brand.brandId}/${brand.favicon}';

    return Image.asset(
      assetPath,
      width: size,
      height: size,
      semanticLabel: '${brand.displayName} favicon',
    );
  }
}

/// Extension to get brand-specific colors with theme awareness.
extension BrandLogoColors on WidgetRef {
  /// Get the current brand's primary color.
  Color get brandPrimaryColor {
    final brand = watch(brandConfigProvider);
    return brand.primaryColor ?? const Color(0xFF9896FF);
  }

  /// Get the current brand's accent color.
  Color get brandAccentColor {
    final brand = watch(brandConfigProvider);
    return brand.accentColor ?? const Color(0xFF9896FF);
  }
}
