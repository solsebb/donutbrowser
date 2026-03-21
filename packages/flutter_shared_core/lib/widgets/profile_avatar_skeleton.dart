import 'package:flutter/cupertino.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter_skeleton_ui/flutter_skeleton_ui.dart';
import 'package:flutter_shared_core/theme/models/app_theme.dart';

/// Skeleton loader for profile avatars during loading/uploading states
/// Uses flutter_skeleton_ui package for clean, simple skeleton animations
/// Matches the profile_block_skeleton.dart pattern for consistency
class ProfileAvatarSkeleton extends StatelessWidget {
  /// The size of the avatar skeleton (diameter)
  final double size;

  /// Theme colors for skeleton styling
  final AppThemeColors colors;

  /// Corner radius for the avatar skeleton
  /// Defaults to size/2 for a perfect circle
  final double? cornerRadius;

  /// Corner smoothing for figma squircle (0-1)
  /// Defaults to 1 for maximum smoothing
  final double cornerSmoothing;

  /// Whether to show a border around the skeleton
  final bool showBorder;

  /// Border width when showBorder is true
  final double borderWidth;

  const ProfileAvatarSkeleton({
    super.key,
    required this.size,
    required this.colors,
    this.cornerRadius,
    this.cornerSmoothing = 1.0,
    this.showBorder = true,
    this.borderWidth = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = colors.primaryBackground == const Color(0xFF111111);
    final effectiveCornerRadius = cornerRadius ?? (size / 2);

    return Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        color: colors.cardBackground,
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: effectiveCornerRadius,
            cornerSmoothing: cornerSmoothing,
          ),
          side: showBorder
              ? BorderSide(
                  color: colors.primaryBorder,
                  width: borderWidth,
                )
              : BorderSide.none,
        ),
      ),
      child: ClipSmoothRect(
        radius: SmoothBorderRadius(
          cornerRadius: effectiveCornerRadius,
          cornerSmoothing: cornerSmoothing,
        ),
        child: SkeletonTheme(
          shimmerGradient: isDarkMode
              ? const LinearGradient(
                  colors: [
                    Color(0xFF222222),
                    Color(0xFF242424),
                    Color(0xFF2B2B2B),
                    Color(0xFF242424),
                    Color(0xFF222222),
                  ],
                  stops: [0.0, 0.2, 0.5, 0.8, 1],
                  begin: Alignment(-2.4, -0.2),
                  end: Alignment(2.4, 0.2),
                  tileMode: TileMode.clamp,
                )
              : const LinearGradient(
                  colors: [
                    Color(0xFFF0F0F0), // Light neutral gray
                    Color(0xFFE8E8E8), // Medium neutral gray
                    Color(0xFFF0F0F0), // Light neutral gray
                  ],
                  stops: [0.1, 0.5, 0.9],
                  begin: Alignment(-1.0, -0.3),
                  end: Alignment(1.0, 0.3),
                  tileMode: TileMode.clamp,
                ),
          darkShimmerGradient: const LinearGradient(
            colors: [
              Color(0xFF222222),
              Color(0xFF242424),
              Color(0xFF2B2B2B),
              Color(0xFF242424),
              Color(0xFF222222),
            ],
            stops: [0.0, 0.2, 0.5, 0.8, 1],
            begin: Alignment(-2.4, -0.2),
            end: Alignment(2.4, 0.2),
            tileMode: TileMode.clamp,
          ),
          child: SkeletonItem(
            child: SkeletonAvatar(
              style: SkeletonAvatarStyle(
                width: size,
                height: size,
                borderRadius: BorderRadius.circular(effectiveCornerRadius),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
