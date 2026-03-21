import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Function()? onPressed;
  final bool isLoading;
  final bool isPrimary;

  const ActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        color: const Color(0xFF2C2C2E),
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: 12,
            cornerSmoothing: 1,
          ),
          side: BorderSide(
            color: CupertinoColors.systemGrey4.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 12),
        onPressed: isLoading ? null : onPressed,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isPrimary
                  ? CupertinoColors.systemBlue
                  : CupertinoColors.white,
              size: 24,
            ),
            const SizedBox(height: 6),
            if (isLoading)
              const CupertinoActivityIndicator()
            else
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: CupertinoColors.white,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
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
