import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_shared_core/theme/providers/theme_provider.dart';
import 'bottom_app_modal.dart';

/// Modal for inputting URL when creating a new URL block
/// Provides a clean, focused UX for entering the URL before block creation
class UrlInputModal extends ConsumerStatefulWidget {
  final Function(String url)? onUrlSubmitted;

  const UrlInputModal({
    super.key,
    this.onUrlSubmitted,
  });

  /// Show the URL input modal
  static Future<String?> show({
    required BuildContext context,
    Function(String url)? onUrlSubmitted,
  }) async {
    return await showBottomAppModal<String>(
      context: context,
      centerModal: true,
      title: 'Add URL',
      subtitle: 'Enter the link you want to share',
      content: UrlInputModal(
        onUrlSubmitted: onUrlSubmitted,
      ),
      showCloseButton: true,
    );
  }

  @override
  ConsumerState<UrlInputModal> createState() => _UrlInputModalState();
}

class _UrlInputModalState extends ConsumerState<UrlInputModal> {
  late TextEditingController _urlController;
  bool _isValid = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    _urlController.addListener(_validateUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _validateUrl() {
    final url = _urlController.text.trim();
    setState(() {
      if (url.isEmpty) {
        _isValid = false;
        _errorMessage = null;
      } else if (!_isValidUrl(url)) {
        _isValid = false;
        _errorMessage = 'Please enter a valid URL';
      } else {
        _isValid = true;
        _errorMessage = null;
      }
    });
  }

  bool _isValidUrl(String url) {
    // Use Dart's Uri parser for robust URL validation
    // This properly handles query parameters, special characters, etc.
    if (url.isEmpty) return false;

    try {
      // First, ensure URL has a scheme for parsing
      final urlWithScheme = url.startsWith('http://') || url.startsWith('https://')
          ? url
          : 'https://$url';

      final uri = Uri.parse(urlWithScheme);

      // For web URLs, ensure it has scheme and authority (domain)
      return uri.hasScheme && uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }

  String _ensureHttps(String url) {
    // Ensure URL starts with https:// if no protocol specified
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return 'https://$url';
    }
    return url;
  }

  void _handleSubmit() {
    if (_isValid) {
      final url = _ensureHttps(_urlController.text.trim());
      if (widget.onUrlSubmitted != null) {
        widget.onUrlSubmitted!(url);
      }
      Navigator.of(context).pop(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(themeColorsProvider);
    final isLightMode = colors.primaryBackground == const Color(0xFFFFFFFF) ||
        colors.primaryBackground == CupertinoColors.white;

    return Container(
      constraints: const BoxConstraints(
        maxWidth: 500, // Reasonable width for URL input
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // URL Input Field
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
              controller: _urlController,
              placeholder: 'https://example.com',
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
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
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
