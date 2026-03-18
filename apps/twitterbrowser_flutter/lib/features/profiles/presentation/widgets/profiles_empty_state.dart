import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twitterbrowser_flutter/shared/widgets/rounded_button.dart';

class ProfilesEmptyState extends StatelessWidget {
  const ProfilesEmptyState({
    super.key,
    required this.colors,
    required this.isLightTheme,
    required this.title,
    required this.description,
    this.buttonLabel,
    this.onPressed,
    this.iconAssetPath,
    this.icon,
  });

  final dynamic colors;
  final bool isLightTheme;
  final String title;
  final String description;
  final String? buttonLabel;
  final VoidCallback? onPressed;
  final String? iconAssetPath;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconAssetPath != null)
              SvgPicture.asset(
                iconAssetPath!,
                width: 56,
                height: 56,
              )
            else
              Icon(
                icon ?? CupertinoIcons.person_2,
                size: 56,
                color: colors.tertiaryText,
              ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colors.primaryText,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.5,
                  color: colors.secondaryText,
                ),
              ),
            ),
            if (buttonLabel != null && onPressed != null) ...[
              const SizedBox(height: 24),
              RoundedButton(
                text: buttonLabel!,
                onPressed: onPressed,
                backgroundColor: colors.primaryText,
                textColor: colors.primaryBackground,
                borderColor: colors.primaryText.withValues(alpha: 0.2),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
