import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_shared_core/theme/providers/theme_provider.dart';
import 'bottom_app_modal.dart';

/// Modal for inputting email address when creating a new Email Button block
/// Provides a clean, focused UX for entering the email before block creation
class EmailButtonInputModal extends ConsumerStatefulWidget {
  final Function(String email)? onEmailSubmitted;

  const EmailButtonInputModal({
    super.key,
    this.onEmailSubmitted,
  });

  /// Show the email button input modal
  static Future<String?> show({
    required BuildContext context,
    Function(String email)? onEmailSubmitted,
  }) async {
    return await showBottomAppModal<String>(
      context: context,
      centerModal: true,
      title: 'Add Email Button',
      subtitle: 'Enter the email address to contact',
      content: EmailButtonInputModal(
        onEmailSubmitted: onEmailSubmitted,
      ),
      showCloseButton: true,
    );
  }

  @override
  ConsumerState<EmailButtonInputModal> createState() => _EmailButtonInputModalState();
}

class _EmailButtonInputModalState extends ConsumerState<EmailButtonInputModal> {
  late TextEditingController _emailController;
  bool _isValid = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _emailController.addListener(_validateEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _validateEmail() {
    final email = _emailController.text.trim();
    setState(() {
      if (email.isEmpty) {
        _isValid = false;
        _errorMessage = null;
      } else if (!_isValidEmail(email)) {
        _isValid = false;
        _errorMessage = 'Please enter a valid email address';
      } else {
        _isValid = true;
        _errorMessage = null;
      }
    });
  }

  bool _isValidEmail(String email) {
    // Use the same email validation pattern as used in auth_service.dart
    // This ensures consistency across the entire codebase
    if (email.isEmpty) return false;

    // Standard email regex pattern matching codebase convention
    final emailPattern = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    return emailPattern.hasMatch(email);
  }

  void _handleSubmit() {
    if (_isValid) {
      final email = _emailController.text.trim();
      if (widget.onEmailSubmitted != null) {
        widget.onEmailSubmitted!(email);
      }
      Navigator.of(context).pop(email);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(themeColorsProvider);

    return Container(
      constraints: const BoxConstraints(
        maxWidth: 500, // Reasonable width for email input
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email Input Field
          Container(
            decoration: BoxDecoration(
              color: colors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _errorMessage != null
                    ? CupertinoColors.systemRed.withValues(alpha: 0.5)
                    : colors.primaryBorder.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: CupertinoTextField(
              controller: _emailController,
              placeholder: 'hello@example.com',
              placeholderStyle: GoogleFonts.inter(
                color: colors.tertiaryText,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              style: GoogleFonts.inter(
                color: colors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(),
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              onSubmitted: (_) => _handleSubmit(),
            ),
          ),

          // Error Message
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: GoogleFonts.inter(
                color: CupertinoColors.systemRed,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Add Button
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _isValid ? _handleSubmit : null,
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: _isValid
                    ? colors.primaryText
                    : colors.cardBackground.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(24),
                border: _isValid
                    ? null
                    : Border.all(
                        color: colors.primaryBorder,
                        width: 1,
                      ),
              ),
              child: Center(
                child: Text(
                  'Add',
                  style: GoogleFonts.inter(
                    color: _isValid
                        ? colors.primaryBackground
                        : colors.primaryText.withValues(alpha: 0.5),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
