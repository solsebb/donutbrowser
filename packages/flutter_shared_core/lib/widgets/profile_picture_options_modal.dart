import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter_shared_core/theme/providers/theme_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Shared modal for profile picture options
/// Displays options to take photo (mobile only), choose from library, or remove picture
/// Matches the publish_share_modal design pattern for consistency
class ProfilePictureOptionsModal extends ConsumerWidget {
  final bool showRemoveOption;

  const ProfilePictureOptionsModal({
    super.key,
    this.showRemoveOption = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeColorsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Take Photo button (mobile only - hidden on desktop)
        if (!kIsWeb) ...[
          _buildOptionButton(
            context: context,
            colors: colors,
            icon: 'assets/icons/camera_RoundedFill.svg',
            label: 'Camera',
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop('camera');
            },
          ),
          const SizedBox(height: 12),
        ],

        // Choose from Library button
        _buildOptionButton(
          context: context,
          colors: colors,
          icon: 'assets/icons/photo_RoundedFill.svg',
          label: 'Gallery',
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop('gallery');
          },
        ),

        // Remove Picture button (conditional)
        if (showRemoveOption) ...[
          const SizedBox(height: 12),
          _buildOptionButton(
            context: context,
            colors: colors,
            icon: 'assets/icons/delete_Rounded_empty.svg',
            label: 'Delete',
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop('remove');
            },
            isDestructive: true,
          ),
        ],
      ],
    );
  }

  /// Build option button matching publish_share_modal style
  Widget _buildOptionButton({
    required BuildContext context,
    required dynamic colors,
    required String icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: ShapeDecoration(
          color: isDestructive
              ? colors.warning.withValues(alpha: 0.1) // Light red background for destructive
              : colors.primaryText, // Black (light) / White (dark)
          shape: SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius(
              cornerRadius: 16,
              cornerSmoothing: 1,
            ),
          ),
        ),
        child: Stack(
          children: [
            // Centered label text
            Center(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: isDestructive
                      ? colors.warning // Red for destructive
                      : colors.primaryBackground, // White (light) / Black (dark)
                  letterSpacing: -0.5,
                ),
              ),
            ),
            // Icon positioned on the left
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: SvgPicture.asset(
                  icon,
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(
                    isDestructive
                        ? colors.warning // Red for destructive
                        : colors.primaryBackground, // White (light) / Black (dark)
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
