import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' show Colors, Material, MaterialType;
import 'package:google_fonts/google_fonts.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Data model for article hover preview content
class ArticlePreviewData {
  final String? heroImageUrl;
  final String title;
  final String? subtitle;

  const ArticlePreviewData({
    this.heroImageUrl,
    required this.title,
    this.subtitle,
  });

  /// Check if preview has displayable content (hero image)
  bool get hasPreviewContent => heroImageUrl != null && heroImageUrl!.isNotEmpty;
}

/// A reusable hover preview widget that shows an article preview card
/// on hover (desktop/web only).
///
/// Usage:
/// ```dart
/// ArticleHoverPreview(
///   previewData: ArticlePreviewData(
///     heroImageUrl: article.heroImageUrl,
///     title: article.title,
///     subtitle: article.keyword,
///   ),
///   isLightTheme: isLightTheme,
///   child: YourWidget(),
/// )
/// ```
class ArticleHoverPreview extends StatefulWidget {
  /// The widget to wrap with hover preview functionality
  final Widget child;

  /// The preview data to display in the tooltip
  final ArticlePreviewData previewData;

  /// Whether the current theme is light
  final bool isLightTheme;

  /// Whether to enable the preview (useful for conditional enabling)
  final bool enabled;

  /// Callback when hover state changes
  final void Function(bool isHovering)? onHoverChanged;

  const ArticleHoverPreview({
    super.key,
    required this.child,
    required this.previewData,
    required this.isLightTheme,
    this.enabled = true,
    this.onHoverChanged,
  });

  @override
  State<ArticleHoverPreview> createState() => _ArticleHoverPreviewState();
}

class _ArticleHoverPreviewState extends State<ArticleHoverPreview>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  Offset _mousePosition = Offset.zero;
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
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _animationController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovering) {
    if (!kIsWeb) return; // Only on web
    if (!widget.enabled) return;
    if (!widget.previewData.hasPreviewContent) return;

    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth <= 768) return; // Only on desktop

    widget.onHoverChanged?.call(isHovering);

    if (isHovering) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _updateMousePosition(PointerEvent event) {
    _mousePosition = event.position;
  }

  void _showOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => _buildOverlayContent(),
    );
    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward();
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _animationController.reset();
    }
  }

  Widget _buildOverlayContent() {
    final cardBackground = widget.isLightTheme
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF2C2C2C);
    final borderColor = widget.isLightTheme
        ? const Color(0xFF000000).withValues(alpha: 0.08)
        : const Color(0xFFFFFFFF).withValues(alpha: 0.08);
    final titleColor = widget.isLightTheme
        ? const Color(0xFF37352F)
        : const Color(0xFFFFFFFF).withValues(alpha: 0.9);
    final descriptionColor = widget.isLightTheme
        ? const Color(0xFF6B6B6B)
        : const Color(0xFFFFFFFF).withValues(alpha: 0.6);

    // Position tooltip above the mouse, centered horizontally
    const tooltipWidth = 280.0;
    const tooltipHeight = 200.0; // Approximate height
    double left = _mousePosition.dx - (tooltipWidth / 2);
    double top = _mousePosition.dy - tooltipHeight - 20; // 20px gap above cursor

    // Keep tooltip within screen bounds
    final screenWidth = MediaQuery.of(context).size.width;
    if (left < 20) left = 20;
    if (left + tooltipWidth > screenWidth - 20) {
      left = screenWidth - tooltipWidth - 20;
    }
    if (top < 20) top = _mousePosition.dy + 30; // Show below if no space above

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Positioned(
          left: left,
          top: top,
          width: tooltipWidth,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              alignment: Alignment.bottomCenter,
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  decoration: ShapeDecoration(
                    color: cardBackground,
                    shape: SmoothRectangleBorder(
                      borderRadius: SmoothBorderRadius(
                        cornerRadius: 12,
                        cornerSmoothing: 0.8,
                      ),
                      side: BorderSide(color: borderColor, width: 1),
                    ),
                    shadows: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ClipSmoothRect(
                    radius: SmoothBorderRadius(
                      cornerRadius: 12,
                      cornerSmoothing: 0.8,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hero Image Preview
                        if (widget.previewData.heroImageUrl != null)
                          SizedBox(
                            height: 120,
                            width: double.infinity,
                            child: CachedNetworkImage(
                              imageUrl: widget.previewData.heroImageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: widget.isLightTheme
                                    ? const Color(0xFFF5F5F5)
                                    : const Color(0xFF1A1A1A),
                                child: Center(
                                  child: CupertinoActivityIndicator(
                                    color: descriptionColor,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: widget.isLightTheme
                                    ? const Color(0xFFF5F5F5)
                                    : const Color(0xFF1A1A1A),
                                child: Center(
                                  child: Icon(
                                    CupertinoIcons.photo,
                                    color: descriptionColor.withValues(alpha: 0.5),
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        // Title and Description
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.previewData.title.isEmpty
                                    ? 'Untitled'
                                    : widget.previewData.title,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: titleColor,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (widget.previewData.subtitle != null &&
                                  widget.previewData.subtitle!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  widget.previewData.subtitle!,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: descriptionColor,
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only add hover functionality on web/desktop
    if (!kIsWeb || !widget.enabled || !widget.previewData.hasPreviewContent) {
      return widget.child;
    }

    return Listener(
      onPointerMove: _updateMousePosition,
      onPointerHover: _updateMousePosition,
      child: MouseRegion(
        onEnter: (_) => _onHover(true),
        onExit: (_) => _onHover(false),
        child: widget.child,
      ),
    );
  }
}
