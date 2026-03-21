import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_shared_core/theme/providers/theme_provider.dart';

/// Reusable hover preview card widget - X/Twitter style preview on hover
/// Shows a rich preview card with image, title, and description
/// Desktop only - no preview on mobile
class HoverPreviewCard extends ConsumerStatefulWidget {
  final String title;
  final String description;
  final String? previewImagePath;
  final Widget? previewWidget;
  final Widget child;
  final double cardWidth;
  final double? leftOffset;
  final double? topOffset;
  final Duration delay;
  final bool enabled;

  const HoverPreviewCard({
    super.key,
    required this.title,
    required this.description,
    this.previewImagePath,
    this.previewWidget,
    required this.child,
    this.cardWidth = 280,
    this.leftOffset,
    this.topOffset,
    this.delay = const Duration(milliseconds: 400),
    this.enabled = true,
  });

  @override
  ConsumerState<HoverPreviewCard> createState() => _HoverPreviewCardState();
}

class _HoverPreviewCardState extends ConsumerState<HoverPreviewCard>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  // Animation controller for smooth fade-in
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    // Simple scale - no bounce
    _scaleAnimation = Tween<double>(begin: 0.97, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  void _onEnter() {
    // Only show preview on desktop web
    if (!kIsWeb || !widget.enabled) return;

    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth <= 768) return; // Mobile responsive - no preview

    // Show preview immediately (atomic display) with bounce animation
    if (mounted) {
      _showPreview();
    }
  }

  void _onExit() {
    // Remove preview with fade out
    _hidePreview();
  }

  void _showPreview() {
    if (_overlayEntry != null) return; // Already showing

    final colors = ref.read(themeColorsProvider);
    final themeMode = ref.read(themeModeProvider);
    final brightness = MediaQuery.of(context).platformBrightness;
    final isLightTheme = themeMode == AppThemeMode.light ||
        (themeMode == AppThemeMode.system && brightness == Brightness.light);

    // Calculate position - show to the right of the button
    final screenWidth = MediaQuery.of(context).size.width;
    final leftOffset = widget.leftOffset ?? (screenWidth > 1200 ? 420 : 320);
    final topOffset = widget.topOffset ?? -60;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: 0,
        top: 0,
        child: CompositedTransformFollower(
          link: _layerLink,
          offset: Offset(leftOffset, topOffset),
          showWhenUnlinked: false,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) => Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            ),
            child: IgnorePointer(
              child: Container(
                width: widget.cardWidth,
                decoration: ShapeDecoration(
                  color: isLightTheme ? CupertinoColors.white : colors.cardBackground,
                  shape: SmoothRectangleBorder(
                    borderRadius: SmoothBorderRadius(
                      cornerRadius: 16,
                      cornerSmoothing: 0.8,
                    ),
                    side: BorderSide(
                      color: isLightTheme
                          ? Colors.black.withValues(alpha: 0.08)
                          : colors.primaryBorder.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  shadows: [
                    BoxShadow(
                      color: isLightTheme
                          ? CupertinoColors.black.withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: ClipSmoothRect(
                  radius: SmoothBorderRadius(
                    cornerRadius: 16,
                    cornerSmoothing: 0.8,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Preview image/widget
                      if (widget.previewWidget != null)
                        Container(
                          width: double.infinity,
                          height: 160,
                          color: isLightTheme
                              ? const Color(0xFFF5F5F5)
                              : colors.secondaryBackground,
                          child: widget.previewWidget,
                        )
                      else if (widget.previewImagePath != null)
                        Container(
                          width: double.infinity,
                          height: 160,
                          color: isLightTheme
                              ? const Color(0xFFF5F5F5)
                              : colors.secondaryBackground,
                          child: widget.previewImagePath!.endsWith('.svg')
                              ? SvgPicture.asset(
                                  widget.previewImagePath!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 160,
                                )
                              : Image.asset(
                                  widget.previewImagePath!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 160,
                                ),
                        ),
                      // Content section
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Text(
                              widget.title,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isLightTheme
                                    ? CupertinoColors.black
                                    : CupertinoColors.white,
                                letterSpacing: -0.3,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Description
                            Text(
                              widget.description,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: isLightTheme
                                    ? CupertinoColors.systemGrey
                                    : colors.secondaryText,
                                letterSpacing: -0.1,
                                height: 1.4,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward();
  }

  void _hidePreview() async {
    if (_overlayEntry == null) return;

    // Fade out animation
    await _animationController.reverse();

    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _animationController.dispose();
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
