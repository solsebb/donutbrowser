import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SaveToGalleryButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isPrimary;

  const SaveToGalleryButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: ShapeDecoration(
        color: isPrimary ? CupertinoColors.systemBlue : const Color(0xFF2C2C2E),
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: 16,
            cornerSmoothing: 1,
          ),
          side: BorderSide(
            color: CupertinoColors.systemGrey4.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 14),
        onPressed: isLoading ? null : onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.arrow_down_circle,
              color: CupertinoColors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            if (isLoading)
              const CupertinoActivityIndicator()
            else
              Text(
                'Save to Gallery',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.white,
                  letterSpacing: -0.5,
                ),
              ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
          duration: const Duration(milliseconds: 200),
        )
        .slideY(
          begin: 0.2,
          curve: Curves.easeOutQuad,
        );
  }
}
