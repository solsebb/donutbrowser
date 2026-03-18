import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_shared_core/theme/models/app_theme.dart';
import 'package:flutter_shared_core/theme/providers/theme_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twitterbrowser_flutter/features/auth/data/providers/auth_providers.dart';

class AuthenticationModalContent extends ConsumerStatefulWidget {
  const AuthenticationModalContent({
    super.key,
    this.autoNavigateOnAuthState = true,
    this.onError,
    this.onLoadingChanged,
  });

  final bool autoNavigateOnAuthState;
  final ValueChanged<String>? onError;
  final ValueChanged<bool>? onLoadingChanged;

  @override
  ConsumerState<AuthenticationModalContent> createState() =>
      _AuthenticationModalContentState();
}

class _AuthenticationModalContentState
    extends ConsumerState<AuthenticationModalContent> {
  bool _isLoading = false;

  String _normalizeError(Object error) {
    return error
        .toString()
        .replaceFirst('AuthException(message: ', '')
        .replaceFirst('Exception: ', '')
        .replaceAll(')', '')
        .trim();
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    widget.onLoadingChanged?.call(true);

    try {
      await ref.read(hostedAuthServiceProvider).signInWithGoogle();
    } catch (error) {
      widget.onError?.call(_normalizeError(error));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      widget.onLoadingChanged?.call(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(themeColorsProvider);
    final isDarkMode = colors == AppThemeColors.dark;

    final googleButton = CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: _isLoading ? null : _signInWithGoogle,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color:
              isDarkMode
                  ? CupertinoColors.white.withValues(alpha: 0.1)
                  : CupertinoColors.black.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/logos/Google__G__logo.svg',
              width: 16,
              height: 16,
            ),
            const SizedBox(width: 8),
            Text(
              _isLoading ? 'Connecting…' : 'Continue with Google',
              style: GoogleFonts.inter(
                color: colors.primaryText,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );

    if (kIsWeb) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [googleButton],
      );
    }

    return Row(children: [Expanded(child: googleButton)]);
  }
}
