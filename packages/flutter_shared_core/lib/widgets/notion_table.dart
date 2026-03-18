import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:google_fonts/google_fonts.dart';

/// Configuration for a Notion-style table column
class NotionTableColumn<T> {
  /// Column header text
  final String header;

  /// Flex value for column width (relative to other columns)
  final int flex;

  /// Builder to create cell content for this column
  final Widget Function(T item, int index, bool isHovered) cellBuilder;

  /// Optional custom header widget (if null, uses default text header)
  final Widget? headerWidget;

  const NotionTableColumn({
    required this.header,
    required this.flex,
    required this.cellBuilder,
    this.headerWidget,
  });
}

/// A reusable Notion-style table widget with customizable columns
///
/// Features:
/// - Configurable columns with flex widths
/// - Notion-style borders and styling
/// - Row hover states
/// - Optional row tap callback
/// - Light/Dark theme support
class NotionTable<T> extends StatefulWidget {
  /// List of items to display
  final List<T> items;

  /// Column configurations
  final List<NotionTableColumn<T>> columns;

  /// Whether using light theme
  final bool isLightTheme;

  /// Callback when a row is tapped (optional)
  final Function(T item, int index)? onRowTap;

  /// Callback when row hover state changes (optional)
  final Function(int index, bool isHovering)? onRowHover;

  /// Custom border color (optional, uses default Notion colors if null)
  final Color? borderColor;

  /// Custom header background color (optional)
  final Color? headerBackgroundColor;

  /// Custom row hover color (optional)
  final Color? rowHoverColor;

  /// Show header row (default: true)
  final bool showHeader;

  /// Show vertical borders between columns (default: true)
  final bool showVerticalBorders;

  /// Show outer border around the table (default: true)
  final bool showOuterBorder;

  /// Horizontal padding applied to the inner rows (default: 0)
  final double horizontalEdgePadding;

  /// Minimum row height (default: 34)
  final double minRowHeight;

  /// Minimum header row height (defaults to [minRowHeight] if null)
  final double? headerMinHeight;

  /// Optional custom header cell padding (defaults to Notion-like 9x7)
  final EdgeInsetsGeometry? headerCellPadding;

  /// Border radius for the table container (default: 4)
  final double borderRadius;

  const NotionTable({
    super.key,
    required this.items,
    required this.columns,
    required this.isLightTheme,
    this.onRowTap,
    this.onRowHover,
    this.borderColor,
    this.headerBackgroundColor,
    this.rowHoverColor,
    this.showHeader = true,
    this.showVerticalBorders = true,
    this.showOuterBorder = true,
    this.horizontalEdgePadding = 0.0,
    this.minRowHeight = 34,
    this.headerMinHeight,
    this.headerCellPadding,
    this.borderRadius = 4,
  });

  @override
  State<NotionTable<T>> createState() => _NotionTableState<T>();
}

class _NotionTableState<T> extends State<NotionTable<T>> {
  int? _hoveredRowIndex;

  // Notion default colors
  Color get _borderColor =>
      widget.borderColor ??
      (widget.isLightTheme
          ? const Color(0xFFE9E9E7) // Light mode border
          : const Color(0xFF373737)); // Dark mode border

  Color get _headerBgColor =>
      widget.headerBackgroundColor ??
      (widget.isLightTheme
          ? const Color(0xFFF7F6F3) // Light mode header bg
          : const Color(0xFF252525)); // Dark mode header bg

  Color get _rowHoverColor =>
      widget.rowHoverColor ??
      (widget.isLightTheme
          ? const Color(0xFFF7F6F3)
          : const Color(0xFF2F2F2F));

  Color get _textColor => widget.isLightTheme
      ? const Color(0xFF37352F)
      : const Color(0xFFFFFFFF).withValues(alpha: 0.9);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: widget.showOuterBorder ? Border.all(color: _borderColor, width: 1) : null,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius - 1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row
            if (widget.showHeader) _buildHeaderRow(),
            // Data rows
            ...widget.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == widget.items.length - 1;
              return _buildDataRow(
                item: item,
                index: index,
                isLast: isLast,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow() {
    final effectiveHeaderMinHeight = widget.headerMinHeight ?? widget.minRowHeight;
    return Container(
      constraints: BoxConstraints(minHeight: effectiveHeaderMinHeight),
      decoration: BoxDecoration(
        color: _headerBgColor,
        border: Border(
          bottom: BorderSide(color: _borderColor, width: 1),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: widget.horizontalEdgePadding),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: widget.columns.asMap().entries.map((entry) {
              final index = entry.key;
              final column = entry.value;
              final isLast = index == widget.columns.length - 1;
              return _buildHeaderCell(
                column,
                minHeight: effectiveHeaderMinHeight,
                isLast: isLast,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(
    NotionTableColumn<T> column, {
    required double minHeight,
    bool isLast = false,
  }) {
    final effectiveHeaderCellPadding =
        widget.headerCellPadding ??
        const EdgeInsets.symmetric(horizontal: 9, vertical: 7);

    return Expanded(
      flex: column.flex,
      child: Container(
        constraints: BoxConstraints(minHeight: minHeight),
        padding: effectiveHeaderCellPadding,
        decoration: BoxDecoration(
          border: isLast || !widget.showVerticalBorders
              ? null
              : Border(
                  right: BorderSide(color: _borderColor, width: 1),
                ),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: column.headerWidget ??
              Text(
                column.header,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 20 / 14,
                  color: _textColor,
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildDataRow({
    required T item,
    required int index,
    required bool isLast,
  }) {
    final isHovered = _hoveredRowIndex == index;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _hoveredRowIndex = index);
        widget.onRowHover?.call(index, true);
      },
      onExit: (_) {
        setState(() => _hoveredRowIndex = null);
        widget.onRowHover?.call(index, false);
      },
      cursor: widget.onRowTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onRowTap != null ? () => widget.onRowTap!(item, index) : null,
        child: Container(
          constraints: BoxConstraints(minHeight: widget.minRowHeight),
          decoration: BoxDecoration(
            color: isHovered ? _rowHoverColor : Colors.transparent,
            border: isLast
                ? null
                : Border(
                    bottom: BorderSide(color: _borderColor, width: 1),
                  ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.horizontalEdgePadding),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: widget.columns.asMap().entries.map((entry) {
                  final colIndex = entry.key;
                  final column = entry.value;
                  final isLastCol = colIndex == widget.columns.length - 1;
                  return _buildDataCell(
                    child: column.cellBuilder(item, index, isHovered),
                    flex: column.flex,
                    isLast: isLastCol,
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataCell({
    required Widget child,
    required int flex,
    bool isLast = false,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        constraints: BoxConstraints(minHeight: widget.minRowHeight),
        decoration: BoxDecoration(
          border: isLast || !widget.showVerticalBorders
              ? null
              : Border(
                  right: BorderSide(color: _borderColor, width: 1),
                ),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: child,
        ),
      ),
    );
  }
}

// =============================================================================
// NOTION TABLE BADGE UTILITIES
// =============================================================================

/// A colored badge widget for displaying values in Notion-style tables
class NotionBadge extends StatelessWidget {
  final String text;
  final Color color;
  final double fontSize;
  final FontWeight fontWeight;

  const NotionBadge({
    super.key,
    required this.text,
    required this.color,
    this.fontSize = 12,
    this.fontWeight = FontWeight.w500,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        ),
      ),
    );
  }
}

/// Badge color utilities for common use cases
class NotionBadgeColors {
  // Difficulty colors
  static Color difficultyColor(double difficulty) {
    if (difficulty < 30) return const Color(0xFF10B981); // Green - Easy
    if (difficulty < 50) return const Color(0xFFF59E0B); // Amber - Medium
    if (difficulty < 70) return const Color(0xFFF97316); // Orange - Hard
    return const Color(0xFFEF4444); // Red - Very Hard
  }

  // Score/percentage colors
  static Color scoreColor(double score, {double highThreshold = 0.6, double mediumThreshold = 0.4}) {
    if (score >= highThreshold) return const Color(0xFF10B981); // Green
    if (score >= mediumThreshold) return const Color(0xFFF59E0B); // Amber
    return const Color(0xFF6B7280); // Gray
  }

  // Intent colors
  static const Color transactional = Color(0xFF10B981); // Green
  static const Color commercial = Color(0xFF3B82F6); // Blue
  static const Color informational = Color(0xFF8B5CF6); // Purple
  static const Color navigational = Color(0xFF6B7280); // Gray

  // Status colors
  static const Color success = Color(0xFF10B981); // Green
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color danger = Color(0xFFEF4444); // Red
  static const Color info = Color(0xFF3B82F6); // Blue
  static const Color muted = Color(0xFF6B7280); // Gray

  // Published/Draft status
  static const Color published = Color(0xFF34D16C);
  static const Color draft = Color(0xFF9B9A97);
}

/// Text styling utilities for Notion tables
class NotionTableTextStyles {
  static TextStyle primary(bool isLightTheme, {double fontSize = 14, FontWeight fontWeight = FontWeight.w400}) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: 20 / 14,
      color: isLightTheme
          ? const Color(0xFF37352F)
          : const Color(0xFFFFFFFF).withValues(alpha: 0.9),
    );
  }

  static TextStyle secondary(bool isLightTheme, {double fontSize = 14}) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      height: 20 / 14,
      color: isLightTheme
          ? const Color(0xFF9B9A97)
          : const Color(0xFFFFFFFF).withValues(alpha: 0.5),
    );
  }

  static TextStyle muted(bool isLightTheme, {double fontSize = 14}) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      color: isLightTheme
          ? const Color(0xFF9B9A97)
          : const Color(0xFFFFFFFF).withValues(alpha: 0.3),
    );
  }
}
