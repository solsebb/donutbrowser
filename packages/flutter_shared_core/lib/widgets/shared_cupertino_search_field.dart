import 'package:flutter/cupertino.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'dart:ui'; // For ImageFilter

class SharedCupertinoSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholderText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextStyle? style;
  final EdgeInsetsGeometry padding;

  const SharedCupertinoSearchField({
    super.key,
    required this.controller,
    this.placeholderText = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.style,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 8),
  });

  @override
  Widget build(BuildContext context) {
    final defaultTextStyle =
        style ?? const TextStyle(color: CupertinoColors.white);

    return Padding(
      padding: padding,
      child: ClipSmoothRect(
        radius: SmoothBorderRadius(
          cornerRadius: 10, // Consistent with CupertinoSearchTextField default
          cornerSmoothing: 1.0,
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: ShapeDecoration(
              color: const Color(0xFF2C2C2E)
                  .withAlpha(76), // Standard dark translucent
              shape: SmoothRectangleBorder(
                borderRadius: SmoothBorderRadius(
                  cornerRadius: 10,
                  cornerSmoothing: 1.0,
                ),
                side: BorderSide(
                  color: CupertinoColors.systemGrey4
                      .withAlpha(51), // Standard border
                  width: 0.5,
                ),
              ),
            ),
            child: CupertinoSearchTextField(
              controller: controller,
              placeholder: placeholderText,
              style: defaultTextStyle,
              itemColor:
                  CupertinoColors.systemGrey, // Color for prefix/suffix icons
              placeholderStyle: defaultTextStyle.copyWith(
                color: CupertinoColors.systemGrey
                    .withAlpha(178), // Lighter grey for placeholder
              ),
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              // The background color of the text field itself should be transparent
              // as the container handles the visual background.
              // This is managed by the default BoxDecoration of CupertinoSearchTextField
              // when backgroundColor is not specified or is transparent.
              // We are relying on the default internal padding and alignment.
            ),
          ),
        ),
      ),
    );
  }
}
