import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material, Colors;
import 'package:flutter/services.dart'; // Required for HapticFeedback
import 'dart:math' as math;
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';

/// A generic class for picker items to be used with [ItemPicker]
class PickerItem<T> {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final String? imageEmoji;
  final T value;

  PickerItem({
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.imageEmoji,
    required this.value,
  });
}

/// A reusable fullscreen picker that displays items with search and alphabetical index
class ItemPicker<T> extends StatefulWidget {
  /// Callback when an item is selected
  final void Function(PickerItem<T> item) onItemSelected;

  /// List of all items to display
  final List<PickerItem<T>> items;

  /// List of suggested items to display at the top
  final List<PickerItem<T>>? suggestedItems;

  /// The currently selected value
  final T? selectedValue;

  /// Title for the navigation bar
  final String title;

  /// Custom item builder for rendering each item
  final Widget Function(PickerItem<T> item, bool isSelected, bool isLast)?
      itemBuilder;

  /// Whether to group items alphabetically
  final bool groupAlphabetically;

  /// Whether to show the alphabetical index
  final bool showAlphabeticalIndex;

  /// Callback when the picker is dismissed
  final VoidCallback? onDismiss;

  const ItemPicker({
    super.key,
    required this.onItemSelected,
    required this.items,
    this.suggestedItems,
    this.selectedValue,
    required this.title,
    this.itemBuilder,
    this.groupAlphabetically = true,
    this.showAlphabeticalIndex = true,
    this.onDismiss,
  });

  @override
  State<ItemPicker<T>> createState() => _ItemPickerState<T>();
}

class _ItemPickerState<T> extends State<ItemPicker<T>> {
  late TextEditingController _searchController;
  List<PickerItem<T>> _filteredItems = [];
  Map<String, List<PickerItem<T>>> _groupedItems = {};
  bool _isSearching = false;
  final _scrollController = ScrollController();
  String? _currentLetter;

  // List of all possible section titles (A-Z)
  final List<String> _indexList = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z'
  ];

  final Map<String, GlobalKey> _sectionKeys = {};

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _initializeItems();

    // Initialize section keys
    for (final letter in _indexList) {
      _sectionKeys[letter] = GlobalKey(debugLabel: letter);
    }
    _sectionKeys['SUGGESTIONS'] = GlobalKey(debugLabel: 'SUGGESTIONS');
  }

  void _initializeItems() {
    _filteredItems = widget.items;
    _groupItems(_filteredItems);
  }

  void _groupItems(List<PickerItem<T>> items) {
    _groupedItems = {};
    if (widget.groupAlphabetically) {
      for (var item in items) {
        final letter = item.title[0].toUpperCase();
        if (!_groupedItems.containsKey(letter)) {
          _groupedItems[letter] = [];
        }
        _groupedItems[letter]!.add(item);
      }
      // Sort items within each group
      _groupedItems.forEach((key, value) {
        value.sort((a, b) => a.title.compareTo(b.title));
      });
    } else {
      // No grouping, just add all items under a single key
      _groupedItems['ALL'] = items;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _jumpToLetter(String letter, {bool updateFeedback = true}) {
    if (!mounted) return;

    // Find the key for this letter
    final key = _sectionKeys[letter];
    if (key?.currentContext == null) return;

    // Get the RenderBox of the section
    final RenderBox renderBox =
        key!.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero).dy;

    // Get the RenderBox of the ListView
    final RenderBox listViewBox = _scrollController
        .position.context.notificationContext!
        .findRenderObject() as RenderBox;
    final listViewPosition = listViewBox.localToGlobal(Offset.zero).dy;

    // Calculate the scroll offset needed
    final scrollTo = _scrollController.offset +
        (position - listViewPosition) -
        96.0; // Account for nav bar + search

    if (mounted) {
      _scrollController.animateTo(
        math.max(0, scrollTo),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }

    if (updateFeedback) {
      setState(() {
        _currentLetter = letter;
      });
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _currentLetter = null);
      }
    });
  }

  Widget _buildLetterBubble() {
    if (_currentLetter == null) return const SizedBox.shrink();

    return Positioned(
      right: 40,
      top: MediaQuery.of(context).size.height / 2 - 40,
      child: AnimatedOpacity(
        opacity: _currentLetter != null ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2E),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Center(
            child: Text(
              _currentLetter!,
              style: GoogleFonts.inter(
                color: CupertinoColors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _filterItems(String query) {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _filteredItems = widget.items;
        _groupItems(_filteredItems);
      });
      return;
    }

    final searchQuery = query.toLowerCase();
    final List<PickerItem<T>> searchResults = [];

    // Search in all items
    for (var item in widget.items) {
      if (item.title.toLowerCase().contains(searchQuery) ||
          (item.subtitle != null &&
              item.subtitle!.toLowerCase().contains(searchQuery))) {
        searchResults.add(item);
      }
    }

    setState(() {
      _isSearching = true;
      _filteredItems = searchResults
        ..sort((a, b) => a.title.compareTo(b.title));
      _groupItems(_filteredItems);
    });
  }

  Widget _buildSectionHeader(String title) {
    // Skip section headers if we're not grouping alphabetically
    if (!widget.groupAlphabetically && title == 'ALL') {
      return SizedBox(key: _sectionKeys[title]);
    }

    return Container(
      key: _sectionKeys[title],
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      color: const Color(0xFF1C1C1E),
      child: Text(
        title,
        style: GoogleFonts.inter(
          color: CupertinoColors.systemGrey.withAlpha(166), // ~65% opacity
          fontSize: 12,
          letterSpacing: 0.2,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDefaultItemTile(
      PickerItem<T> item, bool isSelected, bool isLast) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        border: Border(
          bottom: !isLast
              ? BorderSide(
                  color:
                      CupertinoColors.systemGrey.withAlpha(51), // ~20% opacity
                  width: 0.5,
                )
              : BorderSide.none,
        ),
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          widget.onItemSelected(item);
          if (widget.onDismiss != null) {
            widget.onDismiss!();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              if (item.imageEmoji != null) ...[
                Text(item.imageEmoji!, style: GoogleFonts.inter(fontSize: 22)),
                const SizedBox(width: 12),
              ] else if (item.icon != null) ...[
                Icon(
                  item.icon,
                  color: item.iconColor ?? CupertinoColors.white,
                  size: 22,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  item.title,
                  style: GoogleFonts.inter(
                    color: CupertinoColors.white,
                    fontSize: 17,
                  ),
                ),
              ),
              if (item.subtitle != null) ...[
                Text(
                  item.subtitle!,
                  style: GoogleFonts.inter(
                    color: CupertinoColors.white.withAlpha(153), // ~60% opacity
                    fontSize: 17,
                  ),
                ),
              ],
              if (isSelected) ...[
                const SizedBox(width: 8),
                const Icon(
                  CupertinoIcons.checkmark_alt,
                  color: CupertinoColors.activeBlue,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndexList() {
    if (!widget.showAlphabeticalIndex || !widget.groupAlphabetically) {
      return const SizedBox.shrink();
    }

    final availableLetters = _indexList
        .where((letter) =>
            _groupedItems.containsKey(letter) &&
            _groupedItems[letter]!.isNotEmpty)
        .toList();

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 44.0, // iOS standard touch target
        margin: const EdgeInsets.only(right: 0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const itemHeight = 18.0; // Standard iOS size
            final totalHeight = itemHeight * availableLetters.length;
            final topPadding = (constraints.maxHeight - totalHeight) / 2;

            return Stack(
              children: [
                // Touch area
                Positioned.fill(
                  child: Container(
                    color: CupertinoColors.black
                        .withAlpha(1), // Very transparent touch target
                  ),
                ),
                // Letters
                Positioned(
                  top: topPadding,
                  right: 0,
                  width: 20,
                  height: totalHeight,
                  child: Column(
                    children: [
                      ...availableLetters.map((letter) => SizedBox(
                            height: itemHeight,
                            child: Center(
                              child: Text(
                                letter,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: _currentLetter == letter
                                      ? CupertinoColors.systemBlue
                                      : CupertinoColors.systemGrey,
                                ),
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
                // Touch detector
                Positioned.fill(
                  child: GestureDetector(
                    behavior:
                        HitTestBehavior.opaque, // Important for reliable touch
                    onVerticalDragUpdate: (details) {
                      final localPosition = details.localPosition;
                      final adjustedPosition = localPosition.dy - topPadding;
                      final index = (adjustedPosition / itemHeight)
                          .clamp(0.0, availableLetters.length - 1)
                          .floor();
                      if (index >= 0 && index < availableLetters.length) {
                        final letter = availableLetters[index];
                        if (_currentLetter != letter) {
                          _jumpToLetter(letter);
                          HapticFeedback.selectionClick();
                        }
                      }
                    },
                    onVerticalDragEnd: _onVerticalDragEnd,
                    onTapDown: (details) {
                      final localPosition = details.localPosition;
                      final adjustedPosition = localPosition.dy - topPadding;
                      final index = (adjustedPosition / itemHeight)
                          .clamp(0.0, availableLetters.length - 1)
                          .floor();
                      if (index >= 0 && index < availableLetters.length) {
                        final letter = availableLetters[index];
                        _jumpToLetter(letter);
                        HapticFeedback.selectionClick();
                      }
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<MapEntry<String, List<PickerItem<T>>>> sections = [];

    if (_isSearching) {
      sections = _groupedItems.entries.toList();
    } else {
      if (widget.suggestedItems != null && widget.suggestedItems!.isNotEmpty) {
        sections.add(MapEntry('SUGGESTIONS', widget.suggestedItems!));
      }
      sections.addAll(_groupedItems.entries.where((e) => e.value.isNotEmpty));
    }

    return Material(
      color: Colors.transparent,
      child: CupertinoPageScaffold(
        backgroundColor: const Color(0xFF1C1C1E),
        navigationBar: CupertinoNavigationBar(
          backgroundColor: const Color(0xFF1C1C1E),
          border: null,
          middle: Text(
            widget.title,
            style: GoogleFonts.inter(color: CupertinoColors.white),
          ),
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: widget.onDismiss,
            child: const Icon(
              CupertinoIcons.xmark,
              color: CupertinoColors.white,
            ),
          ),
        ),
        child: Column(
          children: [
            Container(
              color: const Color(0xFF1C1C1E),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: CupertinoSearchTextField(
                controller: _searchController,
                onChanged: _filterItems,
                style: GoogleFonts.inter(color: CupertinoColors.white),
                placeholder: 'Search',
                placeholderStyle: TextStyle(
                  color: CupertinoColors.white.withAlpha(153), // ~60% opacity
                ),
                backgroundColor: const Color(0xFF2C2C2E),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.zero, // Remove all padding
                    itemCount: sections.length,
                    itemBuilder: (context, sectionIndex) {
                      final section = sections[sectionIndex];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(section.key),
                          ...section.value.asMap().entries.map((entry) {
                            final isSelected = widget.selectedValue != null &&
                                entry.value.value == widget.selectedValue;
                            final isLast =
                                entry.key == section.value.length - 1;

                            return widget.itemBuilder != null
                                ? widget.itemBuilder!(
                                    entry.value, isSelected, isLast)
                                : _buildDefaultItemTile(
                                    entry.value, isSelected, isLast);
                          }),
                        ],
                      );
                    },
                  ),
                  if (!_isSearching &&
                      widget.showAlphabeticalIndex &&
                      widget.groupAlphabetically) ...[
                    Positioned(
                      right: 2,
                      top: 0,
                      bottom: 0,
                      child: _buildIndexList(),
                    ),
                    _buildLetterBubble(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The overlay entry for the item picker
OverlayEntry? _itemPickerOverlayEntry;

/// Shows an item picker overlay that appears on top of the current content
Future<T?> showItemPicker<T>({
  required BuildContext context,
  required List<PickerItem<T>> items,
  List<PickerItem<T>>? suggestedItems,
  void Function(PickerItem<T>)? onItemSelected,
  T? selectedValue,
  required String title,
  Widget Function(PickerItem<T>, bool, bool)? itemBuilder,
  bool groupAlphabetically = true,
  bool showAlphabeticalIndex = true,
}) async {
  // Remove existing overlay if any
  _itemPickerOverlayEntry?.remove();
  _itemPickerOverlayEntry = null;

  // Create a completer to handle the async return
  final Completer<T?> completer = Completer<T?>();

  // Flag to prevent multiple completions
  bool isCompleted = false;

  // Function to close the picker and complete the future
  void closeAndComplete(T? value) {
    if (isCompleted) return;
    isCompleted = true;

    _closeItemPicker();
    completer.complete(value);
  }

  _itemPickerOverlayEntry = OverlayEntry(
    builder: (context) => GestureDetector(
      onTap: () {
        // Close on tap outside
        closeAndComplete(null);
      },
      // Full screen modal with animation
      child: AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          color: Colors.black.withAlpha(200), // Semi-transparent background
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: GestureDetector(
            onTap: () {}, // Prevent taps from closing the modal
            behavior: HitTestBehavior.opaque,
            child: ItemPicker<T>(
              items: items,
              suggestedItems: suggestedItems,
              onItemSelected: (item) {
                if (onItemSelected != null) {
                  onItemSelected(item);
                }
                closeAndComplete(item.value);
              },
              selectedValue: selectedValue,
              title: title,
              itemBuilder: itemBuilder,
              groupAlphabetically: groupAlphabetically,
              showAlphabeticalIndex: showAlphabeticalIndex,
              onDismiss: () {
                closeAndComplete(null);
              },
            ),
          ),
        ),
      ),
    ),
  );

  Overlay.of(context).insert(_itemPickerOverlayEntry!);

  return completer.future;
}

void _closeItemPicker() {
  if (_itemPickerOverlayEntry != null) {
    _itemPickerOverlayEntry!.remove();
    _itemPickerOverlayEntry = null;
  }
}
