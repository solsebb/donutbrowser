import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Material;
import 'package:flutter/services.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_shared_core/theme/providers/theme_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Define the height for the modal
const double kModalFixedHeight = 253.0;

// Animation duration for smooth transitions
const Duration kAnimationDuration = Duration(milliseconds: 250);

// Physics constants for iOS 18-style dragging
const double kDismissThreshold = 0.2; // Dismiss when dragged 20% of height
const double kUpwardResistance = 0.8; // More resistance for upward drag
const double kDownwardResistance = 0.7; // Less resistance for downward drag
const double kMaxHeightExtension =
    200.0; // Maximum height extension when dragging up
// const Curve kSnapCurve = Curves.easeOutCubic; // Not used for spring
// const Duration kSnapDuration = Duration(milliseconds: 300); // Not used for spring

// Spring physics parameters (these will need tuning)
const double kSpringMass = 0.8;
const double kSpringStiffness = 180.0;
const double kSpringDampingRatio =
    0.65; // < 1.0 for some bounce, 0.7-0.8 for less bounce

/// Callback type for drag updates
typedef OnDragUpdateCallback = void Function(
    double dragOffset, double heightExtension);

/// A specialized key type to avoid exposing private state classes in public API
typedef DraggableModalKey = GlobalKey<State<DraggableOverlayModal>>;

/// Creates a new unique key for a draggable modal
DraggableModalKey createDraggableModalKey() {
  return GlobalKey<State<DraggableOverlayModal>>();
}

// A fallback key for the legacy version of closeModalWithAnimation
// Helps maintain backward compatibility with existing code
DraggableModalKey _legacySharedModalKey =
    GlobalKey<State<DraggableOverlayModal>>();

/// Method to close a specific modal with animation using its key
/// This version requires a specific modal key
void closeSpecificModalWithAnimation(DraggableModalKey key) {
  if (key.currentState is DraggableOverlayModalState) {
    (key.currentState as DraggableOverlayModalState).closeWithAnimation();
  }
}

// Map to store references to active modals by their keys
// Using GlobalKey<DraggableOverlayModalState> for internal use
final Map<GlobalKey<DraggableOverlayModalState>, bool> _activeModalKeys = {};

/// Legacy version of closeModalWithAnimation without parameters
/// Maintained for backward compatibility with existing code
void closeModalWithAnimation() {
  // Access any active modal in the overlay
  // For modals created with showDraggableOverlayModal, the key is stored in _activeModalKeys
  if (_activeModalKeys.isNotEmpty) {
    final activeKey = _activeModalKeys.keys.last;
    // Cast is safe because we know it's the right type internally
    closeSpecificModalWithAnimation(activeKey as DraggableModalKey);
  } else {
    // Fallback to legacy key if no active keys found
    closeSpecificModalWithAnimation(_legacySharedModalKey);
  }
}

// Function to calculate appropriate modal height based on screen constraints
// and the position of the image container
double calculateModalHeight(BuildContext context, GlobalKey? containerKey,
    {double? customModalHeight}) {
  // Default height if no containerKey is provided
  final double defaultHeight = customModalHeight ?? kModalFixedHeight;

  // Get the screen height
  final screenHeight = MediaQuery.of(context).size.height;
  final bottomSafeArea = MediaQuery.of(context).padding.bottom;

  // If we don't have a container key or its context isn't available, use default
  if (containerKey == null || containerKey.currentContext == null) {
    return defaultHeight;
  }

  // Get the container dimensions and position
  final RenderBox containerBox =
      containerKey.currentContext!.findRenderObject() as RenderBox;
  final containerPosition = containerBox.localToGlobal(Offset.zero);
  final containerBottom = containerPosition.dy + containerBox.size.height;

  // Calculate available space between container bottom and screen bottom
  final availableSpace = screenHeight - containerBottom - bottomSafeArea;

  // Ensure we have at least a minimum height for the modal content
  final double minModalContentHeight = customModalHeight != null
      ? customModalHeight - 52.0 // Subtract header height from custom height
      : 197.0; // Was 170.0
  const double modalHeaderHeight =
      52.0; // Approximate height of the modal header

  // Adjust height to position modal just below the container
  // but ensure it's not less than the minimum height
  return (availableSpace < (minModalContentHeight + modalHeaderHeight))
      ? minModalContentHeight + modalHeaderHeight
      : availableSpace;
}

/// A simplified overlay modal that can be used to display a custom bottom sheet
/// with smooth animations.
class DraggableOverlayModal extends ConsumerStatefulWidget {
  /// Callback when the modal is closed
  final VoidCallback onClose;

  /// The content to display in the modal
  final Widget child;

  /// Optional custom header actions to display on the right side
  final Widget? headerActions;

  /// Optional background gradient colors
  final List<Color>? backgroundColors;

  /// Optional background gradient stops
  final List<double>? backgroundStops;

  /// Whether to allow modal to extend beyond its fixed height when dragging up
  final bool allowUpwardDrag;

  /// Optional container key used to position the modal relative to container
  final GlobalKey? containerKey;

  /// Optional custom height for the modal
  final double? customModalHeight;

  /// Whether to blur the background behind the modal
  final bool blurBackground;

  /// Whether to restrict dragging only to the header section
  final bool headerDragOnly;

  /// Optional callback to notify parent of drag updates
  final OnDragUpdateCallback? onDrag;

  /// Whether to show a dark overlay behind the modal
  final bool showDarkOverlay;

  /// Whether to show the default OK button on the right side
  final bool showOkButton;

  /// Whether to show the close button on the left side
  /// Set to false for hard paywall mode where modal should not be dismissible
  final bool showCloseButton;

  /// Whether to allow drag-to-dismiss behavior
  /// Set to false for hard paywall mode where modal should not be dismissible by dragging
  final bool allowDragToDismiss;

  const DraggableOverlayModal({
    super.key,
    required this.onClose,
    required this.child,
    this.headerActions,
    this.backgroundColors,
    this.backgroundStops,
    this.allowUpwardDrag = true,
    this.containerKey,
    this.customModalHeight,
    this.blurBackground = false,
    this.headerDragOnly = false,
    this.onDrag,
    this.showDarkOverlay = false,
    this.showOkButton = true,
    this.showCloseButton = true,
    this.allowDragToDismiss = true,
  });

  @override
  ConsumerState<DraggableOverlayModal> createState() =>
      DraggableOverlayModalState();
}

class DraggableOverlayModalState extends ConsumerState<DraggableOverlayModal>
    with TickerProviderStateMixin {
  // Animation controller for smooth transitions (initial presentation)
  late AnimationController _animationController;
  // late Animation<double> _slideAnimation; // Removed: Will use _springAnimationController for entry
  late Animation<double> _fadeAnimation;

  // Animation controller for spring-back physics
  late AnimationController _springAnimationController;
  SpringSimulation? _springSimulation; // To store the current simulation

  // Variables for iOS 18-style drag-to-dismiss
  double _dragOffset = 0.0;
  double _heightExtension = 0.0; // Track height extension when dragging up
  bool _isDragging = false; // True if user is actively dragging
  bool _isAnimatingSpring = false; // True if spring animation is running
  bool _isAnimatingSpringForDragOffset = false;
  bool _isAnimatingSpringForHeightExtension = false;

  int _activeAnimationId = 0; // ID to track the currently intended animation

  @override
  void initState() {
    super.initState();

    // Initialize animation controller for fade
    _animationController = AnimationController(
      vsync: this,
      duration: kAnimationDuration,
    );

    // Initialize spring animation controller
    _springAnimationController = AnimationController.unbounded(vsync: this);
    _springAnimationController.addListener(() {
      if (!_isAnimatingSpring) return; // Only update if spring is active
      setState(() {
        if (_isAnimatingSpringForDragOffset) {
          _dragOffset = _springAnimationController.value;
        } else if (_isAnimatingSpringForHeightExtension) {
          _heightExtension = _springAnimationController.value;
        }
        // Call onDrag callback
        widget.onDrag?.call(_dragOffset, _heightExtension);
      });
    });

    // Slide animation from bottom - REMOVED
    // _slideAnimation = Tween<double>(
    //   begin: 100.0, // Start slightly offscreen
    //   end: 0.0,
    // ).animate(CurvedAnimation(
    //   parent: _animationController,
    //   curve: Curves.easeOutCubic,
    //   reverseCurve: Curves.easeInCubic,
    // ));

    // Fade animation for smoother appearance
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Start the entrance animation
    _animationController.forward(); // Starts fade-in

    // Initialize _dragOffset for spring-in animation from bottom
    // Using a fixed value like 250.0 to ensure it starts off-screen.
    // This value will be animated to 0.0 by the spring.
    _dragOffset = 250.0;

    // Start the spring animation for entry
    _isAnimatingSpring = true;
    _isAnimatingSpringForDragOffset = true;
    _isAnimatingSpringForHeightExtension =
        false; // Not animating height extension on entry

    final SpringDescription spring = SpringDescription.withDampingRatio(
      mass: kSpringMass,
      stiffness: kSpringStiffness,
      ratio: kSpringDampingRatio,
    );

    // Animate _dragOffset from its initial value (250.0) to 0.0
    _springSimulation = SpringSimulation(
        spring, _dragOffset, 0.0, 0.0); // Initial velocity is 0
    // Ensure the controller's internal value is synchronized if the simulation doesn't set it immediately
    _springAnimationController.value = _dragOffset;

    final int entryAnimationId = ++_activeAnimationId;
    _springAnimationController
        .animateWith(_springSimulation!)
        .whenCompleteOrCancel(() {
      if (mounted && _activeAnimationId == entryAnimationId) {
        setState(() {
          _dragOffset = 0.0; // Ensure final position
          _isAnimatingSpring = false;
          _isAnimatingSpringForDragOffset = false;
          // _isDragging should remain false as this is not a user drag
          // Call onDrag callback
          widget.onDrag?.call(_dragOffset, _heightExtension);
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _springAnimationController.dispose(); // Dispose the new controller
    super.dispose();
  }

  // Method to close the modal with animation - exposed to the global key
  void closeWithAnimation() {
    HapticFeedback.mediumImpact(); // Haptic feedback

    // If any other spring animation (e.g., from drag settling or previous close attempt) is running, stop it.
    if (_isAnimatingSpring) {
      ++_activeAnimationId; // Invalidate completion handlers of previous animations
      _springAnimationController.stop(
          canceled: true); // Ensure it stops and doesn't complete
    }

    // Start the fade-out animation (concurrently with spring and barrier)
    _animationController.reverse();

    // Set up flags and start the dismissal spring animation for _dragOffset
    _isAnimatingSpring = true;
    _isAnimatingSpringForDragOffset = true;
    _isAnimatingSpringForHeightExtension =
        false; // Not affecting height extension during close

    // Configure the spring for dismissal
    final SpringDescription spring = SpringDescription.withDampingRatio(
      mass: kSpringMass,
      stiffness: kSpringStiffness,
      ratio: kSpringDampingRatio,
    );

    // Define the target offset for dismissal (modal moves off-screen downwards)
    const double targetDragOffset = 250.0;

    // Create the spring simulation for _dragOffset.
    _springSimulation =
        SpringSimulation(spring, _dragOffset, targetDragOffset, 0.0);

    // Start the spring animation for _dragOffset.
    _springAnimationController.value = _dragOffset;
    final int dismissalSpringId = ++_activeAnimationId;
    _springAnimationController
        .animateWith(_springSimulation!)
        .whenCompleteOrCancel(() {
      // This callback handles cleanup if the spring animation completes naturally.
      // If the widget is disposed before this, dispose() handles controller cleanup.
      if (mounted && _activeAnimationId == dismissalSpringId) {
        _isAnimatingSpring = false;
        _isAnimatingSpringForDragOffset = false;
        // _dragOffset will be at targetDragOffset due to animation.
        // No need to call widget.onClose() here as it's called immediately below.
      }
    });

    // Call widget.onClose() IMMEDIATELY.
    // This triggers dismissWithAnimation in showDraggableOverlayModal, which starts
    // the barrier animation and then removes the overlayEntry.
    // The modal's own fade-out and spring-out will run concurrently with the barrier.
    widget.onClose();
  }

  // Method to handle drag to dismiss - iOS 18 style
  void _handleDragUpdate(DragUpdateDetails details) {
    // If a spring animation is running, stop it and let the drag take over.
    if (_isAnimatingSpring) {
      _springAnimationController.stop();
      _isAnimatingSpring = false;
      _isAnimatingSpringForDragOffset = false;
      _isAnimatingSpringForHeightExtension = false;
    }

    // If delta is positive, we're dragging downward
    final isDraggingDown = (details.primaryDelta ?? 0.0) > 0;

    // If delta is negative, we're dragging upward
    final isDraggingUp = (details.primaryDelta ?? 0.0) < 0;

    // Handle immediate dragging in any direction based on allowUpwardDrag
    if (isDraggingDown ||
        (_isDragging && isDraggingDown) ||
        (widget.allowUpwardDrag && isDraggingUp)) {
      setState(() {
        _isDragging = true;

        // Apply appropriate resistance based on direction
        if (isDraggingDown) {
          // When dragging down, we need to handle two different cases:
          // 1. If the modal is extended (height extension > 0), reduce the extension first
          // 2. Once extension is 0, start increasing drag offset for dismissal

          if (_heightExtension > 0) {
            // First reduce the height extension (with the same resistance as upward dragging)
            // for a consistent feel when changing directions
            final reductionAmount =
                (details.primaryDelta ?? 0.0) * kUpwardResistance;
            _heightExtension = (_heightExtension - reductionAmount)
                .clamp(0.0, kMaxHeightExtension);

            // Only if height extension is reduced to 0, then start applying drag offset
            if (_heightExtension <= 0) {
              _heightExtension = 0;
              // Calculate remaining delta to apply to drag offset
              final remainingDelta = (_heightExtension == 0)
                  ? (details.primaryDelta ?? 0.0) -
                      (reductionAmount / kUpwardResistance)
                  : 0;

              if (remainingDelta > 0) {
                _dragOffset += remainingDelta * kDownwardResistance;
              }
            }
          } else {
            // Normal downward drag behavior when there's no height extension
            _dragOffset += (details.primaryDelta ?? 0.0) * kDownwardResistance;
          }
        } else if (widget.allowUpwardDrag && isDraggingUp) {
          // For upward drag, if there's any drag offset, reduce it first
          if (_dragOffset > 0) {
            // Reduce drag offset with the same resistance for smooth transition
            final reductionAmount =
                -(details.primaryDelta ?? 0.0) * kDownwardResistance;
            _dragOffset =
                (_dragOffset - reductionAmount).clamp(0.0, double.infinity);

            // Check if there's any delta left after reducing the drag offset
            if (_dragOffset == 0) {
              // Calculate remaining delta for height extension
              // This accounts for the part of the drag that was "absorbed" by reducing the offset
              final remainingDelta = (details.primaryDelta ?? 0.0) +
                  (reductionAmount / kDownwardResistance);

              if (remainingDelta < 0) {
                // Apply remaining upward drag to height extension with progressive resistance
                final progressiveFactor =
                    1 - (_heightExtension / kMaxHeightExtension);
                final extensionDelta =
                    -remainingDelta * kUpwardResistance * progressiveFactor;
                _heightExtension = (_heightExtension + extensionDelta)
                    .clamp(0.0, kMaxHeightExtension);
              }
            }
          } else {
            // Normal upward drag behavior when there's no drag offset
            // Apply progressive resistance based on current extension
            final progressiveFactor =
                1 - (_heightExtension / kMaxHeightExtension);
            final extensionDelta = -(details.primaryDelta ?? 0.0) *
                kUpwardResistance *
                progressiveFactor;
            _heightExtension = (_heightExtension + extensionDelta)
                .clamp(0.0, kMaxHeightExtension);
          }
        }
        // Call onDrag callback
        widget.onDrag?.call(_dragOffset, _heightExtension);
      });
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_isDragging) {
      // Only handle if a drag was in progress
      final modalHeight = calculateModalHeight(context, widget.containerKey,
          customModalHeight: widget.customModalHeight);

      final bool wasAnimatingHeightExtension = _heightExtension > 0;
      final bool wasAnimatingDragOffset = _dragOffset > 0 &&
          !wasAnimatingHeightExtension; // Prioritize height extension release

      // If neither dragOffset nor heightExtension is active, or if it's a tap (no significant velocity)
      // and no displacement, do nothing or treat as a tap if needed.
      // For now, if there's no displacement, we assume it snaps back.
      if (!wasAnimatingHeightExtension &&
          !wasAnimatingDragOffset &&
          details.velocity.pixelsPerSecond.dy == 0) {
        setState(() {
          _isDragging = false; // Reset dragging state
        });
        return;
      }

      // Handle upward drag release (height extension)
      if (wasAnimatingHeightExtension) {
        // Spring back to original height
        HapticFeedback.lightImpact();
        _isAnimatingSpring = true;
        _isAnimatingSpringForHeightExtension = true;
        _isAnimatingSpringForDragOffset = false; // Ensure exclusivity

        final SpringDescription spring = SpringDescription.withDampingRatio(
          mass: kSpringMass,
          stiffness: kSpringStiffness,
          ratio: kSpringDampingRatio,
        );

        // Velocity for spring: if dragging up, velocity.dy is negative.
        // SpringSimulation needs velocity relative to the value being animated.
        // If _heightExtension is positive, a negative details.velocity.pixelsPerSecond.dy
        // means moving towards 0 (helping the spring).
        double springVelocity =
            details.velocity.pixelsPerSecond.dy / 100.0; // Scale as needed

        _springSimulation =
            SpringSimulation(spring, _heightExtension, 0.0, springVelocity);
        final int heightSpringBackId = ++_activeAnimationId;
        _springAnimationController
            .animateWith(_springSimulation!)
            .whenCompleteOrCancel(() {
          if (mounted && _activeAnimationId == heightSpringBackId) {
            setState(() {
              _heightExtension = 0.0; // Ensure final state
              _isAnimatingSpring = false;
              _isAnimatingSpringForHeightExtension = false;
              _isDragging = false; // Drag interaction officially ends
              // Call onDrag callback
              widget.onDrag?.call(_dragOffset, _heightExtension);
            });
          }
        });
        // Don't reset _isDragging or _heightExtension here directly
        return; // Important: return after initiating the spring
      }

      // Handle downward drag release (drag offset)
      if (wasAnimatingDragOffset) {
        // HARD PAYWALL: If allowDragToDismiss is false, NEVER dismiss - always snap back
        final bool isDismissed = widget.allowDragToDismiss &&
            (_dragOffset > modalHeight * kDismissThreshold ||
                details.velocity.pixelsPerSecond.dy >
                    700); // Keep existing dismiss logic

        if (isDismissed) {
          // Haptic feedback is handled by closeWithAnimation.

          // Set _isDragging to false immediately to prevent further drag updates
          // from interfering while the dismiss animation starts.
          if (mounted) {
            setState(() {
              _isDragging = false;
              // _heightExtension can be left as is or reset; the modal is disappearing.
              // _dragOffset will be animated by closeWithAnimation starting from its current value.
              // _isAnimatingSpring flags are managed by closeWithAnimation.
            });
          }

          // Call closeWithAnimation. It will use the current _dragOffset.
          // It handles haptics and resetting its own animation flags.
          closeWithAnimation();
        } else {
          // Snap back to original position using spring
          HapticFeedback.lightImpact();
          _isAnimatingSpring = true;
          _isAnimatingSpringForDragOffset = true;
          _isAnimatingSpringForHeightExtension = false; // Ensure exclusivity

          final SpringDescription spring = SpringDescription.withDampingRatio(
            mass: kSpringMass,
            stiffness: kSpringStiffness,
            ratio: kSpringDampingRatio,
          );

          // Velocity for spring: if dragging down, velocity.dy is positive.
          // SpringSimulation needs velocity relative to the value being animated.
          // If _dragOffset is positive, a positive details.velocity.pixelsPerSecond.dy
          // means moving away from 0 (resisting the spring). So it should be negative for the simulation.
          double springVelocity = details.velocity.pixelsPerSecond.dy / 100.0;

          _springSimulation =
              SpringSimulation(spring, _dragOffset, 0.0, -springVelocity);
          // Ensure controller value is synchronized before starting animation
          _springAnimationController.value = _dragOffset;
          final int dragSpringBackId = ++_activeAnimationId;
          _springAnimationController
              .animateWith(_springSimulation!)
              .whenCompleteOrCancel(() {
            if (mounted && _activeAnimationId == dragSpringBackId) {
              setState(() {
                _dragOffset = 0.0; // Ensure final state
                _isAnimatingSpring = false;
                _isAnimatingSpringForDragOffset = false;
                _isDragging = false; // Drag interaction officially ends
                // Call onDrag callback
                widget.onDrag?.call(_dragOffset, _heightExtension);
              });
            }
          });
          // Don't reset _isDragging or _dragOffset here directly
        }
      } else if (!wasAnimatingHeightExtension && !wasAnimatingDragOffset) {
        // If neither, but there was some interaction, ensure _isDragging is false.
        // This case might be hit if the drag was minimal and didn't exceed thresholds
        // to activate _dragOffset or _heightExtension in a meaningful way before _handleDragEnd.
        setState(() {
          _isDragging = false;
        });
      }
      // Note: _isDragging is set to false inside whenCompleteOrCancel or if no spring is initiated.
    }
  }

  void _handleDragCancel() {
    // If a spring animation is running, stop it.
    if (_isAnimatingSpring) {
      _springAnimationController.stop();
    }
    // Indicate that a new "animation" or state-setting action is taking precedence.
    // This helps ensure that any lingering whenCompleteOrCancel callbacks from
    // previous animations do not unintentionally modify state.
    ++_activeAnimationId; // Still increment to invalidate previous animation completions

    setState(() {
      // Only proceed if this cancel action is still the latest "active animation".
      // This check is implicitly handled by the fact that setState is synchronous
      // regarding the state update within this call, and subsequent calls to
      // _handleDragEnd or initState would increment _activeAnimationId again.
      // However, for clarity and safety, if _activeAnimationId was a parameter,
      // we'd check it: if (_activeAnimationId == cancelActionId)

      _isDragging = false;
      _dragOffset = 0.0;
      _heightExtension = 0.0;
      _isAnimatingSpring = false;
      _isAnimatingSpringForDragOffset = false;
      _isAnimatingSpringForHeightExtension = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get the safe area
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    
    // Get theme colors
    final themeColors = ref.watch(themeColorsProvider);
    final isDarkMode = themeColors.primaryBackground == const Color(0xFF111111);

    // Default background gradient colors - theme aware
    final colors = widget.backgroundColors ??
        (isDarkMode
            ? [
                const Color(0xFF2C2C2E).withAlpha((0.25 * 255)
                    .round()), // Light transparent glass color (match timeline)
                const Color(0xFF2C2C2E).withAlpha((0.1 * 255)
                    .round()), // Very light inner container (match timeline)
              ]
            : [
                themeColors.glassBackground, // Light theme glass background
                themeColors.glassBackgroundDark, // Light theme glass background dark
              ]);

    // Default gradient stops
    final stops = widget.backgroundStops ?? const [0.2, 0.85];

    // Calculate base height plus any drag extension
    final baseHeight = calculateModalHeight(context, widget.containerKey,
        customModalHeight: widget.customModalHeight);
    final modalHeight = baseHeight + _heightExtension;

    // Create the header with drag handle and buttons
    Widget headerSection = Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Drag handle centered in the row
          Positioned(
            top: 0,
            child: Container(
              width: 36.0,
              height: 5.0,
              decoration: ShapeDecoration(
                color: isDarkMode 
                    ? CupertinoColors.systemGrey4.withAlpha(128)
                    : CupertinoColors.systemGrey3.withAlpha(180),
                shape: SmoothRectangleBorder(
                  borderRadius: SmoothBorderRadius(
                    cornerRadius: 2.5,
                    cornerSmoothing: 1.0,
                  ),
                ),
              ),
            ),
          ),

          // Left and right buttons positioned at the corners
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Close button - hidden when showCloseButton is false (hard paywall mode)
              if (widget.showCloseButton)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(44, 44),
                  onPressed: closeWithAnimation,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: themeColors.primaryText.withAlpha(30), // Theme-aware background
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/icons/arrow_2_Rounded_fill.svg',
                        width: 10,
                        height: 10,
                        colorFilter: ColorFilter.mode(
                          themeColors.primaryText.withAlpha(102), // Theme-aware icon color
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(width: 44, height: 44), // Empty spacer to maintain layout
              if (widget.headerActions != null)
                widget.headerActions!
              else if (widget.showOkButton)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(44, 44),
                  onPressed: closeWithAnimation,
                  child: Text(
                    'OK',
                    style: GoogleFonts.inter(
                      color: themeColors.primaryText, // Theme-aware text color
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                const SizedBox(width: 44, height: 44), // Empty spacer to maintain layout
            ],
          ),
        ],
      ),
    );

    // Wrap the header with a GestureDetector if headerDragOnly is true
    if (widget.headerDragOnly) {
      // Create a larger hit area by wrapping headerSection with a Container
      // that adds negative margins to expand the touch target
      final headerWithExpandedTouchArea = Stack(
        children: [
          // Invisible expanded touch area
          Positioned(
            top: -15,
            left: -15,
            right: -15,
            bottom: -25,
            child: Container(
              color: Colors.transparent,
            ),
          ),
          // Original header stays visually unchanged
          headerSection,
        ],
      );

      headerSection = GestureDetector(
        onVerticalDragUpdate: _handleDragUpdate,
        onVerticalDragEnd: _handleDragEnd,
        onVerticalDragCancel: _handleDragCancel,
        behavior: HitTestBehavior.translucent,
        child: headerWithExpandedTouchArea,
      );
    }

    // Build the main modal content
    final modalContent = Container(
      width: double.infinity,
      // Apply consistent squircle corner pattern for top border only
      decoration: ShapeDecoration(
        color: Colors.transparent,
        shape: SmoothRectangleBorder(
          borderRadius: const SmoothBorderRadius.only(
            topLeft: SmoothRadius(
              cornerRadius: 28,
              cornerSmoothing: 0.9,
            ),
            topRight: SmoothRadius(
              cornerRadius: 28,
              cornerSmoothing: 0.9,
            ),
          ),
          side: BorderSide(
            color: isDarkMode
                ? CupertinoColors.white.withAlpha(38)
                : themeColors.primaryBorder,
            width: isDarkMode ? 0.5 : 1.0,
          ),
        ),
      ),
      child: ClipSmoothRect(
        radius: const SmoothBorderRadius.only(
          topLeft: SmoothRadius(
            cornerRadius: 28,
            cornerSmoothing: 0.9,
          ),
          topRight: SmoothRadius(
            cornerRadius: 28,
            cornerSmoothing: 0.9,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            // Dynamically calculate the height based on the available screen space
            // plus any height extension from upward dragging
            height: modalHeight + bottomSafeArea,
            decoration: ShapeDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
                stops: stops,
              ),
              shape: const SmoothRectangleBorder(
                borderRadius: SmoothBorderRadius.only(
                  topLeft: SmoothRadius(
                    cornerRadius: 28,
                    cornerSmoothing: 0.9,
                  ),
                  topRight: SmoothRadius(
                    cornerRadius: 28,
                    cornerSmoothing: 0.9,
                  ),
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top layout with drag handle and buttons
                headerSection,

                // Main content provided by child
                // Use Flexible instead of Expanded to allow content to size itself
                Flexible(
                  fit: FlexFit.loose,
                  child: widget.child,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _dragOffset),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Material(
              color: Colors.transparent,
              child: widget.headerDragOnly
                  ? modalContent // If header drag only, don't wrap entire modal with a GestureDetector
                  : GestureDetector(
                      onVerticalDragUpdate: _handleDragUpdate,
                      onVerticalDragEnd: _handleDragEnd,
                      onVerticalDragCancel: _handleDragCancel,
                      child: modalContent,
                    ),
            ),
          ),
        );
      },
    );
  }
}

/// Helper function to calculate max modal height based on platform
/// Mobile responsive web gets more screen coverage than native iOS
double _getMaxModalHeight(BuildContext context) {
  final screenHeight = MediaQuery.of(context).size.height;
  final screenWidth = MediaQuery.of(context).size.width;

  // Detect mobile responsive web (web platform with mobile screen width)
  final isMobileResponsiveWeb = kIsWeb && screenWidth <= 768;

  if (isMobileResponsiveWeb) {
    // Mobile responsive web: Maximum screen coverage - only 1% gap for drag hint
    return screenHeight * 0.995;
  } else {
    // Native iOS or desktop: Keep existing 90% constraint
    return screenHeight * 0.9;
  }
}

/// Helper function to show a draggable overlay modal
/// This function now includes animation handling for
/// smooth appearance and dismissal.
OverlayEntry? showDraggableOverlayModal({
  required BuildContext context,
  required Widget child,
  Widget? headerActions,
  VoidCallback? onDismiss,
  List<Color>? backgroundColors,
  List<double>? backgroundStops,
  bool allowUpwardDrag = true,
  GlobalKey? containerKey,
  bool dismissOnTapOutside = true,
  double? customModalHeight,
  bool blurBackground = false,
  bool headerDragOnly = false,
  OnDragUpdateCallback? onDrag,
  bool showDarkOverlay = false,
  bool showOkButton = true,
  bool showCloseButton = true,
  bool allowDragToDismiss = true,
}) {
  // Create a unique key for this modal instance
  final modalKey = GlobalKey<DraggableOverlayModalState>();

  // Register this modal key as active
  _activeModalKeys[modalKey] = true;

  // Animate the barrier
  final barrierAnimationController = AnimationController(
    vsync: Navigator.of(context),
    duration: kAnimationDuration,
  );

  // Remove existing overlay if any
  OverlayEntry? overlayEntry;

  // Function to handle dismissal with animation
  void dismissWithAnimation() async {
    // Reverse the barrier animation first
    await barrierAnimationController.reverse();

    // Ensure entry still exists before removing
    if (overlayEntry != null) {
      overlayEntry.remove();

      // Unregister this modal key when it's dismissed
      _activeModalKeys.remove(modalKey);

      if (onDismiss != null) onDismiss();
    }

    // Clean up the controller
    barrierAnimationController.dispose();
  }

  overlayEntry = OverlayEntry(
    maintainState: true,
    opaque: false,
    builder: (context) => Consumer(
      builder: (context, ref, _) {
        // Get theme colors in the overlay context
        final themeColors = ref.watch(themeColorsProvider);
        final isDarkMode = themeColors.primaryBackground == const Color(0xFF111111);
        
        return Stack(
          children: [
            // Dark overlay OR Background blur when enabled
            // They can be used together or separately
            if (showDarkOverlay || blurBackground)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapDown: dismissOnTapOutside
                      ? (_) {
                          HapticFeedback.lightImpact();
                          modalKey.currentState?.closeWithAnimation();
                        }
                      : null,
                  child: AnimatedBuilder(
                    animation: barrierAnimationController,
                    builder: (context, _) {
                      Widget overlayWidget = Container(
                          color: Colors.transparent); // Default transparent

                      if (showDarkOverlay && blurBackground) {
                        overlayWidget = BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: 25 * barrierAnimationController.value,
                            sigmaY: 25 * barrierAnimationController.value,
                          ),
                          child: Container(
                            color: isDarkMode
                                ? Colors.black.withAlpha(
                                    (80 * barrierAnimationController.value).toInt())
                                : Colors.black.withAlpha(
                                    (40 * barrierAnimationController.value).toInt()),
                          ),
                        );
                      } else if (blurBackground) {
                        overlayWidget = BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: 25 * barrierAnimationController.value,
                            sigmaY: 25 * barrierAnimationController.value,
                          ),
                          child: Container(
                            // If only blur, make the container under it slightly transparent
                            // to ensure blur is visible but not overly dark.
                            color: isDarkMode
                                ? Colors.black.withAlpha(
                                    (20 * barrierAnimationController.value).toInt())
                                : Colors.black.withAlpha(
                                    (10 * barrierAnimationController.value).toInt()),
                          ),
                        );
                      } else if (showDarkOverlay) {
                        overlayWidget = Container(
                          color: isDarkMode
                              ? Colors.black.withAlpha(
                                  (120 * barrierAnimationController.value).toInt())
                              : Colors.black.withAlpha(
                                  (60 * barrierAnimationController.value).toInt()), // Lighter overlay for light theme
                        );
                      }
                      return overlayWidget;
                    },
                  ),
                ),
              ),

        // Customized dismissible areas for containerKey if provided
        if (containerKey != null && dismissOnTapOutside)
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Get the RenderBox of the container
                final RenderBox? containerBox = containerKey.currentContext
                    ?.findRenderObject() as RenderBox?;
                if (containerBox == null) return const SizedBox.shrink();

                // Get the container's position in global coordinates
                final containerPosition =
                    containerBox.localToGlobal(Offset.zero);
                final containerRect = Rect.fromLTWH(
                  containerPosition.dx,
                  containerPosition.dy,
                  containerBox.size.width,
                  containerBox.size.height,
                );

                return Stack(
                  children: [
                    // Top area (above container)
                    if (containerRect.top > 0)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: containerRect.top,
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTapDown: (_) {
                            HapticFeedback.lightImpact();
                            modalKey.currentState?.closeWithAnimation();
                          },
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                    // Left area
                    if (containerRect.left > 0)
                      Positioned(
                        top: containerRect.top,
                        left: 0,
                        width: containerRect.left,
                        height: containerRect.height,
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTapDown: (_) {
                            HapticFeedback.lightImpact();
                            modalKey.currentState?.closeWithAnimation();
                          },
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                    // Right area
                    if (containerRect.right < constraints.maxWidth)
                      Positioned(
                        top: containerRect.top,
                        left: containerRect.right,
                        right: 0,
                        height: containerRect.height,
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTapDown: (_) {
                            HapticFeedback.lightImpact();
                            modalKey.currentState?.closeWithAnimation();
                          },
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                    // Bottom area (between container and modal)
                    if (containerRect.bottom < constraints.maxHeight)
                      Positioned(
                        top: containerRect.bottom,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTapDown: (_) {
                            HapticFeedback.lightImpact();
                            modalKey.currentState?.closeWithAnimation();
                          },
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

        // Modal content
        Positioned(
          left: 0,
          right: 0,
          bottom: MediaQuery.of(context).viewInsets.bottom,
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: _getMaxModalHeight(context),
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {}, // Empty onTap to prevent propagation
                child: DraggableOverlayModal(
                  key: modalKey, // Use the unique key created for this modal
                  onClose: dismissWithAnimation,
                  headerActions: headerActions,
                  backgroundColors: backgroundColors,
                  backgroundStops: backgroundStops,
                  allowUpwardDrag: allowUpwardDrag,
                  containerKey: containerKey,
                  customModalHeight: customModalHeight,
                  blurBackground: blurBackground,
                  headerDragOnly: headerDragOnly,
                  onDrag: onDrag,
                  showDarkOverlay: showDarkOverlay,
                  showOkButton: showOkButton,
                  showCloseButton: showCloseButton,
                  allowDragToDismiss: allowDragToDismiss,
                  child: child,
                ),
              ),
            ),
          ),
        ),
          ],
        );
      },
    ),
  );

  // Start the barrier animation
  barrierAnimationController.forward();

  Overlay.of(context).insert(overlayEntry);
  return overlayEntry;
}
