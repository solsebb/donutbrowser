import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'custom_back_button.dart';
import 'package:flutter_shared_core/theme/providers/theme_provider.dart';
import 'dart:math' as math;

/// A reusable glass-effect header with search functionality that adapts to scroll position.
///
/// The header provides a blur effect that increases as the user scrolls, creating an
/// iOS-style glass effect for a modern and dynamic UI.
///
/// # Features:
/// - Dynamic glass effect that changes with scroll position
/// - Search bar with customizable placeholder
/// - Back button and title
/// - Optional trailing widget
///
/// # Usage Example:
/// ```dart
/// SearchHeader(
///   title: 'Settings',
///   searchController: _searchController,
///   scrollController: _scrollController,
///   onSearchChanged: (value) {
///     setState(() {
///       _searchQuery = value;
///       _filterItems();
///     });
///   },
///   onSearchTap: () {
///     setState(() => _isSearchActive = true);
///   },
///   onSearchClear: () {
///     setState(() {
///       _isSearchActive = false;
///     });
///   },
///   searchPlaceholder: 'Search settings',
/// )
/// ```
///
/// Note: This component should typically be placed in a Stack as a Positioned widget,
/// with content in a scrollable container below it that uses the same ScrollController.
class SearchHeader extends ConsumerStatefulWidget {
  /// The title displayed in the center of the header.
  final String title;

  /// Whether to show the back button.
  final bool showBackButton;

  /// Callback for when the search query changes.
  final void Function(String) onSearchChanged;

  /// Callback for when the search bar is tapped.
  final VoidCallback? onSearchTap;

  /// Callback for when the clear button in the search bar is tapped.
  final VoidCallback? onSearchClear;

  /// Callback for when search is submitted.
  final void Function(String)? onSearchSubmitted;

  /// The controller for the search text field.
  final TextEditingController searchController;

  /// The scroll controller to track for header blur effects.
  final ScrollController scrollController;

  /// Height of the header including the status bar area and search bar.
  final double height;

  /// Custom widget to be shown at the right side of the header bar.
  final Widget? trailing;

  /// Placeholder text for the search bar.
  final String searchPlaceholder;

  /// Alternative parameter for search placeholder (for backward compatibility)
  final String? searchHint;

  /// Whether search functionality is currently active
  final bool? isSearchActive;

  /// Callback when search button is pressed
  final VoidCallback? onSearchButtonPressed;

  /// Custom leading button widget
  final Widget? leadingButton;

  /// Custom trailing button widget
  final Widget? trailingButton;

  /// Whether to apply responsive margins to search bar for web only
  final bool useResponsiveMargins;

  const SearchHeader({
    super.key,
    required this.title,
    required this.searchController,
    required this.scrollController,
    required this.onSearchChanged,
    this.showBackButton = true,
    this.onSearchTap,
    this.onSearchClear,
    this.onSearchSubmitted,
    this.height = 120,
    this.trailing,
    this.searchPlaceholder = 'Search',
    this.searchHint,
    this.isSearchActive,
    this.onSearchButtonPressed,
    this.leadingButton,
    this.trailingButton,
    this.useResponsiveMargins = false,
  });

  @override
  ConsumerState<SearchHeader> createState() => _SearchHeaderState();
}

class _SearchHeaderState extends ConsumerState<SearchHeader> {
  // Glass effect values
  double _headerOpacity = 0.25; // Start with minimal opacity
  double _blurValue = 5.0; // Start with minimal blur

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_updateScrollEffect);

    // Initialize glass effect
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGlassEffect();
    });
  }

  @override
  void dispose() {
    // We don't remove the listener from scrollController since it's passed from parent
    // and may still be used elsewhere
    super.dispose();
  }

  // Initialize the glass effect
  void _initializeGlassEffect() {
    if (!mounted) return;

    setState(() {
      _headerOpacity = 0.25;
      _blurValue = 5.0;
    });
  }

  // Method to update header glass effect based on scroll position
  void _updateScrollEffect() {
    if (!mounted) return;

    final double scrollPosition = widget.scrollController.position.pixels;

    // Start with minimal values when at the top and increase as we scroll
    double newOpacity =
        0.25 + (scrollPosition / 500.0) * 0.6; // Range: 0.25-0.85
    double newBlur = 5.0 +
        (1 - math.exp(-scrollPosition / 200)) * 25.0; // Non-linear increase

    // Clamp values to appropriate ranges for iOS-style glass
    newOpacity = newOpacity.clamp(0.25, 0.85);
    newBlur = newBlur.clamp(5.0, 30.0);

    // Only update state if values have changed significantly
    if ((newOpacity - _headerOpacity).abs() > 0.01 ||
        (newBlur - _blurValue).abs() > 0.1) {
      setState(() {
        _headerOpacity = newOpacity;
        _blurValue = newBlur;
      });
    }
  }

  /// Calculate responsive horizontal margin for web platforms
  double _calculateResponsiveMargin(BuildContext context) {
    if (!kIsWeb || !widget.useResponsiveMargins) {
      return 16.0; // Default margin for mobile or when disabled
    }

    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth > 1200) {
      // Large screens: significant margins
      return (screenWidth - 800) / 2;
    } else if (screenWidth > 768) {
      // Medium screens: moderate margins
      return (screenWidth - 600) / 2;
    } else {
      // Small screens: minimal margins
      return 24.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final contentHeight = widget.height;
    final colors = ref.watch(themeColorsProvider);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: _blurValue, sigmaY: _blurValue),
          child: Container(
            height: statusBarHeight + contentHeight,
            child: Column(
              children: [
                // Status bar space
                SizedBox(height: statusBarHeight),

                // Navigation bar
                SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      if (widget.showBackButton)
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: CustomBackButton(
                            color: colors.primaryText,
                          ),
                        )
                      else if (widget.leadingButton != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: widget.leadingButton!,
                        )
                      else
                        const SizedBox(width: 64), // Match the right side width
                      Expanded(
                        child: Center(
                          child: Text(
                            widget.title,
                            style: GoogleFonts.inter(
                              color: colors.primaryText,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ),
                      if (widget.trailingButton != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: widget.trailingButton!,
                        )
                      else if (widget.trailing != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: widget.trailing!,
                        )
                      else
                        const SizedBox(width: 64),
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: EdgeInsets.fromLTRB(_calculateResponsiveMargin(context), 8, _calculateResponsiveMargin(context), 16),
                  child: ClipSmoothRect(
                    radius: SmoothBorderRadius(
                      cornerRadius: 16,
                      cornerSmoothing: 1,
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        decoration: ShapeDecoration(
                          color: colors.searchBarBackground,
                          shape: SmoothRectangleBorder(
                            borderRadius: SmoothBorderRadius(
                              cornerRadius: 16,
                              cornerSmoothing: 1,
                            ),
                            side: BorderSide(
                              color: colors.primaryBorder
                                  .withAlpha(51), // 0.2 * 255 = ~51
                              width: 1,
                            ),
                          ),
                        ),
                        child: CupertinoSearchTextField(
                          controller: widget.searchController,
                          onTap: widget.onSearchTap,
                          onSuffixTap: () {
                            widget.searchController.clear();
                            if (widget.onSearchClear != null) {
                              widget.onSearchClear!();
                            }
                            // Clear focus to dismiss keyboard
                            FocusManager.instance.primaryFocus?.unfocus();
                          },
                          onChanged: widget.onSearchChanged,
                          onSubmitted: widget.onSearchSubmitted ??
                              (_) {
                                // Clear focus on submission to dismiss keyboard
                                FocusManager.instance.primaryFocus?.unfocus();
                              },
                          style: GoogleFonts.inter(
                            color: colors.primaryText,
                            fontSize: 17,
                            letterSpacing: -0.3,
                          ),
                          placeholder: widget.searchPlaceholder,
                          placeholderStyle: GoogleFonts.inter(
                            color: colors.placeholderText,
                            fontSize: 17,
                            letterSpacing: -0.3,
                          ),
                          backgroundColor: const Color(0x00000000),
                          itemColor: colors.secondaryText,
                          prefixInsets:
                              const EdgeInsets.only(left: 8, right: 4),
                          suffixInsets: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
