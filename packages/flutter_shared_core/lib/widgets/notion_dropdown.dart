import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' show Colors, Material, MaterialType, BoxShadow;
import 'package:google_fonts/google_fonts.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter_shared_core/theme/providers/theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Positioning mode for the dropdown relative to tap position
enum NotionDropdownPosition {
  /// Default - dropdown appears below and to the right of tap
  belowRight,

  /// Notion block menu style - dropdown appears to the LEFT of tap
  leftAligned,
}

/// Configuration for optional search functionality
class NotionDropdownSearchConfig {
  final String placeholder;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  const NotionDropdownSearchConfig({
    this.placeholder = 'Search...',
    required this.onChanged,
    this.controller,
  });
}

/// Configuration for optional footer section
class NotionDropdownFooterConfig {
  final String? label;
  final String? value;
  final Widget? customWidget;

  const NotionDropdownFooterConfig({
    this.label,
    this.value,
    this.customWidget,
  });
}

/// Shows a Notion-style dropdown overlay at the specified position.
/// This is a shared reusable dropdown that provides consistent styling
/// across the app (blog selector, block actions, page actions, etc.)
///
/// Features:
/// - [searchConfig] - Optional search input at the top
/// - [footerConfig] - Optional footer section at the bottom
/// - [positionMode] - Control dropdown positioning relative to tap
/// - [showDeeperShadow] - Enhanced shadow for complex dropdowns like block actions
/// - [cornerRadius] - Customizable corner radius (default 8, block actions uses 10)
void showNotionDropdown({
  required BuildContext context,
  required Offset tapPosition,
  required Widget Function(BuildContext context, VoidCallback close) builder,
  double width = 260.0,
  double? maxHeight,
  Alignment alignment = Alignment.topLeft,
  double cornerRadius = 8.0,
  double cornerSmoothing = 0.6,
  Duration animationDuration = const Duration(milliseconds: 150),
  NotionDropdownPosition positionMode = NotionDropdownPosition.belowRight,
  NotionDropdownSearchConfig? searchConfig,
  NotionDropdownFooterConfig? footerConfig,
  bool showDeeperShadow = false,
  String? headerTitle,
}) {
  if (!context.mounted) return;

  try {
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (ctx) => _NotionDropdownOverlay(
        tapPosition: tapPosition,
        width: width,
        maxHeight: maxHeight,
        alignment: alignment,
        cornerRadius: cornerRadius,
        cornerSmoothing: cornerSmoothing,
        animationDuration: animationDuration,
        positionMode: positionMode,
        searchConfig: searchConfig,
        footerConfig: footerConfig,
        showDeeperShadow: showDeeperShadow,
        headerTitle: headerTitle,
        onClose: () => overlayEntry.remove(),
        builder: builder,
      ),
    );

    overlay.insert(overlayEntry);
  } catch (e) {
    debugPrint('Error in showNotionDropdown: $e');
  }
}

/// Internal overlay widget for Notion-style dropdown
class _NotionDropdownOverlay extends ConsumerStatefulWidget {
  final Offset tapPosition;
  final double width;
  final double? maxHeight;
  final Alignment alignment;
  final double cornerRadius;
  final double cornerSmoothing;
  final Duration animationDuration;
  final NotionDropdownPosition positionMode;
  final NotionDropdownSearchConfig? searchConfig;
  final NotionDropdownFooterConfig? footerConfig;
  final bool showDeeperShadow;
  final String? headerTitle;
  final VoidCallback onClose;
  final Widget Function(BuildContext context, VoidCallback close) builder;

  const _NotionDropdownOverlay({
    required this.tapPosition,
    required this.width,
    this.maxHeight,
    required this.alignment,
    required this.cornerRadius,
    required this.cornerSmoothing,
    required this.animationDuration,
    required this.positionMode,
    this.searchConfig,
    this.footerConfig,
    required this.showDeeperShadow,
    this.headerTitle,
    required this.onClose,
    required this.builder,
  });

  @override
  ConsumerState<_NotionDropdownOverlay> createState() =>
      _NotionDropdownOverlayState();
}

class _NotionDropdownOverlayState extends ConsumerState<_NotionDropdownOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final brightness = MediaQuery.of(context).platformBrightness;
    final isLightTheme = themeMode == AppThemeMode.light ||
        (themeMode == AppThemeMode.system && brightness == Brightness.light);

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final effectiveMaxHeight = widget.maxHeight ?? 400.0;

    // Calculate position based on position mode
    double left;
    double top;

    if (widget.positionMode == NotionDropdownPosition.leftAligned) {
      // Block actions style - show to the LEFT of tap position
      left = widget.tapPosition.dx - widget.width - 8;
      if (left < 24) {
        left = widget.tapPosition.dx + 8;
      }
      if (left + widget.width > screenWidth - 24) {
        left = screenWidth - widget.width - 24;
      }
      top = widget.tapPosition.dy - 16;
      if (top < 24) top = 24;
      if (top + effectiveMaxHeight > screenHeight - 24) {
        top = screenHeight - effectiveMaxHeight - 24;
      }
    } else {
      // Default - show below and to the right
      left = widget.tapPosition.dx;
      if (left + widget.width > screenWidth - 12) {
        left = screenWidth - widget.width - 12;
      }
      if (left < 12) left = 12;

      top = widget.tapPosition.dy + 4;
      if (top + effectiveMaxHeight > screenHeight - 12) {
        top = widget.tapPosition.dy - effectiveMaxHeight - 4;
      }
      if (top < 12) top = 12;
    }

    // Theme colors - matching Notion exactly
    final theme = NotionDropdownTheme(isLightTheme: isLightTheme);

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Backdrop - tap to close
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onClose,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),

          // Dropdown
          Positioned(
            left: left,
            top: top,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    alignment: widget.alignment,
                    child: child,
                  ),
                );
              },
              child: Container(
                width: widget.width,
                constraints: widget.maxHeight != null
                    ? BoxConstraints(maxHeight: widget.maxHeight!)
                    : null,
                decoration: _buildDecoration(theme, isLightTheme),
                child: ClipSmoothRect(
                  radius: SmoothBorderRadius(
                    cornerRadius: widget.cornerRadius,
                    cornerSmoothing: widget.cornerSmoothing,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Optional search input
                      if (widget.searchConfig != null)
                        _buildSearchInput(theme),

                      // Optional header title
                      if (widget.headerTitle != null)
                        NotionDropdownHeader(
                          title: widget.headerTitle!,
                          textColor: theme.secondaryTextColor,
                        ),

                      // Main content from builder
                      Flexible(
                        child: widget.builder(context, widget.onClose),
                      ),

                      // Optional footer
                      if (widget.footerConfig != null)
                        _buildFooter(theme),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ShapeDecoration _buildDecoration(NotionDropdownTheme theme, bool isLightTheme) {
    final shadows = widget.showDeeperShadow
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: isLightTheme ? 0.12 : 0.35),
              blurRadius: 16,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isLightTheme ? 0.08 : 0.25),
              blurRadius: 32,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: isLightTheme ? 0.1 : 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ];

    return ShapeDecoration(
      color: theme.backgroundColor,
      shape: SmoothRectangleBorder(
        borderRadius: SmoothBorderRadius(
          cornerRadius: widget.cornerRadius,
          cornerSmoothing: widget.cornerSmoothing,
        ),
        side: BorderSide(color: theme.borderColor, width: 1),
      ),
      shadows: shadows,
    );
  }

  Widget _buildSearchInput(NotionDropdownTheme theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: theme.searchBgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: CupertinoTextField(
          controller: widget.searchConfig!.controller,
          placeholder: widget.searchConfig!.placeholder,
          placeholderStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: theme.secondaryTextColor,
            letterSpacing: -0.2,
          ),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: theme.textColor,
            letterSpacing: -0.2,
          ),
          decoration: const BoxDecoration(
            color: CupertinoColors.transparent,
          ),
          padding: EdgeInsets.zero,
          onChanged: widget.searchConfig!.onChanged,
        ),
      ),
    );
  }

  Widget _buildFooter(NotionDropdownTheme theme) {
    final footer = widget.footerConfig!;

    if (footer.customWidget != null) {
      return footer.customWidget!;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        NotionDropdownDivider(color: theme.dividerColor),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (footer.label != null)
                Text(
                  footer.label!,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: theme.secondaryTextColor,
                  ),
                ),
              if (footer.value != null) ...[
                const SizedBox(height: 2),
                Text(
                  footer.value!,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Helper class providing common dropdown theme colors
class NotionDropdownTheme {
  final bool isLightTheme;

  NotionDropdownTheme({required this.isLightTheme});

  Color get backgroundColor =>
      isLightTheme ? CupertinoColors.white : const Color(0xFF252525);

  Color get borderColor => isLightTheme
      ? Colors.black.withValues(alpha: 0.08)
      : Colors.white.withValues(alpha: 0.08);

  Color get textColor => isLightTheme ? Colors.black : Colors.white;

  Color get secondaryTextColor => isLightTheme
      ? Colors.black.withValues(alpha: 0.5)
      : Colors.white.withValues(alpha: 0.5);

  Color get hoverBgColor => isLightTheme
      ? Colors.black.withValues(alpha: 0.04)
      : Colors.white.withValues(alpha: 0.06);

  Color get dividerColor => isLightTheme
      ? Colors.black.withValues(alpha: 0.06)
      : Colors.white.withValues(alpha: 0.08);

  Color get iconColor => isLightTheme
      ? Colors.black.withValues(alpha: 0.8)
      : Colors.white.withValues(alpha: 0.8);

  Color get searchBgColor => isLightTheme
      ? const Color(0xFFF7F7F5)
      : Colors.white.withValues(alpha: 0.06);

  /// Create theme from WidgetRef
  static NotionDropdownTheme fromRef(WidgetRef ref, BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final brightness = MediaQuery.of(context).platformBrightness;
    final isLightTheme = themeMode == AppThemeMode.light ||
        (themeMode == AppThemeMode.system && brightness == Brightness.light);
    return NotionDropdownTheme(isLightTheme: isLightTheme);
  }
}

/// Common dropdown row widget with hover effect
class NotionDropdownRow extends StatefulWidget {
  final Widget? leading;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;
  final double height;
  final Color textColor;
  final Color hoverBgColor;
  final bool isDestructive;
  final String? shortcut;
  final Color? secondaryTextColor;

  const NotionDropdownRow({
    super.key,
    this.leading,
    required this.label,
    this.trailing,
    required this.onTap,
    this.height = 36.0,
    required this.textColor,
    required this.hoverBgColor,
    this.isDestructive = false,
    this.shortcut,
    this.secondaryTextColor,
  });

  @override
  State<NotionDropdownRow> createState() => _NotionDropdownRowState();
}

class _NotionDropdownRowState extends State<NotionDropdownRow> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor = widget.isDestructive
        ? CupertinoColors.destructiveRed
        : widget.textColor;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: widget.height,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: _isHovering ? widget.hoverBgColor : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  widget.label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: effectiveTextColor,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.shortcut != null && widget.secondaryTextColor != null)
                Text(
                  widget.shortcut!,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: widget.secondaryTextColor,
                  ),
                ),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

/// Dropdown row with submenu arrow (like "Transform into")
class NotionDropdownRowWithSubmenu extends StatefulWidget {
  final Widget? leading;
  final String label;
  final Color textColor;
  final Color hoverBgColor;
  final Color secondaryTextColor;
  final bool isSubmenuVisible;
  final VoidCallback onHoverEnter;
  final VoidCallback onHoverExit;
  final double height;

  const NotionDropdownRowWithSubmenu({
    super.key,
    this.leading,
    required this.label,
    required this.textColor,
    required this.hoverBgColor,
    required this.secondaryTextColor,
    required this.isSubmenuVisible,
    required this.onHoverEnter,
    required this.onHoverExit,
    this.height = 36.0,
  });

  @override
  State<NotionDropdownRowWithSubmenu> createState() =>
      _NotionDropdownRowWithSubmenuState();
}

class _NotionDropdownRowWithSubmenuState
    extends State<NotionDropdownRowWithSubmenu> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    // Show hover state when mouse is on this item OR when submenu is visible
    final showHoverBg = _isHovering || widget.isSubmenuVisible;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _isHovering = true);
        widget.onHoverEnter();
      },
      onExit: (_) {
        setState(() => _isHovering = false);
        widget.onHoverExit();
      },
      child: Container(
        height: widget.height,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: showHoverBg ? widget.hoverBgColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            if (widget.leading != null) ...[
              widget.leading!,
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: widget.textColor,
                  letterSpacing: -0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: widget.secondaryTextColor,
            ),
          ],
        ),
      ),
    );
  }
}

/// Common dropdown header widget
class NotionDropdownHeader extends StatelessWidget {
  final String title;
  final Color textColor;

  const NotionDropdownHeader({
    super.key,
    required this.title,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

/// Common dropdown divider
class NotionDropdownDivider extends StatelessWidget {
  final Color color;
  final EdgeInsets margin;

  const NotionDropdownDivider({
    super.key,
    required this.color,
    this.margin = const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: margin,
      color: color,
    );
  }
}

/// Common dropdown icon wrapper - ensures consistent sizing
class NotionDropdownIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double containerSize;

  const NotionDropdownIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 18,
    this.containerSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: containerSize,
      height: containerSize,
      child: Center(
        child: Icon(
          icon,
          size: size,
          color: color,
        ),
      ),
    );
  }
}

/// Builds a submenu that appears to the side of the main dropdown
/// Use this for complex dropdowns like block actions with transform options
Widget buildNotionSubmenu({
  required BuildContext context,
  required double mainDropdownLeft,
  required double mainDropdownTop,
  required double mainDropdownWidth,
  required NotionDropdownTheme theme,
  required Widget child,
  double submenuWidth = 220.0,
  double verticalOffset = 80.0,
  VoidCallback? onHoverEnter,
  VoidCallback? onHoverExit,
}) {
  final screenWidth = MediaQuery.of(context).size.width;

  // Try to position on the right, fall back to left if not enough space
  double submenuLeft = mainDropdownLeft + mainDropdownWidth + 4;
  if (submenuLeft + submenuWidth > screenWidth - 24) {
    submenuLeft = mainDropdownLeft - submenuWidth - 4;
  }

  final submenuTop = mainDropdownTop + verticalOffset;

  return Positioned(
    left: submenuLeft,
    top: submenuTop,
    child: MouseRegion(
      onEnter: onHoverEnter != null ? (_) => onHoverEnter() : null,
      onExit: onHoverExit != null ? (_) => onHoverExit() : null,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 150),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset((1 - value) * -8, 0),
              child: child,
            ),
          );
        },
        child: Container(
          width: submenuWidth,
          constraints: const BoxConstraints(maxHeight: 400),
          decoration: ShapeDecoration(
            color: theme.backgroundColor,
            shape: SmoothRectangleBorder(
              borderRadius: SmoothBorderRadius(
                cornerRadius: 10,
                cornerSmoothing: 0.6,
              ),
              side: BorderSide(color: theme.borderColor, width: 1),
            ),
            shadows: [
              BoxShadow(
                color: Colors.black
                    .withValues(alpha: theme.isLightTheme ? 0.12 : 0.35),
                blurRadius: 16,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black
                    .withValues(alpha: theme.isLightTheme ? 0.08 : 0.25),
                blurRadius: 32,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipSmoothRect(
            radius: SmoothBorderRadius(
              cornerRadius: 10,
              cornerSmoothing: 0.6,
            ),
            child: child,
          ),
        ),
      ),
    ),
  );
}

/// Dropdown row with hover preview tooltip
/// Shows a preview card to the side when hovering (web desktop only)
/// Used for image style pickers where visual preview is helpful
class NotionDropdownRowWithPreview extends ConsumerStatefulWidget {
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;
  final double height;
  final Color textColor;
  final Color hoverBgColor;
  // Preview properties
  final String previewImagePath;
  final String previewTitle;
  final String previewDescription;

  const NotionDropdownRowWithPreview({
    super.key,
    required this.label,
    this.trailing,
    required this.onTap,
    this.height = 36.0,
    required this.textColor,
    required this.hoverBgColor,
    required this.previewImagePath,
    required this.previewTitle,
    required this.previewDescription,
  });

  @override
  ConsumerState<NotionDropdownRowWithPreview> createState() =>
      _NotionDropdownRowWithPreviewState();
}

class _NotionDropdownRowWithPreviewState
    extends ConsumerState<NotionDropdownRowWithPreview>
    with SingleTickerProviderStateMixin {
  bool _isHovering = false;
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
    _scaleAnimation = Tween<double>(begin: 0.97, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hidePreview();
    _animationController.dispose();
    super.dispose();
  }

  void _onEnter() {
    setState(() => _isHovering = true);

    // Only show preview on desktop web
    if (!kIsWeb) return;

    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth <= 768) return; // Mobile responsive - no preview

    _showPreview();
  }

  void _onExit() {
    setState(() => _isHovering = false);
    _hidePreview();
  }

  void _showPreview() {
    if (_overlayEntry != null) return; // Already showing

    final themeMode = ref.read(themeModeProvider);
    final brightness = MediaQuery.of(context).platformBrightness;
    final isLightTheme = themeMode == AppThemeMode.light ||
        (themeMode == AppThemeMode.system && brightness == Brightness.light);

    // Position preview to the LEFT of the dropdown row
    // Dropdown is right-aligned, so preview goes left
    const previewWidth = 240.0;
    const leftOffset = -(previewWidth + 12); // 12px gap

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: 0,
        top: 0,
        child: CompositedTransformFollower(
          link: _layerLink,
          offset: const Offset(leftOffset, -40), // Position left and slightly up
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
                width: previewWidth,
                decoration: ShapeDecoration(
                  color: isLightTheme ? CupertinoColors.white : const Color(0xFF252525),
                  shape: SmoothRectangleBorder(
                    borderRadius: SmoothBorderRadius(
                      cornerRadius: 12,
                      cornerSmoothing: 0.8,
                    ),
                    side: BorderSide(
                      color: isLightTheme
                          ? Colors.black.withValues(alpha: 0.08)
                          : Colors.white.withValues(alpha: 0.08),
                      width: 1,
                    ),
                  ),
                  shadows: [
                    BoxShadow(
                      color: isLightTheme
                          ? CupertinoColors.black.withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
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
                      // Preview image
                      Container(
                        width: double.infinity,
                        height: 120,
                        color: isLightTheme
                            ? const Color(0xFFF5F5F5)
                            : const Color(0xFF1A1A1A),
                        child: Image.asset(
                          widget.previewImagePath,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 120,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                CupertinoIcons.photo,
                                size: 32,
                                color: isLightTheme
                                    ? CupertinoColors.systemGrey
                                    : CupertinoColors.systemGrey2,
                              ),
                            );
                          },
                        ),
                      ),
                      // Content section
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Text(
                              widget.previewTitle,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isLightTheme
                                    ? CupertinoColors.black
                                    : CupertinoColors.white,
                                letterSpacing: -0.2,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Description
                            Text(
                              widget.previewDescription,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: isLightTheme
                                    ? CupertinoColors.systemGrey
                                    : CupertinoColors.systemGrey2,
                                letterSpacing: -0.1,
                                height: 1.4,
                              ),
                              maxLines: 2,
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

    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
    _animationController.forward();
  }

  void _hidePreview() {
    if (_overlayEntry == null) return;

    _animationController.reverse().then((_) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => _onEnter(),
        onExit: (_) => _onExit(),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            height: widget.height,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: _isHovering ? widget.hoverBgColor : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: widget.textColor,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.trailing != null) widget.trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
