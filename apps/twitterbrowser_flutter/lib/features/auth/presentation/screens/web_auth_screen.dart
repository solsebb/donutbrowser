import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_shared_core/config/brand_config.dart'
    show brandConfigProvider, brandTestimonialProvider;
import 'package:flutter_shared_core/theme/models/app_theme.dart';
import 'package:flutter_shared_core/theme/providers/theme_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twitterbrowser_flutter/features/auth/data/providers/auth_providers.dart';
import 'package:twitterbrowser_flutter/features/auth/presentation/screens/web_email_otp_verification_screen.dart';
import 'package:twitterbrowser_flutter/features/auth/presentation/widgets/authentication_modal_content.dart';
import 'package:twitterbrowser_flutter/features/auth/presentation/widgets/web_language_selector.dart';
import 'package:twitterbrowser_flutter/features/auth/presentation/widgets/web_theme_selector.dart';
import 'package:twitterbrowser_flutter/shared/widgets/brand_logo.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WebAuthScreen extends ConsumerStatefulWidget {
  const WebAuthScreen({super.key, this.isSignUp = false});

  final bool isSignUp;

  @override
  ConsumerState<WebAuthScreen> createState() => _WebAuthScreenState();
}

class _WebAuthScreenState extends ConsumerState<WebAuthScreen> {
  static final RegExp _emailRegex = RegExp(r'^[\w\-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isResolvingAuthRedirect = false;
  bool _hasRedirected = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAuthAndRedirect());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndRedirect() async {
    if (!mounted || _hasRedirected) {
      return;
    }

    final sourceMode = ref.read(profileSourceModeProvider);
    if (!kIsWeb && sourceMode == ProfileSourceMode.local) {
      _hasRedirected = true;
      context.go('/app/profiles');
      return;
    }

    final session = ref.read(authSessionProvider).valueOrNull;
    if (sourceMode == ProfileSourceMode.hosted && session != null) {
      _hasRedirected = true;
      setState(() => _isResolvingAuthRedirect = true);
      if (mounted) {
        context.go('/app/profiles');
      }
    }
  }

  Future<void> _launchExternalUrl(String urlString) async {
    if (urlString.isEmpty) {
      return;
    }

    final uri = Uri.parse(urlString);
    if (kIsWeb) {
      await launchUrl(uri, webOnlyWindowName: '_self');
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _normalizeError(Object error) {
    return error
        .toString()
        .replaceFirst('AuthException(message: ', '')
        .replaceFirst('Exception: ', '')
        .replaceFirst('Bad state: ', '')
        .replaceAll(')', '')
        .trim();
  }

  bool _validateEmail() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Enter your email address.';
        _successMessage = null;
      });
      return false;
    }

    if (!_emailRegex.hasMatch(email)) {
      setState(() {
        _errorMessage = 'Use a valid email address.';
        _successMessage = null;
      });
      return false;
    }
    return true;
  }

  Future<void> _handleEmailAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (!_validateEmail()) {
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _errorMessage =
            widget.isSignUp
                ? 'Create a password to continue.'
                : 'Enter your password to continue.';
        _successMessage = null;
      });
      return;
    }

    if (widget.isSignUp && password.length < 8) {
      setState(() {
        _errorMessage = 'Use at least 8 characters for your password.';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final service = ref.read(hostedAuthServiceProvider);
      if (widget.isSignUp) {
        await service.signUpWithPassword(email: email, password: password);
        if (!mounted) {
          return;
        }
        await Navigator.of(context).push(
          CupertinoPageRoute(
            builder:
                (_) => WebEmailOtpVerificationScreen(
                  email: email,
                  password: password,
                  mode: WebEmailOtpMode.signup,
                ),
          ),
        );
        if (mounted) {
          context.go('/app/profiles');
        }
        return;
      }

      await service.signInWithPassword(email: email, password: password);
      if (mounted) {
        context.go('/app/profiles');
      }
    } catch (error) {
      setState(() {
        _errorMessage = _normalizeError(error);
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showForgotPasswordPrompt() async {
    if (_isLoading || widget.isSignUp) {
      return;
    }

    final colors = ref.read(themeColorsProvider);
    final emailController = TextEditingController(
      text: _emailController.text.trim(),
    );

    try {
      final email = await showCupertinoDialog<String>(
        context: context,
        builder:
            (dialogContext) => CupertinoAlertDialog(
              title: const Text('Reset password'),
              content: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: CupertinoTextField(
                  controller: emailController,
                  placeholder: 'Enter your email',
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.inter(
                    color: colors.primaryText,
                    fontSize: 14,
                  ),
                  placeholderStyle: GoogleFonts.inter(
                    color: colors.placeholderText,
                    fontSize: 14,
                  ),
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () {
                    Navigator.of(dialogContext).pop(emailController.text.trim());
                  },
                  child: const Text('Send link'),
                ),
              ],
            ),
      );

      if (email == null || email.trim().isEmpty) {
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _successMessage = null;
      });

      await ref.read(hostedAuthServiceProvider).sendPasswordResetEmail(
            email: email.trim(),
            redirectTo: kIsWeb ? Uri.base.origin : null,
          );

      if (mounted) {
        setState(() {
          _successMessage = 'Password reset instructions have been sent.';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = _normalizeError(error);
        });
      }
    } finally {
      emailController.dispose();
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        child: Row(
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed:
                  () => _launchExternalUrl(
                    ref.read(brandConfigProvider).websiteUrl,
                  ),
              child: const BrandLogo(height: 24),
            ),
            const SizedBox(width: 16),
            const WebLanguageSelector(),
            const SizedBox(width: 8),
            const WebThemeSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String placeholder,
    required AppThemeColors colors,
    required bool isDarkMode,
    required TextInputType keyboardType,
    required TextInputAction textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    return Focus(
      onFocusChange: (_) => setState(() {}),
      child: Builder(
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;
          return Container(
            height: 40,
            decoration: BoxDecoration(
              color:
                  isDarkMode
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border:
                  hasFocus
                      ? Border.all(color: const Color(0xFF918DF6), width: 2)
                      : null,
            ),
            child: CupertinoTextField.borderless(
              controller: controller,
              focusNode: focusNode,
              placeholder: placeholder,
              placeholderStyle: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.tertiaryText,
              ),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.primaryText,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(color: Colors.transparent),
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              enabled: !_isLoading,
              onSubmitted: onSubmitted,
            ),
          );
        },
      ),
    );
  }

  Widget _buildPasswordField({
    required AppThemeColors colors,
    required bool isDarkMode,
  }) {
    return Focus(
      onFocusChange: (_) => setState(() {}),
      child: Builder(
        builder: (context) {
          final hasFocus = Focus.of(context).hasFocus;
          return Container(
            height: 40,
            decoration: BoxDecoration(
              color:
                  isDarkMode
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border:
                  hasFocus
                      ? Border.all(color: const Color(0xFF918DF6), width: 2)
                      : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: CupertinoTextField.borderless(
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    placeholder: 'Password',
                    placeholderStyle: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colors.tertiaryText,
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colors.primaryText,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: const BoxDecoration(color: Colors.transparent),
                    obscureText: !_isPasswordVisible,
                    textInputAction: TextInputAction.done,
                    enabled: !_isLoading,
                    onSubmitted: (_) => _handleEmailAuth(),
                  ),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.only(right: 12),
                  onPressed:
                      _isLoading
                          ? null
                          : () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                  child: Icon(
                    _isPasswordVisible
                        ? CupertinoIcons.eye_slash
                        : CupertinoIcons.eye,
                    color: colors.tertiaryText,
                    size: 18,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPrimaryActionButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return CupertinoButton(
      onPressed: _isLoading ? null : onPressed,
      padding: EdgeInsets.zero,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF918DF6),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF918DF6).withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child:
              _isLoading
                  ? const CupertinoActivityIndicator(
                    color: CupertinoColors.white,
                  )
                  : Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.white,
                    ),
                  ),
        ),
      ),
    );
  }

  Widget _buildFeedbackMessage(AppThemeColors colors) {
    if (_errorMessage == null && _successMessage == null) {
      return const SizedBox.shrink();
    }

    final hasError = _errorMessage != null;
    final message = _errorMessage ?? _successMessage!;
    final messageColor =
        hasError ? CupertinoColors.systemRed : CupertinoColors.systemGreen;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        message,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: messageColor.resolveFrom(context),
        ),
        textAlign: TextAlign.left,
      ),
    );
  }

  Widget _buildAuthForm({
    required AppThemeColors colors,
    required bool isDarkMode,
    required double maxWidth,
  }) {
    final title = widget.isSignUp ? 'Join TwitterBrowser' : 'Sign In';
    final subtitle =
        widget.isSignUp
            ? 'Create your account in less than 2 minutes !'
            : 'Welcome back! Sign in to your TwitterBrowser account.';
    final brand = ref.watch(brandConfigProvider);

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
          const SizedBox(height: 48),
          _buildTextInputField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            placeholder: 'Email address',
            colors: colors,
            isDarkMode: isDarkMode,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _passwordFocusNode.requestFocus(),
          ),
          const SizedBox(height: 16),
          _buildPasswordField(colors: colors, isDarkMode: isDarkMode),
          if (!widget.isSignUp) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                onPressed: _showForgotPasswordPrompt,
                child: Text(
                  'Forgot your password?',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF918DF6),
                  ),
                ),
              ),
            ),
          ],
          _buildFeedbackMessage(colors),
          const SizedBox(height: 16),
          _buildPrimaryActionButton(
            label: widget.isSignUp ? 'Create Account' : 'Continue with email',
            onPressed: _handleEmailAuth,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  color: colors.primaryBorder.withValues(alpha: 0.2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OR',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colors.tertiaryText,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  color: colors.primaryBorder.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AuthenticationModalContent(
            autoNavigateOnAuthState: false,
            onError: (message) {
              if (!mounted) {
                return;
              }
              setState(() {
                _errorMessage = message;
                _successMessage = null;
              });
            },
            onLoadingChanged: (isLoading) {
              if (!mounted) {
                return;
              }
              setState(() => _isLoading = isLoading);
            },
          ),
          const SizedBox(height: 24),
          Text.rich(
            TextSpan(
              style: GoogleFonts.inter(
                fontSize: 13,
                color: colors.tertiaryText,
                letterSpacing: -0.2,
              ),
              children: [
                const TextSpan(text: 'By continuing, you agree to our '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    onPressed:
                        brand.privacyPolicyUrl.isEmpty
                            ? null
                            : () => _launchExternalUrl(brand.privacyPolicyUrl),
                    child: Text(
                      'Privacy',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: colors.tertiaryText,
                        letterSpacing: -0.2,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                const TextSpan(text: ' and '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    onPressed:
                        brand.termsOfServiceUrl.isEmpty
                            ? null
                            : () => _launchExternalUrl(brand.termsOfServiceUrl),
                    child: Text(
                      'Terms',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: colors.tertiaryText,
                        letterSpacing: -0.2,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                const TextSpan(text: '.'),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.isSignUp ? 'Already have an account?' : 'Not yet a member?',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: colors.secondaryText,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 6),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  context.go(widget.isSignUp ? '/signin' : '/signup');
                },
                child: Text(
                  widget.isSignUp ? 'Login' : 'Sign up',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF918DF6),
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<Session?>>(authSessionProvider, (previous, next) {
      if (_hasRedirected) {
        return;
      }
      final session = next.valueOrNull;
      if (session != null) {
        _checkAuthAndRedirect();
      }
    });

    final colors = ref.watch(themeColorsProvider);
    final isDarkMode = colors == AppThemeColors.dark;

    return CupertinoPageScaffold(
      backgroundColor: colors.primaryBackground,
      child: Stack(
        children: [
          Positioned.fill(
            child:
                kIsWeb
                    ? LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 768;
                        final showTestimonial = constraints.maxWidth >= 1024;

                        return isMobile
                            ? Column(
                              children: [
                                _buildTopBar(),
                                Expanded(
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 48,
                                      vertical: 24,
                                    ),
                                    child: Center(
                                      child: _buildAuthForm(
                                        colors: colors,
                                        isDarkMode: isDarkMode,
                                        maxWidth: 400,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                            : Container(
                              color: colors.primaryBackground,
                              child: Stack(
                                children: [
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    child: _buildTopBar(),
                                  ),
                                  Positioned.fill(
                                    top: 80,
                                    child: Builder(
                                      builder: (context) {
                                        final authFormContent =
                                            SingleChildScrollView(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 48,
                                                    vertical: 24,
                                                  ),
                                              child: _buildAuthForm(
                                                colors: colors,
                                                isDarkMode: isDarkMode,
                                                maxWidth: 400,
                                              ),
                                            );

                                        if (showTestimonial) {
                                          return Row(
                                            children: [
                                              Expanded(
                                                child: Center(
                                                  child: authFormContent,
                                                ),
                                              ),
                                              Expanded(
                                                child: Center(
                                                  child: _FeaturedTestimonial(
                                                    colors: colors,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        }

                                        return Center(child: authFormContent);
                                      },
                                    ),
                                  ),
                                ],
                              ),
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
                              child: _buildAuthForm(
                                colors: colors,
                                isDarkMode: isDarkMode,
                                maxWidth: 360,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
          ),
          if (_isResolvingAuthRedirect)
            Positioned.fill(
              child: ColoredBox(
                color: colors.primaryBackground.withValues(alpha: 0.9),
                child: const Center(
                  child: CupertinoActivityIndicator(radius: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FeaturedTestimonial extends ConsumerWidget {
  const _FeaturedTestimonial({required this.colors});

  final AppThemeColors colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLightTheme = colors.primaryBackground.computeLuminance() > 0.5;
    final testimonial = ref.watch(brandTestimonialProvider('auth'));

    List<TextSpan> buildQuoteSpans() {
      final highlight = testimonial.highlightedPhrase;
      if (highlight.isEmpty) {
        return [TextSpan(text: testimonial.quote)];
      }

      final highlightIndex = testimonial.quote.indexOf(highlight);
      if (highlightIndex == -1) {
        return [TextSpan(text: testimonial.quote)];
      }

      final before = testimonial.quote.substring(0, highlightIndex);
      final after = testimonial.quote.substring(
        highlightIndex + highlight.length,
      );

      return [
        TextSpan(text: before),
        TextSpan(
          text: highlight,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
            color: colors.primaryText,
            height: 1.7,
          ),
        ),
        TextSpan(text: after),
      ];
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: -8,
                left: -48,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CustomPaint(
                    painter: _QuoteIconPainter(
                      color:
                          isLightTheme
                              ? const Color(0xFF000000).withValues(alpha: 0.08)
                              : const Color(0xFFFFFFFF).withValues(alpha: 0.08),
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                        color: colors.primaryText,
                        height: 1.7,
                      ),
                      children: buildQuoteSpans(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isLightTheme
                                    ? const Color(
                                      0xFF000000,
                                    ).withValues(alpha: 0.06)
                                    : const Color(
                                      0xFFFFFFFF,
                                    ).withValues(alpha: 0.06),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            testimonial.avatarAsset,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            testimonial.authorName,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: colors.primaryText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            testimonial.authorTitle,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: colors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuoteIconPainter extends CustomPainter {
  const _QuoteIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    final scale = size.width / 32;

    final path = Path();
    path.moveTo(10 * scale, 8 * scale);
    path.cubicTo(
      6.7 * scale,
      8 * scale,
      4 * scale,
      10.7 * scale,
      4 * scale,
      14 * scale,
    );
    path.lineTo(4 * scale, 24 * scale);
    path.lineTo(14 * scale, 24 * scale);
    path.lineTo(14 * scale, 14 * scale);
    path.lineTo(10 * scale, 14 * scale);
    path.cubicTo(
      10 * scale,
      11.8 * scale,
      11.8 * scale,
      10 * scale,
      14 * scale,
      10 * scale,
    );
    path.lineTo(14 * scale, 8 * scale);
    path.close();

    path.moveTo(26 * scale, 8 * scale);
    path.cubicTo(
      22.7 * scale,
      8 * scale,
      20 * scale,
      10.7 * scale,
      20 * scale,
      14 * scale,
    );
    path.lineTo(20 * scale, 24 * scale);
    path.lineTo(30 * scale, 24 * scale);
    path.lineTo(30 * scale, 14 * scale);
    path.lineTo(26 * scale, 14 * scale);
    path.cubicTo(
      26 * scale,
      11.8 * scale,
      27.8 * scale,
      10 * scale,
      30 * scale,
      10 * scale,
    );
    path.lineTo(30 * scale, 8 * scale);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _QuoteIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
