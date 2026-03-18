import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_shared_core/theme/models/app_theme.dart';
import 'package:flutter_shared_core/theme/providers/theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twitterbrowser_flutter/features/auth/data/providers/auth_providers.dart';
import 'package:twitterbrowser_flutter/features/auth/presentation/widgets/web_language_selector.dart';
import 'package:twitterbrowser_flutter/features/auth/presentation/widgets/web_theme_selector.dart';
import 'package:twitterbrowser_flutter/shared/widgets/brand_logo.dart';

enum WebEmailOtpMode { signIn, signup }

class WebEmailOtpVerificationScreen extends ConsumerStatefulWidget {
  const WebEmailOtpVerificationScreen({
    super.key,
    required this.email,
    this.password,
    this.mode = WebEmailOtpMode.signIn,
  });

  final String email;
  final String? password;
  final WebEmailOtpMode mode;

  @override
  ConsumerState<WebEmailOtpVerificationScreen> createState() =>
      _WebEmailOtpVerificationScreenState();
}

class _WebEmailOtpVerificationScreenState
    extends ConsumerState<WebEmailOtpVerificationScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  String _normalizeError(Object error) {
    return error
        .toString()
        .replaceFirst('AuthException(message: ', '')
        .replaceFirst('Exception: ', '')
        .replaceAll(')', '')
        .trim();
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Enter the 6-digit code.');
      return;
    }
    if (code.length != 6) {
      setState(() => _errorMessage = 'Use the 6-digit code from your inbox.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final service = ref.read(hostedAuthServiceProvider);
      if (widget.mode == WebEmailOtpMode.signup) {
        await service.verifySignupOtp(email: widget.email, code: code);
      } else {
        await service.verifyEmailOtp(email: widget.email, code: code);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = _normalizeError(error));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _isResending = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final service = ref.read(hostedAuthServiceProvider);
      if (widget.mode == WebEmailOtpMode.signup) {
        final password = widget.password;
        if (password == null || password.isEmpty) {
          throw StateError('Missing password for signup confirmation.');
        }
        await service.signUpWithPassword(email: widget.email, password: password);
      } else {
        await service.sendEmailOtp(email: widget.email);
      }

      if (mounted) {
        setState(() {
          _successMessage = 'A fresh code was sent to ${widget.email}.';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = _normalizeError(error));
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: const SafeArea(
        child: Row(
          children: [
            BrandLogo(height: 24),
            SizedBox(width: 16),
            WebLanguageSelector(),
            SizedBox(width: 16),
            WebThemeSelector(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(themeColorsProvider);
    final isDarkMode = colors == AppThemeColors.dark;
    final title =
        widget.mode == WebEmailOtpMode.signup
            ? 'Verify your email'
            : 'Check your inbox';
    final subtitle =
        widget.mode == WebEmailOtpMode.signup
            ? 'Enter the 6-digit confirmation code sent to ${widget.email}.'
            : 'Enter the 6-digit sign-in code sent to ${widget.email}.';

    return CupertinoPageScaffold(
      backgroundColor: colors.primaryBackground,
      child:
          kIsWeb
              ? LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 768;
                  return Column(
                    children: [
                      _buildTopBar(),
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 24 : 48,
                              vertical: 24,
                            ),
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 400),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontFamily: 'PlusJakartaSans',
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      height: 1.3,
                                      letterSpacing: -0.3,
                                    ).copyWith(color: colors.primaryText),
                                    textAlign: TextAlign.center,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      subtitle,
                                      style: const TextStyle(
                                        fontFamily: 'PlusJakartaSans',
                                        fontSize: 24,
                                        fontWeight: FontWeight.w400,
                                        height: 1.3,
                                        letterSpacing: -0.3,
                                      ).copyWith(color: colors.secondaryText),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(height: 40),
                                  Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color:
                                          isDarkMode
                                              ? Colors.white.withValues(
                                                alpha: 0.08,
                                              )
                                              : Colors.black.withValues(
                                                alpha: 0.05,
                                              ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: CupertinoTextField.borderless(
                                      controller: _otpController,
                                      keyboardType: TextInputType.number,
                                      placeholder: '6-digit code',
                                      textAlign: TextAlign.center,
                                      maxLength: 6,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: colors.primaryText,
                                      ),
                                      placeholderStyle: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: colors.tertiaryText,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      decoration: const BoxDecoration(
                                        color: Colors.transparent,
                                      ),
                                      onSubmitted: (_) => _verifyOtp(),
                                    ),
                                  ),
                                  if (_errorMessage != null ||
                                      _successMessage != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: Text(
                                        _errorMessage ?? _successMessage!,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color:
                                              _errorMessage != null
                                                  ? CupertinoColors.systemRed
                                                      .resolveFrom(context)
                                                  : CupertinoColors.systemGreen
                                                      .resolveFrom(context),
                                        ),
                                        textAlign: TextAlign.left,
                                      ),
                                    ),
                                  const SizedBox(height: 16),
                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    onPressed: _isLoading ? null : _verifyOtp,
                                    child: Container(
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF918DF6),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF918DF6,
                                            ).withValues(alpha: 0.25),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child:
                                            _isLoading
                                                ? const CupertinoActivityIndicator(
                                                  color:
                                                      CupertinoColors.white,
                                                )
                                                : Text(
                                                  'Verify code',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        CupertinoColors.white,
                                                  ),
                                                ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    onPressed:
                                        _isResending ? null : _resendCode,
                                    child: Container(
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: colors.primaryBorder.withValues(
                                            alpha: 0.24,
                                          ),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _isResending
                                              ? 'Resending…'
                                              : 'Resend code',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: colors.primaryText,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: Text(
                                      'Back',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF918DF6),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              )
              : Column(
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  height: 1.3,
                                  letterSpacing: -0.3,
                                ).copyWith(color: colors.primaryText),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                subtitle,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  height: 1.6,
                                  color: colors.secondaryText,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
