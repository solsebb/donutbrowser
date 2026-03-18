import 'dart:ui';
import 'package:flutter_shared_core/utils/app_logger.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Material;
import 'package:figma_squircle/figma_squircle.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A shared toast notification component that provides consistent styling
/// matching the app's design language from AppModal.
class AppToast extends StatelessWidget {
  /// Message to display in the toast
  final String message;

  /// Optional icon to display before the message
  final IconData? icon;

  /// Optional SVG icon path to display before the message
  final String? iconPath;

  const AppToast({
    super.key,
    required this.message,
    this.icon,
    this.iconPath,
  });

  /// Show a toast message with the app's design language
  static void show({
    required BuildContext context,
    required String message,
    IconData? icon,
    String? iconPath,
    Duration duration = const Duration(seconds: 2),
  }) {
    // First check if context is valid before proceeding
    if (!context.mounted) return;

    OverlayEntry? overlayEntry;

    try {
      // Try to get overlay safely with null checks
      final overlay = Overlay.maybeOf(context);
      if (overlay == null) return;

      overlayEntry = OverlayEntry(
        builder: (innerContext) => Positioned(
          top: MediaQuery.of(innerContext).padding.top + 16,
          left: 0,
          right: 0,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: AppToast(
                message: message,
                icon: icon,
                iconPath: iconPath,
              ),
            ),
          ),
        ),
      );

      overlay.insert(overlayEntry);

      // Schedule removal using a delayed Future without context
      Future.delayed(duration, () {
        if (overlayEntry?.mounted == true) {
          overlayEntry?.remove();
        }
      });
    } catch (e) {
      AppLogger.log('Error showing toast: $e');
      // Clean up if there was an error
      if (overlayEntry?.mounted == true) {
        overlayEntry?.remove();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipSmoothRect(
      radius: SmoothBorderRadius(
        cornerRadius: 16,
        cornerSmoothing: 1,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: ShapeDecoration(
            // Warm beige iOS 18 glass effect with ultra-low opacity background
            color: const Color(0xFF2A2520)
                .withAlpha(77), // Warm beige with 30% opacity
            shape: SmoothRectangleBorder(
              borderRadius: SmoothBorderRadius(
                cornerRadius: 16,
                cornerSmoothing: 1,
              ),
              side: BorderSide(
                color: const Color(0xFFF2ECE4)
                    .withAlpha(51), // Warm light beige border (20% opacity)
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: CupertinoColors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
              ] else if (iconPath != null) ...[
                SvgPicture.asset(
                  iconPath!,
                  width: 18,
                  height: 18,
                  colorFilter: const ColorFilter.mode(
                    CupertinoColors.white,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                message,
                style: GoogleFonts.inter(
                  color: CupertinoColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
