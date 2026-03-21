import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter_shared_core/theme/providers/theme_provider.dart';

class FloatingPromptField extends ConsumerStatefulWidget {
  final String placeholder;
  final Function(String)? onSubmitted;

  const FloatingPromptField({
    super.key,
    this.placeholder = 'Ask MeetBase about your notes...',
    this.onSubmitted,
  });

  @override
  ConsumerState<FloatingPromptField> createState() => _FloatingPromptFieldState();
}

class _FloatingPromptFieldState extends ConsumerState<FloatingPromptField> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  
  bool _isSending = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    // Call onSubmitted callback
    widget.onSubmitted?.call(message);

    // Clear the field
    _messageController.clear();
    
    setState(() {
      _isSending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(themeColorsProvider);
    
    // The floating widget IS the text field itself with integrated send button
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 56, // Standard iOS text field height
      child: ClipSmoothRect(
        radius: SmoothBorderRadius(
          cornerRadius: 16, // Reduced corner radius for less pill-like appearance
          cornerSmoothing: 1,
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: ShapeDecoration(
              color: colors.cardBackground.withAlpha((0.9 * 255).round()), // More opaque
              shape: SmoothRectangleBorder(
                borderRadius: SmoothBorderRadius(
                  cornerRadius: 16,
                  cornerSmoothing: 1,
                ),
                side: BorderSide(
                  color: colors.secondaryBorder.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              shadows: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                // Chat icon on the left
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  child: SvgPicture.asset(
                    'assets/icons/chat_RoundedEmpty_colored.svg',
                    width: 24,
                    height: 24,
                  ),
                ),
                
                // Text input - fills the floating container
                Expanded(
                  child: CupertinoTextField(
                    controller: _messageController,
                    focusNode: _messageFocusNode,
                    placeholder: widget.placeholder,
                    placeholderStyle: GoogleFonts.inter(
                      fontSize: 16,
                      color: colors.secondaryText,
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: colors.primaryText,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                      border: null, // Remove any default border
                    ),
                    padding: const EdgeInsets.only(
                      left: 0, // Reduced since we now have the icon
                      right: 8,
                      top: 16,
                      bottom: 16,
                    ),
                    maxLines: 1,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    enabled: !_isSending,
                  ),
                ),

                // Integrated send button - ChatGPT style
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: (_isSending || !_hasText) ? null : _sendMessage,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: ShapeDecoration(
                        color: _isSending
                            ? const Color(0xFFE5E5E7) // iOS light gray (disabled)
                            : _hasText
                                ? colors.primaryText
                                : const Color(0xFFE5E5E7), // iOS light gray (empty state)
                        shape: const CircleBorder(),
                      ),
                      child: Center(
                        child: Transform.rotate(
                          angle: math.pi / 2, // 90 degrees to point up
                          child: SvgPicture.asset(
                            'assets/icons/arrow_Rounded_fill.svg',
                            width: 24, // Larger icon
                            height: 24,
                            colorFilter: ColorFilter.mode(
                              _isSending
                                  ? const Color(0xFF8E8E93) // iOS secondary gray for disabled
                                  : _hasText
                                      ? colors.primaryBackground
                                      : const Color(0xFF8E8E93), // iOS secondary gray for empty state
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}