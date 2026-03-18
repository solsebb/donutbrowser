import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Material3 theme configuration matching Notion.so branding
/// Dark mode uses Notion's exact color palette
class AppTheme {
  // Primary purple accent color (used for both light and dark themes)
  static const _primaryColor = Color(0xFF9896FF);

  // Notion dark mode colors
  static const _notionDarkBg = Color(0xFF191919);
  static const _notionDarkSurface = Color(0xFF252525);
  static const _notionDarkText = Color(0xFFEBEBEB);
  static const _notionDarkSecondaryText = Color(0xFF9B9A97);

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.light,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.black87),
      titleTextStyle: TextStyle(
        color: Colors.black87,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    cardTheme: const CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );

  /// Dark theme - Notion.so exact branding colors
  /// Reference: https://docs.super.so/notion-colors
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.dark,
      surface: _notionDarkBg,
    ),
    scaffoldBackgroundColor: _notionDarkBg,
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: _notionDarkText,
      displayColor: _notionDarkText,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _notionDarkBg,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: _notionDarkText),
      titleTextStyle: TextStyle(
        color: _notionDarkText,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    cardTheme: const CardThemeData(
      color: _notionDarkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _notionDarkSurface,
      hintStyle: const TextStyle(color: _notionDarkSecondaryText),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    dividerColor: const Color(0xFF2F2F2F),
    dialogTheme: const DialogThemeData(
      backgroundColor: _notionDarkBg,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: _notionDarkBg,
    ),
  );
}
