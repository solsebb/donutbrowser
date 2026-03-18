import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_shared_core/theme/providers/theme_provider.dart';
import 'bottom_app_modal.dart';

/// Modal for inputting section title text when creating a new Section Title block
/// Provides a clean, focused UX for entering the title before block creation
class SectionTitleInputModal extends ConsumerStatefulWidget {
  final Function(String title)? onTitleSubmitted;
  static const int maxTitleLength = 280;

  const SectionTitleInputModal({
    super.key,
    this.onTitleSubmitted,
  });

  /// Show the section title input modal
  static Future<String?> show({
    required BuildContext context,
    Function(String title)? onTitleSubmitted,
  }) async {
    return await showBottomAppModal<String>(
      context: context,
      centerModal: true,
      title: 'Add Section Title',
      subtitle: 'Enter a title to organize your content',
      content: SectionTitleInputModal(
        onTitleSubmitted: onTitleSubmitted,
      ),
      showCloseButton: true,
    );
  }

  @override
  ConsumerState<SectionTitleInputModal> createState() => _SectionTitleInputModalState();
}

class _SectionTitleInputModalState extends ConsumerState<SectionTitleInputModal> {
  late TextEditingController _titleController;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _titleController.addListener(_validateTitle);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _validateTitle() {
    final title = _titleController.text.trim();
    setState(() {
      _isValid = title.isNotEmpty;
    });
  }

  void _handleSubmit() {
    if (_isValid) {
      final title = _titleController.text.trim();
      if (widget.onTitleSubmitted != null) {
        widget.onTitleSubmitted!(title);
      }
      Navigator.of(context).pop(title);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(themeColorsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final isLightMode = themeMode.name == 'light' ||
        (themeMode.name == 'system' && brightness == Brightness.light);

    return Container(
      constraints: const BoxConstraints(
        maxWidth: 500, // Reasonable width for title input
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title Input Field with character counter
          Stack(
            children: [
              CupertinoTextField(
                controller: _titleController,
                placeholder: 'e.g., Social Media, Contact Info, Projects',
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
                decoration: BoxDecoration(
                  color: isLightMode
                      ? const Color(0xFFF8F8F8)
                      : colors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: isLightMode
                      ? null
                      : Border.all(
                          color: colors.primaryBorder,
                          width: 0.5,
                        ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 36),
                minLines: 3,
                maxLines: null, // Unlimited lines - field expands to show all text
                autofocus: true,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                textCapitalization: TextCapitalization.words,
                onChanged: (value) {
                  if (value.length > SectionTitleInputModal.maxTitleLength) {
                    const maxLength = SectionTitleInputModal.maxTitleLength;
                    _titleController.text = value.substring(0, maxLength);
                    _titleController.selection = TextSelection.fromPosition(
                      const TextPosition(offset: maxLength),
                    );
                  }
                  setState(() {});
                },
              ),
              // Character counter
              if (_titleController.text.isNotEmpty)
                Positioned(
                  right: 16,
                  bottom: 10,
                  child: Text(
                    '${_titleController.text.length}/${SectionTitleInputModal.maxTitleLength}',
                    style: GoogleFonts.inter(
                      color: _titleController.text.length == SectionTitleInputModal.maxTitleLength
                          ? colors.warning
                          : colors.secondaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
            ],
          ),

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
