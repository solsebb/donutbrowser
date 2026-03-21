import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/services.dart';

/// A modal overlay that shows a loading indicator with a message
/// Designed to match the app_modal.dart styling for visual consistency
class ProcessingOverlay extends StatelessWidget {
  /// Main message displayed under the loading indicator
  final String message;

  /// Optional sub-message displayed below the main message
  final String subMessage;

  /// Whether to use haptic feedback
  final bool useHaptics;

  /// Background color tint for the glass effect
  final Color backgroundColor;

  /// Constructs a ProcessingOverlay
  const ProcessingOverlay({
    super.key,
    this.message = 'Processing',
    this.subMessage = 'This may take a moment',
    this.useHaptics = false,
    this.backgroundColor = const Color(0xFF2A2520), // Matches app_modal
  });

  @override
  Widget build(BuildContext context) {
    // Provide haptic feedback when first shown
    if (useHaptics) {
      Future.microtask(() => HapticFeedback.lightImpact());
    }

    // Calculate modal width based on screen size
    final screenWidth = MediaQuery.of(context).size.width;
    final modalWidth = screenWidth * 0.85; // 85% of screen width

    return Container(
      color:
          CupertinoColors.black.withOpacity(0.7), // Semi-transparent background
      child: BackdropFilter(
        filter: ImageFilter.blur(
            sigmaX: 30, sigmaY: 30), // Strong blur for iOS 18 true tone effect
        child: Center(
          child: ClipSmoothRect(
            radius: SmoothBorderRadius(
              cornerRadius: 24,
              cornerSmoothing: 1,
            ),
            child: Container(
              width: modalWidth,
              margin: const EdgeInsets.symmetric(horizontal: 32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: ShapeDecoration(
                    // Warm beige iOS 18 glass effect with ultra-low opacity background
                    color: backgroundColor.withAlpha(77), // 30% opacity
                    shape: SmoothRectangleBorder(
                      borderRadius: SmoothBorderRadius(
                        cornerRadius: 24,
                        cornerSmoothing: 1,
                      ),
                      side: BorderSide(
                        color: const Color(0xFFF2ECE4)
                            .withAlpha(51), // Light border (20% opacity)
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Direct loading indicator without container
                      const CupertinoActivityIndicator(
                        radius: 20, // Slightly larger for better visibility
                        color: CupertinoColors.white, // Explicit white color
                      ),
                      const SizedBox(height: 24), // Increased spacing
                      // Main message
                      Text(
                        message,
                        style: GoogleFonts.inter(
                          color: CupertinoColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      // Sub message
                      Text(
                        subMessage,
                        style: GoogleFonts.inter(
                          color: CupertinoColors.white.withOpacity(0.65),
                          fontSize: 16,
                          letterSpacing: -0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
