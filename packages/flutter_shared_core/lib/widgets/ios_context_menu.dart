import 'dart:ui';
import 'package:flutter_shared_core/utils/app_logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show Colors; // Import only Colors from Material
import 'package:google_fonts/google_fonts.dart'; // Add this import for Inter font
import 'package:flutter/services.dart'; // Import for haptic feedback
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Add Riverpod support
import 'package:flutter_shared_core/theme/providers/theme_provider.dart'; // Add theme provider
import 'package:figma_squircle/figma_squircle.dart'; // Add squircle support

class IOSContextMenuItem {
  final String text;
  final IconData icon;
  final Color? textColor; // Make colors nullable for theme support
  final Color? iconColor;
  final VoidCallback onPressed;
  final bool isDestructive; // iOS-style destructive action with separator
  final bool isGroupStart; // Start of a new group with thick separator

  const IOSContextMenuItem({
    required this.text,
    required this.icon,
    required this.onPressed,
    this.textColor, // Remove default color
    this.iconColor, // Remove default color
    this.isDestructive = false, // Default to false for non-destructive actions
    this.isGroupStart = false, // Default to false for regular items
  });
}

class IOSContextMenu extends ConsumerStatefulWidget {
  final List<IOSContextMenuItem> items;
  final double width;
  final Offset position;
  final Size buttonSize;
  final VoidCallback onDismiss;
  final bool showAboveButton; // Option to show above button instead of below

  const IOSContextMenu({
    super.key,
    required this.items,
    required this.position,
    required this.buttonSize,
    required this.onDismiss,
    this.width = 220,
    this.showAboveButton = false,
  });

  @override
  ConsumerState<IOSContextMenu> createState() => _IOSContextMenuState();
}

class _IOSContextMenuState extends ConsumerState<IOSContextMenu>
    with SingleTickerProviderStateMixin {
  // Animation controller for the menu
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  // Tracks if menu is being dismissed
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller with iOS 18-like spring curve
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    // Scale animation that starts slightly smaller and springs to full size
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.9, end: 1.02)
            .chain(CurveTween(curve: Curves.easeOutExpo)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.02, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(_animationController);

    // Opacity animation for fade-in effect
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    ));

    // Start the animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Handle dismissal with animation
  Future<void> _dismiss() async {
    if (_isDismissing) return;

    setState(() {
      _isDismissing = true;
    });

    // Reverse the animation and wait for completion
    await _animationController.reverse();
    
    if (mounted) {
      widget.onDismiss();
    }

    // Add subtle haptic feedback on dismiss
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(themeColorsProvider);
    final isLightTheme = colors.primaryBackground != const Color(0xFF111111);
    
    // Calculate the menu position
    final screenSize = MediaQuery.of(context).size;
    final menuWidth = widget.width;

    // Calculate right position to align with button's right edge
    final rightPosition =
        screenSize.width - (widget.position.dx + widget.buttonSize.width);

    // Ensure menu doesn't go off screen
    // Min: 16px from right edge
    // Max: Ensure menu doesn't go too far left (leave space for nav bar + content margin)
    // Typically nav bar is ~80px, so menu shouldn't go further left than ~120px from screen left
    final maxRightPosition = screenSize.width - 120.0 - menuWidth; // Keep menu away from nav bar area
    final adjustedRightPosition =
        rightPosition.clamp(16.0, maxRightPosition);

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _dismiss();
        }
      },
      canPop: false,
      child: Stack(
        children: [
          // Dismissible overlay - full screen tappable area
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: (_) => _dismiss(),
            ),
          ),

          // Animated menu
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              // Calculate positioning based on showAboveButton
              double topPosition;
              Alignment scaleAlignment;
              
              if (widget.showAboveButton) {
                // Calculate menu height for positioning above button
                const menuItemHeight = 42.0; // padding (14*2) + content
                const dividerHeight = 0.5;
                const menuPadding = 8.0; // Container padding
                final estimatedMenuHeight = (widget.items.length * menuItemHeight) + 
                                          ((widget.items.length - 1) * dividerHeight) + 
                                          (menuPadding * 2);
                
                topPosition = widget.position.dy - estimatedMenuHeight - 6; // 6px gap above button
                scaleAlignment = Alignment.bottomRight; // Scale from bottom-right when above
              } else {
                topPosition = widget.position.dy + widget.buttonSize.height + 6; // 6px gap below button
                scaleAlignment = Alignment.topRight; // Scale from top-right when below
              }
              
              return Positioned(
                top: topPosition,
                right: adjustedRightPosition,
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    alignment: scaleAlignment, // Use calculated alignment
                    child: child,
                  ),
                ),
              );
            },
            child: ClipSmoothRect(
              radius: SmoothBorderRadius(
                cornerRadius: 16, // Match QR card corner radius
                cornerSmoothing: 0.8, // Match QR card smoothing
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                    sigmaX: 40, sigmaY: 40), // iOS 18 uses stronger blur
                child: Container(
                  width: menuWidth,
                  decoration: ShapeDecoration(
                    // iOS 18 context menu background with theme support
                    color: isLightTheme
                        ? colors.cardBackground.withAlpha((0.95 * 255).round()) // Light theme: slightly transparent card background
                        : const Color(0xE0212121), // Dark theme: keep existing dark background
                    shape: SmoothRectangleBorder(
                      borderRadius: SmoothBorderRadius(
                        cornerRadius: 16, // Match QR card corner radius
                        cornerSmoothing: 0.8, // Match QR card smoothing
                      ),
                      side: BorderSide(
                        color: isLightTheme
                            ? colors.primaryBorder.withAlpha((0.3 * 255).round()) // Light theme: visible border
                            : CupertinoColors.white.withAlpha(38), // Dark theme: subtle white border
                        width: 0.5,
                      ),
                    ),
                    // Add subtle shadow for iOS 18 style
                    shadows: [
                      BoxShadow(
                        color: isLightTheme
                            ? colors.shadowColor.withAlpha((0.2 * 255).round()) // Light theme: subtle shadow
                            : Colors.black.withAlpha(77), // Dark theme: stronger shadow
                        blurRadius: isLightTheme ? 12 : 16, // Lighter blur for light theme
                        spreadRadius: isLightTheme ? 0 : 1, // Less spread for light theme
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: widget.items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;

                      return Column(
                        children: [
                          if (index > 0)
                            _buildSeparator(item, index, isLightTheme, colors),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () async {
                              await _dismiss();
                              item.onPressed();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal:
                                    18, // iOS 18 uses slightly more horizontal padding
                                vertical:
                                    14, // iOS 18 uses slightly more vertical padding
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item.text,
                                    style: GoogleFonts.inter(
                                      textStyle: TextStyle(
                                        color: item.textColor ?? (isLightTheme 
                                            ? colors.primaryText // Light theme: dark text
                                            : CupertinoColors.white), // Dark theme: white text
                                        fontSize:
                                            17, // iOS 18 uses slightly larger font
                                        fontWeight: FontWeight
                                            .w500, // Medium weight for iOS 18
                                        letterSpacing:
                                            -0.4, // Tighter letter spacing for iOS 18
                                        height: 1.2, // Adjusted line height
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    item.icon,
                                    color: item.iconColor ?? (isLightTheme 
                                        ? colors.primaryText // Light theme: dark icon
                                        : CupertinoColors.white), // Dark theme: white icon
                                    size:
                                        20, // iOS 18 uses slightly larger icons
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build appropriate separator based on item type (regular vs destructive vs group start)
  Widget _buildSeparator(IOSContextMenuItem item, int index, bool isLightTheme, dynamic colors) {
    final isFirstDestructiveAction = item.isDestructive && 
        (index == 0 || !widget.items[index - 1].isDestructive);
    final needsThickSeparator = isFirstDestructiveAction || item.isGroupStart;
    
    if (needsThickSeparator) {
      // iOS-style thicker separator before destructive actions or group starts
      return Container(
        height: 6.0, // Thicker separator for destructive actions and group starts
        margin: const EdgeInsets.symmetric(vertical: 2.0), // Add spacing around it
        decoration: BoxDecoration(
          color: isLightTheme
              ? colors.secondaryBorder // Light theme: same as thin separator
              : CupertinoColors.white.withAlpha(31), // Dark theme: same as thin separator
        ),
      );
    } else {
      // Regular thin separator between normal items
      return Container(
        height: 0.5,
        decoration: BoxDecoration(
          color: isLightTheme
              ? colors.secondaryBorder // Light theme: use secondary border
              : CupertinoColors.white.withAlpha(31), // Dark theme: subtle white divider
        ),
      );
    }
  }
}

// Helper function to show the context menu using overlay (for modals)
OverlayEntry? showIOSContextMenuOverlay({
  required BuildContext context,
  required List<IOSContextMenuItem> items,
  required Offset position,
  required Size buttonSize,
  double width = 220,
  VoidCallback? onMenuDismissed,
  bool showAboveButton = false, // Option to show above button instead of below
}) {
  AppLogger.log('🎯 iOS Context Menu Overlay: showIOSContextMenuOverlay called');
  AppLogger.log('🎯 iOS Context Menu Overlay: Position: $position, ButtonSize: $buttonSize');
  AppLogger.log('🎯 iOS Context Menu Overlay: Items count: ${items.length}');
  AppLogger.log('🎯 iOS Context Menu Overlay: Context mounted: ${context.mounted}');
  
  // Light haptic feedback when menu appears - matches iOS behavior
  HapticFeedback.selectionClick();

  OverlayEntry? overlayEntry;
  
  overlayEntry = OverlayEntry(
    builder: (context) {
      AppLogger.log('🎯 iOS Context Menu Overlay: OverlayEntry builder called, creating IOSContextMenu widget');
      return IOSContextMenu(
        items: items,
        position: position,
        buttonSize: buttonSize,
        width: width,
        showAboveButton: showAboveButton, // Pass the positioning parameter
        onDismiss: () {
          AppLogger.log('🎯 iOS Context Menu Overlay: onDismiss called, removing overlay');
          overlayEntry?.remove();
          overlayEntry = null;
          // Notify the caller that the menu was dismissed
          onMenuDismissed?.call();
        },
      );
    },
  );

  AppLogger.log('🎯 iOS Context Menu Overlay: About to insert overlay...');
  try {
    // Use root navigator's overlay to ensure context menu appears above navigation bar
    // This follows the same pattern as static_overlay_modal.dart
    final NavigatorState rootNavigator = Navigator.of(context, rootNavigator: true);
    if (rootNavigator.overlay != null) {
      rootNavigator.overlay!.insert(overlayEntry!);
      AppLogger.log('✅ iOS Context Menu Overlay: Successfully inserted overlay in root navigator');
    } else {
      // Fallback to local overlay if root navigator overlay is null (rare edge case)
      AppLogger.log('⚠️ iOS Context Menu Overlay: Root navigator overlay is null, using local overlay');
      Overlay.of(context).insert(overlayEntry!);
    }
    return overlayEntry;
  } catch (e) {
    AppLogger.log('❌ iOS Context Menu Overlay: Error inserting overlay: $e');
    // Fallback to local overlay as last resort
    try {
      Overlay.of(context).insert(overlayEntry!);
      AppLogger.log('✅ iOS Context Menu Overlay: Fallback to local overlay succeeded');
      return overlayEntry;
    } catch (fallbackError) {
      AppLogger.log('❌ iOS Context Menu Overlay: Fallback also failed: $fallbackError');
      overlayEntry?.remove();
      overlayEntry = null;
      return null;
    }
  }
}

// Helper function to show the context menu using navigator (for regular screens)
Future<void> showIOSContextMenu({
  required BuildContext context,
  required List<IOSContextMenuItem> items,
  required Offset position,
  required Size buttonSize,
  double width = 220,
}) {
  AppLogger.log('🎯 iOS Context Menu: showIOSContextMenu called');
  AppLogger.log('🎯 iOS Context Menu: Position: $position, ButtonSize: $buttonSize');
  AppLogger.log('🎯 iOS Context Menu: Items count: ${items.length}');
  AppLogger.log('🎯 iOS Context Menu: Context mounted: ${context.mounted}');
  
  // Light haptic feedback when menu appears - matches iOS behavior
  HapticFeedback.selectionClick();

  AppLogger.log('🎯 iOS Context Menu: About to push Navigator route...');
  return Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors
          .transparent, // Transparent barrier, we'll handle blur in HomeScreen
      barrierDismissible: true,
      transitionDuration: Duration.zero, // Let our custom animation handle this
      reverseTransitionDuration:
          Duration.zero, // Let our custom animation handle this
      pageBuilder: (context, _, __) {
        AppLogger.log('🎯 iOS Context Menu: pageBuilder called, creating IOSContextMenu widget');
        return IOSContextMenu(
          items: items,
          position: position,
          buttonSize: buttonSize,
          width: width,
          onDismiss: () {
            AppLogger.log('🎯 iOS Context Menu: onDismiss called, closing menu');
            Navigator.pop(context);
          },
        );
      },
    ),
  ).then((result) {
    AppLogger.log('🎯 iOS Context Menu: Navigator route completed with result: $result');
  }).catchError((error) {
    AppLogger.log('❌ iOS Context Menu: Navigator route error: $error');
  });
}
