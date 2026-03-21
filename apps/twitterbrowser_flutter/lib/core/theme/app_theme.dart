import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData buildTwitterBrowserTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  const canvas = Color(0xFF0A0E13);
  const panel = Color(0xFF10161E);
  const raised = Color(0xFF171F29);
  const border = Color(0xFF293445);
  const text = Color(0xFFF4F7FB);
  const muted = Color(0xFF9AA8BB);
  const warm = Color(0xFFF56C47);
  const warmSoft = Color(0xFFFFA183);
  const mint = Color(0xFF5DD0B4);
  const paper = Color(0xFFF7F4EE);
  const ink = Color(0xFF131821);
  const line = Color(0xFFD7D3CA);

  final scheme = ColorScheme(
    brightness: brightness,
    primary: warm,
    onPrimary: Colors.white,
    secondary: isDark ? warmSoft : const Color(0xFF3A495D),
    onSecondary: isDark ? canvas : Colors.white,
    error: const Color(0xFFEF5350),
    onError: Colors.white,
    surface: isDark ? panel : Colors.white,
    onSurface: isDark ? text : ink,
    surfaceContainerHighest: isDark ? raised : paper,
    onSurfaceVariant: isDark ? muted : const Color(0xFF67768B),
    outline: isDark ? border : line,
    shadow: Colors.black,
    scrim: Colors.black54,
    inverseSurface: isDark ? paper : canvas,
    onInverseSurface: isDark ? ink : text,
    inversePrimary: warmSoft,
    tertiary: mint,
    onTertiary: canvas,
    surfaceTint: warm,
  );

  final baseTextTheme = GoogleFonts.interTextTheme().apply(
    bodyColor: scheme.onSurface,
    displayColor: scheme.onSurface,
  );

  final textTheme = baseTextTheme.copyWith(
    displayLarge: GoogleFonts.inter(
      fontSize: 56,
      fontWeight: FontWeight.w700,
      letterSpacing: -2.2,
      color: scheme.onSurface,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: 46,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.6,
      color: scheme.onSurface,
    ),
    headlineLarge: GoogleFonts.inter(
      fontSize: 36,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.0,
      color: scheme.onSurface,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.7,
      color: scheme.onSurface,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
      color: scheme.onSurface,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: scheme.onSurface,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: scheme.onSurface,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: scheme.onSurface,
      height: 1.55,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: scheme.onSurface,
      height: 1.5,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: scheme.onSurfaceVariant,
      height: 1.4,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: scheme.onSurface,
      letterSpacing: 0.1,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: scheme.onSurfaceVariant,
      letterSpacing: 0.3,
    ),
  );

  OutlineInputBorder borderShape(double width, Color color) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: color, width: width),
      );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: isDark ? canvas : const Color(0xFFF2EEE6),
    textTheme: textTheme,
    cardTheme: CardThemeData(
      color: scheme.surface.withValues(alpha: isDark ? 0.92 : 0.96),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.28)),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outline.withValues(alpha: 0.24),
      space: 1,
      thickness: 1,
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      side: BorderSide(color: scheme.outline.withValues(alpha: 0.18)),
      backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.32),
      labelStyle: textTheme.labelMedium?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      selectedColor: scheme.primary.withValues(alpha: 0.16),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF121922) : Colors.white,
      hintStyle: textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
      labelStyle: textTheme.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
      border: borderShape(1, scheme.outline.withValues(alpha: 0.22)),
      enabledBorder: borderShape(1, scheme.outline.withValues(alpha: 0.22)),
      focusedBorder: borderShape(1.3, scheme.primary.withValues(alpha: 0.85)),
      errorBorder: borderShape(1.1, scheme.error.withValues(alpha: 0.8)),
      focusedErrorBorder: borderShape(1.3, scheme.error),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      prefixIconColor: scheme.onSurfaceVariant,
      suffixIconColor: scheme.onSurfaceVariant,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: textTheme.titleMedium?.copyWith(color: scheme.onPrimary),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.28)),
        textStyle: textTheme.titleMedium,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(textStyle: textTheme.titleMedium),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: textTheme.titleLarge,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isDark ? raised : Colors.white,
      contentTextStyle: textTheme.bodyMedium,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
  );
}
