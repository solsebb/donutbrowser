import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_shared_core/theme/providers/theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class HoverTooltip extends ConsumerStatefulWidget {
  const HoverTooltip({
    super.key,
    required this.message,
    required this.child,
    this.leftOffset = -35,
    this.topOffset = 40,
    this.delay = const Duration(milliseconds: 500),
  });

  final String message;
  final Widget child;
  final double? leftOffset;
  final double? topOffset;
  final Duration delay;

  @override
  ConsumerState<HoverTooltip> createState() => _HoverTooltipState();
}

class _HoverTooltipState extends ConsumerState<HoverTooltip> {
  final LayerLink _layerLink = LayerLink();
  Timer? _timer;
  OverlayEntry? _overlayEntry;
  bool _isHovered = false;

  void _onEnter() {
    setState(() => _isHovered = true);
    _timer = Timer(widget.delay, () {
      if (_isHovered && mounted) {
        _showTooltip();
      }
    });
  }

  void _onExit() {
    setState(() => _isHovered = false);
    _timer?.cancel();
    _timer = null;
    _removeTooltip();
  }

  void _showTooltip() {
    if (_overlayEntry != null) {
      return;
    }

    final colors = ref.read(themeColorsProvider);
    final themeMode = ref.read(themeModeProvider);
    final brightness = MediaQuery.of(context).platformBrightness;
    final isLightTheme =
        themeMode == AppThemeMode.light ||
        (themeMode == AppThemeMode.system && brightness == Brightness.light);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: 0,
        top: 0,
        child: CompositedTransformFollower(
          link: _layerLink,
          offset: Offset(widget.leftOffset ?? -35, widget.topOffset ?? 40),
          showWhenUnlinked: false,
          child: IgnorePointer(
            child: FittedBox(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isLightTheme ? CupertinoColors.white : colors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: isLightTheme
                      ? Border.all(
                          color: Colors.black.withValues(alpha: 0.08),
                          width: 1,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: isLightTheme
                          ? CupertinoColors.black.withValues(alpha: 0.1)
                          : Colors.white.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  widget.message,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isLightTheme ? CupertinoColors.black : CupertinoColors.white,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeTooltip() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _removeTooltip();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) => _onEnter(),
        onExit: (_) => _onExit(),
        child: widget.child,
      ),
    );
  }
}
