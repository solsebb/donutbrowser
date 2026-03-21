import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_shared_core/theme/providers/theme_provider.dart';
import 'bottom_app_modal.dart';

/// Modal for inputting optional title when creating a new Email Signup block
/// Provides a clean, focused UX for entering the title before block creation
class EmailSignupInputModal extends ConsumerStatefulWidget {
  final Function(String? title)? onTitleSubmitted;

  const EmailSignupInputModal({
    super.key,
    this.onTitleSubmitted,
  });

  /// Show the email signup input modal
  static Future<String?> show({
    required BuildContext context,
    Function(String? title)? onTitleSubmitted,
  }) async {
    return await showBottomAppModal<String>(
      context: context,
      centerModal: true,
      title: 'Add Email Signup',
      subtitle: 'Add an optional title for your email form',
      content: EmailSignupInputModal(
        onTitleSubmitted: onTitleSubmitted,
      ),
      showCloseButton: true,
    );
  }

  @override
  ConsumerState<EmailSignupInputModal> createState() => _EmailSignupInputModalState();
}

class _EmailSignupInputModalState extends ConsumerState<EmailSignupInputModal> {
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _titleController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final title = _titleController.text.trim();
    if (widget.onTitleSubmitted != null) {
      widget.onTitleSubmitted!(title);
    }
    // Return the actual string (even if empty "") to distinguish from cancellation (null)
    // Empty string means "user clicked Add with no title" (valid, title is optional)
    // Null means "user cancelled/closed modal" (no block should be created)
    Navigator.of(context).pop(title);
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(themeColorsProvider);

    return Container(
      constraints: const BoxConstraints(
        maxWidth: 500, // Reasonable width for title input
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title Input Field
          Container(
            decoration: BoxDecoration(
              color: colors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colors.primaryBorder.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: CupertinoTextField(
              controller: _titleController,
              placeholder: 'e.g., Join my newsletter',
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
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _handleSubmit(),
            ),
          ),

          const SizedBox(height: 8),

          // Helper text
          Text(
            'The title is optional. Leave blank to use the default text.',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: colors.tertiaryText,
              letterSpacing: -0.08,
            ),
          ),

          const SizedBox(height: 16),

          // Add Button (always enabled since title is optional)
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _handleSubmit,
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: colors.primaryText,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Text(
                  'Add',
                  style: GoogleFonts.inter(
                    color: colors.primaryBackground,
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
