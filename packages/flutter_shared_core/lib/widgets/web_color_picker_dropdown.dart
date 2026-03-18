import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Material, showDialog, Dialog;
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'dart:ui';

/// Reusable color picker dropdown widget for web
/// Provides consistent color picker functionality across the app
class WebColorPickerDropdown extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorChanged;
  final VoidCallback onCancel;
  final dynamic colors; // Theme colors
  final String? title;

  const WebColorPickerDropdown({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
    required this.onCancel,
    required this.colors,
    this.title,
  });

  @override
  State<WebColorPickerDropdown> createState() => _WebColorPickerDropdownState();
}

class _WebColorPickerDropdownState extends State<WebColorPickerDropdown> {
  late Color _selectedColor;
  late TextEditingController _hexController;
  late FocusNode _hexFocusNode;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
    _hexController = TextEditingController(
      text: _selectedColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()
    );
    _hexFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _hexController.dispose();
    _hexFocusNode.dispose();
    super.dispose();
  }

  void _updateColor(Color color) {
    setState(() {
      _selectedColor = color;
      // Update hex field when color changes from picker
      _hexController.text = color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
    });
  }

  void _updateColorFromHex(String hexValue) {
    if (hexValue.length == 6) {
      try {
        final color = Color(int.parse('FF$hexValue', radix: 16));
        setState(() {
          _selectedColor = color;
        });
      } catch (e) {
        // Invalid hex, ignore
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 320, // Standard width for proper display
        decoration: ShapeDecoration(
          color: widget.colors.primaryBackground,
          shape: SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius(
              cornerRadius: 16,
              cornerSmoothing: 1.0,
            ),
            side: BorderSide(
              color: widget.colors.primaryBorder.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          shadows: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipSmoothRect(
          radius: SmoothBorderRadius(
            cornerRadius: 16,
            cornerSmoothing: 1.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with color preview
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.colors.secondaryBackground,
                  border: Border(
                    bottom: BorderSide(
                      color: widget.colors.primaryBorder.withValues(alpha: 0.12),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    if (widget.title != null) ...[
                      // Title
                      Row(
                        children: [
                          Text(
                            widget.title!.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: widget.colors.secondaryText.withValues(alpha: 0.6),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    // Color preview bar
                    Container(
                      width: double.infinity,
                      height: 36,
                      decoration: ShapeDecoration(
                        color: _selectedColor,
                        shape: SmoothRectangleBorder(
                          borderRadius: SmoothBorderRadius(
                            cornerRadius: 8,
                            cornerSmoothing: 0.8,
                          ),
                          side: BorderSide(
                            color: widget.colors.primaryBorder.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '#',
                              style: GoogleFonts.inter(
                                color: useWhiteForeground(_selectedColor) ? Colors.white : Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Flexible(
                              child: CupertinoTextField(
                                controller: _hexController,
                                focusNode: _hexFocusNode,
                                decoration: null,
                                textAlign: TextAlign.center,
                                textAlignVertical: TextAlignVertical.center,
                                maxLength: 6,
                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                style: GoogleFonts.inter(
                                  color: useWhiteForeground(_selectedColor) ? Colors.white : Colors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Fa-f]')),
                                  LengthLimitingTextInputFormatter(6),
                                ],
                                onChanged: _updateColorFromHex,
                                onSubmitted: _updateColorFromHex,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Compact custom color picker
              Container(
                constraints: const BoxConstraints(maxHeight: 280),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      width: 280,
                      height: 240, // Increased to accommodate the ColorPicker internal layout
                      child: ColorPicker(
                        pickerColor: _selectedColor,
                        onColorChanged: _updateColor,
                        pickerAreaHeightPercent: 0.5, // Compact picker area
                        enableAlpha: false,
                        displayThumbColor: true,
                        labelTypes: const [], // Remove labels for cleaner look
                        portraitOnly: true,
                        pickerAreaBorderRadius: const BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                ),
              ),
              // Action buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.colors.secondaryBackground,
                  border: Border(
                    top: BorderSide(
                      color: widget.colors.primaryBorder.withValues(alpha: 0.12),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: widget.onCancel,
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: widget.colors.primaryBackground,
                            borderRadius: BorderRadius.circular(9999), // Fully rounded like Twitter
                            border: Border.all(
                              color: widget.colors.primaryBorder.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: widget.colors.primaryText,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => widget.onColorChanged(_selectedColor),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: widget.colors.primaryText, // Black in light theme, white in dark theme
                            borderRadius: BorderRadius.circular(9999), // Fully rounded like Twitter
                            border: Border.all(
                              color: widget.colors.primaryText,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Apply',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: widget.colors.primaryBackground, // White in light theme, black in dark theme
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable color picker trigger widget
class WebColorPickerTrigger extends StatelessWidget {
  final Color currentColor;
  final String label;
  final ValueChanged<Color> onColorChanged;
  final dynamic colors; // Theme colors
  final String? title;

  const WebColorPickerTrigger({
    super.key,
    required this.currentColor,
    required this.label,
    required this.onColorChanged,
    required this.colors,
    this.title,
  });

  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 400,
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              child: WebColorPickerDropdown(
                initialColor: currentColor,
                onColorChanged: (color) {
                  onColorChanged(color);
                  Navigator.of(context).pop();
                },
                onCancel: () {
                  Navigator.of(context).pop();
                },
                colors: colors,
                title: title,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    color: colors.primaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _showColorPicker(context),
                child: Container(
                  width: 32,
                  height: 32, // Make it circular
                  decoration: BoxDecoration(
                    color: currentColor,
                    shape: BoxShape.circle, // Perfect circle
                    border: Border.all(
                      color: colors.primaryBorder.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Subtle separator line
        Container(
          height: 0.5,
          color: colors.primaryBorder.withValues(alpha: 0.2),
        ),
      ],
    );
  }
}