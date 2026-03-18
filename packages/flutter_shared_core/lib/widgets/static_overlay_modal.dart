import 'package:flutter/cupertino.dart';
import 'package:flutter_shared_core/utils/app_logger.dart';
import 'package:flutter/material.dart' show Colors, Material;
import 'package:flutter/services.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:google_fonts/google_fonts.dart'; // Removed unused import
import 'dart:ui';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
typedef StaticModalKey = GlobalKey<State<StaticOverlayModal>>;

/// Creates a new unique key for a static modal
StaticModalKey createStaticModalKey() {
  return GlobalKey<State<StaticOverlayModal>>();
}

// A fallback key for the legacy version of closeStaticModalWithAnimation
// Helps maintain backward compatibility with existing code
StaticModalKey _legacySharedStaticModalKey =
    GlobalKey<State<StaticOverlayModal>>();

/// Method to close a specific static modal with animation using its key
/// This version requires a specific modal key
void closeSpecificStaticModalWithAnimation(StaticModalKey key) {
  if (key.currentState is StaticOverlayModalState) {
    (key.currentState as StaticOverlayModalState).closeWithAnimation();
  }
}

// Map to store references to active static modals by their keys
// Using GlobalKey<StaticOverlayModalState> for internal use
final Map<StaticModalKey, bool> _activeStaticModalKeys = {};

/// Legacy version of closeStaticModalWithAnimation without parameters
/// Maintained for backward compatibility with existing code
void closeStaticModalWithAnimation() {
  // Access any active modal in the overlay
  // For modals created with showStaticOverlayModal, the key is stored in _activeStaticModalKeys
  if (_activeStaticModalKeys.isNotEmpty) {
    final activeKey = _activeStaticModalKeys.keys.last;
    // Cast is safe because we know it's the right type internally
    closeSpecificStaticModalWithAnimation(activeKey);
  } else {
    // Fallback to legacy key if no active keys found
    closeSpecificStaticModalWithAnimation(_legacySharedStaticModalKey);
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
class StaticOverlayModal extends ConsumerStatefulWidget {
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

  /// Optional widget to display as a title/header, below the action buttons header
  final Widget? titleHeaderContent;

  /// Whether to show the close button - ADDED for mandatory authentication control
  final bool showCloseButton;

  /// Optional callback for when the close button is pressed
  /// If not provided, will use the standard onClose callback
  final VoidCallback? onCloseButton;

  const StaticOverlayModal({
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
    this.titleHeaderContent,
    this.showCloseButton =
        true, // ADDED: Default to true for backward compatibility
    this.onCloseButton,
  });

  @override
  ConsumerState<StaticOverlayModal> createState() => StaticOverlayModalState();
}

class StaticOverlayModalState extends ConsumerState<StaticOverlayModal>
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

    const double targetDragOffset = 250.0;

    _springSimulation =
        SpringSimulation(spring, _dragOffset, targetDragOffset, 0.0);

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
      }
    });

    // Call widget.onClose() IMMEDIATELY.
    // This triggers dismissWithAnimation in showStaticOverlayModal, which starts
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
      // final modalHeight = calculateModalHeight(context, widget.containerKey, customModalHeight: widget.customModalHeight); // Unused

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
        // MODIFIED: Always snap back, never dismiss by drag
        // final bool isDismissed = _dragOffset > modalHeight * kDismissThreshold ||
        // details.velocity.pixelsPerSecond.dy > 700; // Keep existing dismiss logic

        // if (isDismissed) {
        // Haptic feedback is handled by closeWithAnimation.

        // Set _isDragging to false immediately to prevent further drag updates
        // from interfering while the dismiss animation starts.
        // if (mounted) {
        //   setState(() {
        //     _isDragging = false;
        // _heightExtension can be left as is or reset; the modal is disappearing.
        // _dragOffset will be animated by closeWithAnimation starting from its current value.
        // _isAnimatingSpring flags are managed by closeWithAnimation.
        //   });
        // }

        // Call closeWithAnimation. It will use the current _dragOffset.
        // It handles haptics and resetting its own animation flags.
        // closeWithAnimation();

        // } else { // MODIFIED: This block is now unconditional for wasAnimatingDragOffset
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
        // }
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
    // final int cancelActionId = ++_activeAnimationId; // Unused
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

    // Default background gradient colors
    final colors = widget.backgroundColors ??
        [
          const Color(0xFF2A2520).withAlpha(217),
          const Color(0xFF16120F).withAlpha(204),
        ];

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
          // Left and right buttons positioned at the corners
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Display headerActions on the left if provided, otherwise a placeholder
              widget.headerActions ??
                  const SizedBox(
                      width: 44, height: 44), // Placeholder to maintain balance

              // Close button on the right - MODIFIED: Only show if showCloseButton is true
              if (widget.showCloseButton)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(44, 44),
                  onPressed: () {
                    // Use custom close button callback if provided, otherwise use standard close
                    if (widget.onCloseButton != null) {
                      widget.onCloseButton!();
                    } else {
                      closeWithAnimation();
                    }
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/icons/arrow_2_Rounded_fill.svg', // This was the close icon in DraggableOverlayModal
                        // Assuming it's 'close' or 'cross' icon for StaticOverlayModal
                        // If 'assets/icons/cross_rounded.svg' exists, use that, otherwise keep.
                        // For now, keeping 'arrow_2_Rounded_fill.svg' as it was the original.
                        // If a specific 'cross' icon is needed, path should be updated.
                        width: 10,
                        height: 10,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF111111), // Changed to #111111
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(
                    width: 44,
                    height:
                        44), // ADDED: Placeholder to maintain balance when close button is hidden
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
            color: CupertinoColors.white.withAlpha(38),
            width: 0.5,
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
            child: Stack(
              children: [
                // The main content (e.g., _SubscriptionModalBody with its banner)
                // will be the first layer.
                Positioned.fill(
                  child: widget.child,
                ),

                // Header section, overlaid on top
                // The existing headerSection already has padding and contains the buttons.
                // It will be positioned at the top of the Stack.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child:
                      headerSection, // headerSection itself is a Container with padding
                ),

                // Display titleHeaderContent if provided, below the main header buttons
                if (widget.titleHeaderContent != null)
                  Positioned(
                    top:
                        0, // Adjust this based on desired spacing from top header or rely on its internal padding
                    left: 0,
                    right: 0,
                    child: widget.titleHeaderContent!,
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

/// Helper function to show a static overlay modal
/// This function now includes animation handling for
/// smooth appearance and dismissal.
OverlayEntry? showStaticOverlayModal({
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
  Widget? titleHeaderContent,
  bool showCloseButton = true,
  VoidCallback? onCloseButton,
}) {
  // Create a unique key for this modal instance
  final modalKey = createStaticModalKey(); // Use the new key creation function

  // Register this modal key as active
  _activeStaticModalKeys[modalKey] = true;

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
      overlayEntry
          .remove(); // FIXED: Removed unnecessary ! since overlayEntry is already checked for null above

      // Unregister this modal key when it's dismissed
      _activeStaticModalKeys.remove(modalKey);

      if (onDismiss != null) onDismiss();
    }

    // Clean up the controller
    barrierAnimationController.dispose();
  }

  overlayEntry = OverlayEntry(
    maintainState: true,
    opaque: false,
    builder: (context) => Stack(
      children: [
        // Background blur when enabled
        if (blurBackground)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: dismissOnTapOutside
                  ? (_) {
                      HapticFeedback.lightImpact();
                      // Use the modal's specific key
                      (modalKey.currentState as StaticOverlayModalState?)
                          ?.closeWithAnimation();
                    }
                  : null,
              child: AnimatedBuilder(
                animation: barrierAnimationController,
                builder: (context, _) {
                  return BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 25 * barrierAnimationController.value,
                      sigmaY: 25 * barrierAnimationController.value,
                    ),
                    child: Container(
                      color: Colors.black.withAlpha(
                          (80 * barrierAnimationController.value).toInt()),
                    ),
                  );
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
                            // Use the modal's specific key
                            (modalKey.currentState as StaticOverlayModalState?)
                                ?.closeWithAnimation();
                          },
                          child: Container(
                              color: Colors.transparent), // Added const
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
                            // Use the modal's specific key
                            (modalKey.currentState as StaticOverlayModalState?)
                                ?.closeWithAnimation();
                          },
                          child: Container(
                              color: Colors.transparent), // Added const
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
                            // Use the modal's specific key
                            (modalKey.currentState as StaticOverlayModalState?)
                                ?.closeWithAnimation();
                          },
                          child: Container(
                              color: Colors.transparent), // Added const
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
                            // Use the modal's specific key
                            (modalKey.currentState as StaticOverlayModalState?)
                                ?.closeWithAnimation();
                          },
                          child: Container(
                              color: Colors.transparent), // Added const
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
                maxHeight: MediaQuery.of(context).size.height * 0.92,
              ),
              child: StaticOverlayModal(
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
                titleHeaderContent: titleHeaderContent,
                showCloseButton: showCloseButton,
                onCloseButton: onCloseButton,
                child: child,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  // Start the barrier animation
  barrierAnimationController.forward();

  // Overlay.of(context).insert(overlayEntry); // Original line to be replaced
  try {
    final NavigatorState rootNavigator =
        Navigator.of(context, rootNavigator: true);
    if (rootNavigator.overlay != null) {
      rootNavigator.overlay!
          .insert(overlayEntry); // Removed ! from overlayEntry
    } else {
      // This case (root navigator exists but its overlay is null) is highly unusual.
      // Fallback to the original method as a last resort.
      AppLogger.log(
          'Warning: Root navigator found, but its overlay is null. Falling back to Overlay.of(context).');
      Overlay.of(context).insert(overlayEntry); // Removed ! from overlayEntry
    }
  } catch (e) {
    // Catch if Navigator.of(context, rootNavigator: true) fails (e.g., no root navigator found)
    AppLogger.log(
        'Error finding root navigator: $e. Falling back to Overlay.of(context).');
    Overlay.of(context).insert(overlayEntry); // Removed ! from overlayEntry
  }

  return overlayEntry;
}
