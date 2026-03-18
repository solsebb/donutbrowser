import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Material, MaterialType;
import 'package:figma_squircle/figma_squircle.dart';

/// Reusable base widget for web dropdown menus
/// Provides consistent styling and behavior for dropdown overlays
class WebDropdownBase extends StatefulWidget {
  final Widget trigger;
  final Widget Function(BuildContext context, VoidCallback closeDropdown)
      dropdownBuilder;
  final double dropdownWidth;
  final AlignmentGeometry alignment;
  final double offsetY;

  const WebDropdownBase({
    super.key,
    required this.trigger,
    required this.dropdownBuilder,
    this.dropdownWidth = 280,
    this.alignment = Alignment.topLeft,
    this.offsetY = 8,
  });

  @override
  State<WebDropdownBase> createState() => _WebDropdownBaseState();
}

class _WebDropdownBaseState extends State<WebDropdownBase> {
  bool _isOpen = false;
  OverlayEntry? _overlayEntry;
  final _buttonKey = GlobalKey();

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    // Only call setState if widget is still mounted and not being disposed
    if (mounted) {
      // Use a post frame callback to avoid setState during dispose
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isOpen = false;
          });
        }
      });
    } else {
      _isOpen = false;
    }
  }

  void _showOverlay() {
    final RenderBox? renderBox =
        _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    // Determine if this is a dropup (bottom alignment) or dropdown (top alignment)
    final isDropup = widget.alignment == Alignment.bottomLeft ||
        widget.alignment == Alignment.bottomCenter ||
        widget.alignment == Alignment.bottomRight;

    // Calculate horizontal position based on alignment
    double left = position.dx;
    if (widget.alignment == Alignment.topRight ||
        widget.alignment == Alignment.centerRight ||
        widget.alignment == Alignment.bottomRight) {
      left = position.dx + size.width - widget.dropdownWidth;
    } else if (widget.alignment == Alignment.topCenter ||
        widget.alignment == Alignment.center ||
        widget.alignment == Alignment.bottomCenter) {
      left = position.dx + (size.width - widget.dropdownWidth) / 2;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            // Backdrop to capture taps outside
            Positioned.fill(
              child: GestureDetector(
                onTap: _removeOverlay,
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.transparent),
              ),
            ),
            // Dropdown menu - position above or below based on alignment
            Positioned(
              top: isDropup ? null : position.dy + size.height + widget.offsetY,
              bottom: isDropup
                  ? MediaQuery.of(context).size.height -
                      position.dy +
                      widget.offsetY.abs()
                  : null,
              left: left,
              width: widget.dropdownWidth,
              child: Material(
                color: Colors.transparent,
                elevation: 24, // High elevation to ensure it's on top
                child: widget.dropdownBuilder(context, _removeOverlay),
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      key: _buttonKey,
      padding: EdgeInsets.zero,
      onPressed: _toggleDropdown,
      child: widget.trigger,
    );
  }
}

/// Standard dropdown container with smooth rect decoration
class WebDropdownContainer extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final Color borderColor;
  final double maxHeight;

  const WebDropdownContainer({
    super.key,
    required this.child,
    required this.backgroundColor,
    required this.borderColor,
    this.maxHeight = 400,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }
}
