import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'bottom_app_modal.dart';
import 'hover_tooltip.dart';

/// Reusable navigation item with "Coming soon" tooltip and modal
/// Used in landing page header for features not yet available (API, Templates, etc.)
class ComingSoonNavItem extends StatefulWidget {
  final String label;
  final dynamic colors;
  final String? modalTitle;
  final String? modalSubtitle;

  const ComingSoonNavItem({
    super.key,
    required this.label,
    required this.colors,
    this.modalTitle,
    this.modalSubtitle,
  });

  @override
  State<ComingSoonNavItem> createState() => _ComingSoonNavItemState();
}

class _ComingSoonNavItemState extends State<ComingSoonNavItem> {
  bool _isHovering = false;
  bool _showTooltip = false;
  Timer? _tooltipTimer;

  @override
  void dispose() {
    _tooltipTimer?.cancel();
    super.dispose();
  }

  void _onHoverEnter() {
    setState(() => _isHovering = true);
    // Show tooltip after 500ms delay
    _tooltipTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted && _isHovering) {
        setState(() => _showTooltip = true);
      }
    });
  }

  void _onHoverExit() {
    _tooltipTimer?.cancel();
    setState(() {
      _isHovering = false;
      _showTooltip = false;
    });
  }

  void _showComingSoonModal(BuildContext context) {
    showBottomAppModal(
      context: context,
      title: widget.modalTitle ?? '${widget.label} Coming Soon',
      subtitle: widget.modalSubtitle ??
          'Our ${widget.label} feature will be available in Q4 2025 and is still being developed. Stay tuned for updates!',
      centerModal: true,
      primaryButton: BottomModalButton(
        label: 'Got it',
        onTap: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: MouseRegion(
        onEnter: (_) => _onHoverEnter(),
        onExit: (_) => _onHoverExit(),
        child: _showTooltip
            ? HoverTooltip(
                message: 'Coming soon',
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: () => _showComingSoonModal(context),
                  child: Text(
                    widget.label,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600, // Bold on hover
                      color: widget.colors.primaryText, // Primary color on hover
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              )
            : CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                onPressed: () => _showComingSoonModal(context),
                child: Text(
                  widget.label,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: _isHovering ? FontWeight.w600 : FontWeight.w500,
                    color: _isHovering ? widget.colors.primaryText : widget.colors.secondaryText,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
      ),
    );
  }
}
