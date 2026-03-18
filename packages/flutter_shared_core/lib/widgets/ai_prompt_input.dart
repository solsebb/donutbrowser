import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:figma_squircle/figma_squircle.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A shared AI prompt input widget that provides consistent styling and behavior
/// across different AI features (Background, Videos, etc.)
/// Now with responsive height that grows with content up to a reasonable limit
class AiPromptInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String labelText;
  final String placeholderText;
  final String? placeholderGeneratingText;
  final VoidCallback? onGenerate;
  final bool isGenerating;
  final bool isDescribing;
  final bool enabled;
  final int maxLength;
  final String? generatingText;

  const AiPromptInput({
    super.key,
    required this.controller,
    this.focusNode,
    required this.labelText,
    required this.placeholderText,
    this.placeholderGeneratingText,
    this.onGenerate,
    this.isGenerating = false,
    this.isDescribing = false,
    this.enabled = true,
    this.maxLength = 200,
    this.generatingText,
  });

  @override
  State<AiPromptInput> createState() => _AiPromptInputState();
}

class _AiPromptInputState extends State<AiPromptInput> {
  // Increased minimum height to accommodate multiline placeholder text
  static const double _minHeight =
      80.0; // Increased from 56 to 80 for better placeholder display
  static const double _maxHeight =
      240.0; // Slightly increased max for better user experience

  // Calculate dynamic height based on both placeholder and actual text content
  double _calculateDynamicHeight() {
    // Get the text to measure - either actual text or placeholder
    final String textToMeasure;
    if (widget.controller.text.isNotEmpty) {
      textToMeasure = widget.controller.text;
    } else {
      // Use placeholder text for height calculation when field is empty
      textToMeasure =
          widget.isDescribing && widget.placeholderGeneratingText != null
              ? widget.placeholderGeneratingText!
              : widget.placeholderText;
    }

    // Create a TextPainter to measure text height
    final textPainter = TextPainter(
      text: TextSpan(
        text: textToMeasure,
        style: GoogleFonts.inter(
          fontSize: 17,
          height: 1.4, // Consistent line height
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: null, // Allow unlimited lines for measurement
    );

    // Get the available width (accounting for padding, button, and spacing)
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth -
        32 -
        16 -
        12 -
        48; // Container padding + internal padding + spacing + button

    textPainter.layout(maxWidth: availableWidth);

    // Calculate height based on text height + adequate padding
    final textHeight = textPainter.height;
    final showCharacterCount =
        widget.controller.text.isNotEmpty || widget.isDescribing;

    // Account for top/bottom padding and character count space when visible
    final totalHeight = textHeight +
        16 +
        (showCharacterCount
            ? 32
            : 16); // Top padding + bottom padding/character count space

    // Constrain between min and max heights
    return totalHeight.clamp(_minHeight, _maxHeight);
  }

  @override
  void initState() {
    super.initState();
    // Listen to text changes to trigger height recalculation
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    // Trigger rebuild when text changes to recalculate height
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show character count when there's text or when describing
    final showCharacterCount =
        widget.controller.text.isNotEmpty || widget.isDescribing;

    // Calculate dynamic height based on content (now includes placeholder text)
    final dynamicHeight = _calculateDynamicHeight();

    return Container(
      decoration: ShapeDecoration(
        color: const Color(0xFF171717).withAlpha(61), // ~24% opacity black
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: 16,
            cornerSmoothing: 1,
          ),
          side: BorderSide(
            color: const Color(0xFFF3F5F7).withAlpha(38), // ~15% opacity white
            width: 0.48,
          ),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label with loading indicator
          Row(
            children: [
              Text(
                widget.labelText,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: CupertinoColors.systemGrey,
                  letterSpacing: -0.3,
                ),
              ),
              if (widget.isDescribing) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CupertinoActivityIndicator(
                    radius: 6,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
                if (widget.generatingText != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    widget.generatingText!,
                    style: GoogleFonts.inter(
                      color: CupertinoColors.systemGrey,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ],
          ),
          const SizedBox(height: 8),

          // Text field with generate button
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Text input field with dynamic height
              Expanded(
                child: Stack(
                  children: [
                    // AnimatedContainer for smooth height transitions
                    AnimatedContainer(
                      duration: const Duration(
                          milliseconds:
                              200), // Slightly longer for smoother transitions
                      curve: Curves.easeInOutCubic, // More sophisticated easing
                      height: dynamicHeight,
                      child: CupertinoTextField(
                        controller: widget.controller,
                        focusNode: widget.focusNode,
                        placeholder: widget.isDescribing &&
                                widget.placeholderGeneratingText != null
                            ? widget.placeholderGeneratingText!
                            : widget.placeholderText,
                        placeholderStyle: GoogleFonts.inter(
                          color: CupertinoColors.systemGrey,
                          fontSize: 17,
                          height: 1.4, // Consistent line height for placeholder
                        ),
                        style: GoogleFonts.inter(
                          color: CupertinoColors.white,
                          fontSize: 17,
                          height: 1.4, // Consistent line height for actual text
                          fontWeight: FontWeight
                              .w400, // Slightly bolder for better visibility
                        ),
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                        ),
                        // Improved padding for better text visibility
                        padding: EdgeInsets.fromLTRB(
                            0, 12, 0, showCharacterCount ? 36 : 12),
                        maxLines:
                            null, // Allow unlimited lines within height constraint
                        minLines: 1,
                        textInputAction: TextInputAction.newline,
                        enabled: !widget.isDescribing &&
                            !widget.isGenerating &&
                            widget.enabled,
                        textCapitalization: TextCapitalization.sentences,
                        keyboardType: TextInputType.multiline,
                        onChanged: (value) {
                          if (value.length > widget.maxLength) {
                            widget.controller.text =
                                value.substring(0, widget.maxLength);
                            widget.controller.selection =
                                TextSelection.fromPosition(
                              TextPosition(offset: widget.maxLength),
                            );
                          }
                        },
                      ),
                    ),

                    // Character count positioned inside text field with improved styling
                    if (showCharacterCount)
                      Positioned(
                        right: 0,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: ShapeDecoration(
                            color: const Color(0xFF1C1C1E).withAlpha(
                                204), // More opaque for better visibility
                            shape: SmoothRectangleBorder(
                              borderRadius: SmoothBorderRadius(
                                cornerRadius: 10, // Slightly larger radius
                                cornerSmoothing: 1.0,
                              ),
                            ),
                          ),
                          child: Text(
                            '${widget.controller.text.length}/${widget.maxLength}',
                            style: GoogleFonts.inter(
                              color: widget.controller.text.length ==
                                      widget.maxLength
                                  ? CupertinoColors.systemOrange
                                  : CupertinoColors.systemGrey,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Generate button
              CupertinoButton(
                padding: const EdgeInsets.all(10),
                onPressed: (widget.controller.text.trim().isEmpty ||
                        widget.isGenerating ||
                        !widget.enabled ||
                        widget.onGenerate == null)
                    ? null
                    : widget.onGenerate,
                color: (widget.controller.text.trim().isEmpty ||
                        widget.isGenerating ||
                        !widget.enabled ||
                        widget.onGenerate == null)
                    ? CupertinoColors.systemGrey2.withValues(alpha: 0.5)
                    : const Color(0xFF918DF6),
                borderRadius: BorderRadius.circular(30),
                child: widget.isGenerating
                    ? const CupertinoActivityIndicator(
                        radius: 10,
                        color: CupertinoColors.white,
                      )
                    : SvgPicture.asset(
                        'assets/icons/arrow_upward_alt_RoundedFill.svg',
                        colorFilter: const ColorFilter.mode(
                            CupertinoColors.white, BlendMode.srcIn),
                        width: 28,
                        height: 28,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
