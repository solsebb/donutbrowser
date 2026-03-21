import 'package:flutter/cupertino.dart';

class AppThemeColors {
  // Background colors
  final Color primaryBackground;
  final Color secondaryBackground;
  final Color tertiaryBackground;
  final Color cardBackground;
  final Color modalBackground;

  // Text colors
  final Color primaryText;
  final Color secondaryText;
  final Color tertiaryText;
  final Color placeholderText;

  // Border colors
  final Color primaryBorder;
  final Color secondaryBorder;

  // System colors
  final Color navigationBarBackground;
  final Color navigationBarBorder;
  final Color tabBarBackground;
  final Color searchBarBackground;

  // Semantic colors
  final Color accentPrimary;
  final Color accentSecondary;
  final Color success;
  final Color warning;
  final Color error;

  // Special UI elements
  final Color glassBackground;
  final Color glassBackgroundDark;
  final Color shadowColor;
  final Color highlightColor;

  // Button colors
  final Color secondaryButtonBackground;
  final Color secondaryButtonText;

  const AppThemeColors({
    required this.primaryBackground,
    required this.secondaryBackground,
    required this.tertiaryBackground,
    required this.cardBackground,
    required this.modalBackground,
    required this.primaryText,
    required this.secondaryText,
    required this.tertiaryText,
    required this.placeholderText,
    required this.primaryBorder,
    required this.secondaryBorder,
    required this.navigationBarBackground,
    required this.navigationBarBorder,
    required this.tabBarBackground,
    required this.searchBarBackground,
    required this.accentPrimary,
    required this.accentSecondary,
    required this.success,
    required this.warning,
    required this.error,
    required this.glassBackground,
    required this.glassBackgroundDark,
    required this.shadowColor,
    required this.highlightColor,
    required this.secondaryButtonBackground,
    required this.secondaryButtonText,
  });

  // Dark theme - Notion.so exact branding colors
  // Reference: https://docs.super.so/notion-colors
  // CSS Variables: --color-bg-default, --color-text-default, etc.
  static const dark = AppThemeColors(
    // Background colors - Notion dark mode palette
    // Main background: #191919 (Notion's --color-bg-default)
    primaryBackground: Color(0xFF191919),
    // Secondary surfaces: #202020 (slightly elevated)
    secondaryBackground: Color(0xFF202020),
    // Tertiary/hover: #2F2F2F (Notion's hover state)
    tertiaryBackground: Color(0xFF2F2F2F),
    // Card background: #252525 (Notion's card surfaces)
    cardBackground: Color(0xFF252525),
    // Modal background: #191919 (same as primary for consistency)
    modalBackground: Color(0xFF191919),

    // Text colors - Notion uses off-white, not pure white
    // Primary text: #EBEBEB (Notion's --color-text-default ~#e1e1e1)
    primaryText: Color(0xFFEBEBEB),
    // Secondary text: #9B9A97 (Notion's secondary/muted text)
    secondaryText: Color(0xFF9B9A97),
    // Tertiary text: #6B6B6B (dimmer text for hints)
    tertiaryText: Color(0xFF6B6B6B),
    // Placeholder text: #5A5A5A (Notion's placeholder style)
    placeholderText: Color(0xFF5A5A5A),

    // Border colors - Notion's subtle borders
    // Primary border: #2F2F2F (Notion's --color-border-default)
    primaryBorder: Color(0xFF2F2F2F),
    // Secondary border: #373737 (slightly more visible)
    secondaryBorder: Color(0xFF373737),

    // System UI colors - Notion style
    // Navigation bar: #191919 (matches primary background)
    navigationBarBackground: Color(0xFF191919),
    // Nav border: subtle 8% white opacity
    navigationBarBorder: Color(0x14FFFFFF),
    // Tab bar: #202020 (secondary background)
    tabBarBackground: Color(0xFF202020),
    // Search bar: #252525 (Notion's input background)
    searchBarBackground: Color(0xFF252525),

    // Semantic/Accent colors - Purple accent palette
    // Primary accent: #9896FF (purple - used for links, buttons)
    accentPrimary: Color(0xFF9896FF),
    // Secondary accent: #B8B6FF (lighter purple for text)
    accentSecondary: Color(0xFFB8B6FF),
    // Success: #4DAB9A (Notion's green)
    success: Color(0xFF4DAB9A),
    // Warning: #FFA344 (Notion's orange)
    warning: Color(0xFFFFA344),
    // Error: #FF7369 (Notion's red)
    error: Color(0xFFFF7369),

    // Special UI elements - Notion glass/overlay style
    // Glass background: 25% opacity of primary bg
    glassBackground: Color(0x40191919),
    // Dark glass: 60% opacity for overlays
    glassBackgroundDark: Color(0x99191919),
    // Shadow: subtle black shadow
    shadowColor: Color(0x40000000),
    // Highlight: 6% white for subtle hover states
    highlightColor: Color(0x0FFFFFFF),

    // Button colors - Notion style
    // Secondary button: 10% white opacity
    secondaryButtonBackground: Color(0x1AFFFFFF),
    // Button text: off-white (matches primary text)
    secondaryButtonText: Color(0xFFEBEBEB),
  );

  // Light theme (Notion.so style - clean light gray)
  static const light = AppThemeColors(
    // Background colors
    primaryBackground: CupertinoColors.white, // Pure white background
    secondaryBackground: Color(0xFFF8F8F8), // Notion-style light gray (not purple #F2F2F7)
    tertiaryBackground: CupertinoColors.white, // Pure white
    cardBackground: Color(0xFFF8F8F8), // Notion-style light gray for cards
    modalBackground: Color(0xFFF8F8F8), // Light gray for modals

    // Text colors
    primaryText: CupertinoColors.label, // Black
    secondaryText: CupertinoColors.secondaryLabel, // #3C3C43
    tertiaryText: CupertinoColors.tertiaryLabel, // #3C3C43 60%
    placeholderText: CupertinoColors.placeholderText, // #3C3C43 30%

    // Border colors - Notion-style subtle borders
    primaryBorder: Color(0xFFEBEBEB), // Subtle light gray border (Notion style)
    secondaryBorder: Color(0xFFE0E0E0), // Slightly more visible border

    // System colors
    navigationBarBackground:
        Color(0xFFFFFFFF), // Fully opaque pure white (no transparency)
    navigationBarBorder: CupertinoColors.separator,
    tabBarBackground: CupertinoColors.white,
    searchBarBackground: CupertinoColors.tertiarySystemFill, // #767680 12%

    // Semantic colors - Purple accent palette (same as dark for consistency)
    accentPrimary: Color(0xFF9896FF),
    accentSecondary: Color(0xFF7A78E6),
    success: Color(0xFF34C759),
    warning: Color(0xFFFF9500),
    error: Color(0xFFFF3B30),

    // Special UI elements
    glassBackground: Color(0xCCFFFFFF), // 80% opacity white
    glassBackgroundDark: Color(0xF0FFFFFF), // 94% opacity white
    shadowColor: Color(0x14000000), // 8% black
    highlightColor: Color(0x0A000000), // 4% black

    // Button colors
    secondaryButtonBackground: Color(0x1F000000), // #000000 at 12% opacity
    secondaryButtonText: CupertinoColors.label, // Black
  );

  // Helper method to get color with opacity
  Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }
}
