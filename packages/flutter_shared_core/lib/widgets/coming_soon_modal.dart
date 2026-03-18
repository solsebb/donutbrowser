import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'app_modal.dart';

/// Shows a "Coming Soon" modal to inform users about features in development
Future<void> showComingSoonModal(
  BuildContext context, {
  String title = 'Coming Soon',
  String message =
      'This feature is currently in development. Check back soon for updates!',
  String buttonText = 'Got It',
}) async {
  HapticFeedback.lightImpact();

  return showCupertinoModalPopup(
    context: context,
    barrierDismissible: true,
    builder: (context) => GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        color: CupertinoColors.black.withAlpha(102),
        child: GestureDetector(
          // Prevent taps on the modal from closing it
          onTap: () {},
          child: AppModal(
            title: title,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Feature description
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Text(
                    message,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: CupertinoColors.white,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Confirmation button
                AppModalOptionButton(
                  label: buttonText,
                  icon: CupertinoIcons.check_mark,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
