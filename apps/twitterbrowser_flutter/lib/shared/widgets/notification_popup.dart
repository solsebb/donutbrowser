import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter_shared_core/theme/providers/theme_provider.dart';
import 'package:flutter_shared_core/theme/models/app_theme.dart';

// =============================================================================
// NOTIFICATION DATA MODEL
// =============================================================================

/// Notification type for styling
enum NotificationType {
  info,
  success,
  warning,
  error,
  progress,
}

enum NotificationDismissStyle {
  standard,
  softChevron,
  none,
}

enum NotificationDismissReason {
  timer,
  manual,
  replaced,
  programmatic,
}

/// Notification data model
class NotificationData {
  final String id;
  final String title;
  final String subtitle;
  final NotificationType type;
  final String? iconAsset;
  final IconData? icon;
  final int? progress; // 0-100 for progress type
  final Duration? autoDismissAfter;
  final Duration? minVisibleFor;
  final NotificationDismissStyle dismissStyle;
  final VoidCallback? onTap;
  final DateTime createdAt;

  NotificationData({
    required this.id,
    required this.title,
    required this.subtitle,
    this.type = NotificationType.info,
    this.iconAsset,
    this.icon,
    this.progress,
    this.autoDismissAfter,
    this.minVisibleFor,
    this.dismissStyle = NotificationDismissStyle.standard,
    this.onTap,
  }) : createdAt = DateTime.now();

  NotificationData copyWith({
    String? title,
    String? subtitle,
    NotificationType? type,
    String? iconAsset,
    IconData? icon,
    int? progress,
    Duration? autoDismissAfter,
    Duration? minVisibleFor,
    NotificationDismissStyle? dismissStyle,
    VoidCallback? onTap,
  }) {
    return NotificationData(
      id: id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      type: type ?? this.type,
      iconAsset: iconAsset ?? this.iconAsset,
      icon: icon ?? this.icon,
      progress: progress ?? this.progress,
      autoDismissAfter: autoDismissAfter ?? this.autoDismissAfter,
      minVisibleFor: minVisibleFor ?? this.minVisibleFor,
      dismissStyle: dismissStyle ?? this.dismissStyle,
      onTap: onTap ?? this.onTap,
    );
  }
}

// =============================================================================
// NOTIFICATION CONTROLLER PROVIDER
// =============================================================================

/// State notifier for managing notifications
class NotificationController extends StateNotifier<List<NotificationData>> {
  final Map<String, Timer> _autoDismissTimers = {};
  final Map<String, Timer> _pendingDismissTimers = {};
  final Map<String, DateTime> _shownAtById = {};

  NotificationController() : super([]);

  /// Show a notification
  void show(NotificationData notification) {
    // Replace existing notification with same ID.
    dismiss(
      notification.id,
      reason: NotificationDismissReason.replaced,
      respectMinVisible: false,
    );

    // Add new notification
    state = [...state, notification];
    _shownAtById[notification.id] = DateTime.now();

    // Set up auto-dismiss if specified
    if (notification.autoDismissAfter != null) {
      _autoDismissTimers[notification.id]?.cancel();
      _autoDismissTimers[notification.id] = Timer(
        notification.autoDismissAfter!,
        () => dismiss(
          notification.id,
          reason: NotificationDismissReason.timer,
        ),
      );
    }
  }

  /// Update an existing notification
  void update(String id, NotificationData Function(NotificationData) updater) {
    state = state.map((n) {
      if (n.id == id) {
        return updater(n);
      }
      return n;
    }).toList();
  }

  /// Dismiss a notification by ID
  void dismiss(
    String id, {
    NotificationDismissReason reason = NotificationDismissReason.programmatic,
    bool respectMinVisible = true,
  }) {
    NotificationData? notification;
    for (final item in state) {
      if (item.id == id) {
        notification = item;
        break;
      }
    }
    if (notification == null) return;

    final shownAt = _shownAtById[id];
    final elapsed = shownAt == null
        ? Duration.zero
        : DateTime.now().difference(shownAt);
    final minVisibleFor = notification.minVisibleFor ?? Duration.zero;

    if (respectMinVisible && minVisibleFor > Duration.zero && elapsed < minVisibleFor) {
      final remaining = minVisibleFor - elapsed;
      _pendingDismissTimers[id]?.cancel();
      _pendingDismissTimers[id] = Timer(
        remaining,
        () => dismiss(id, reason: reason, respectMinVisible: false),
      );
      _logDismiss(
        id: id,
        reason: reason,
        elapsed: elapsed,
        minVisibleFor: minVisibleFor,
        deferred: true,
      );
      return;
    }

    _autoDismissTimers[id]?.cancel();
    _autoDismissTimers.remove(id);
    _pendingDismissTimers[id]?.cancel();
    _pendingDismissTimers.remove(id);
    _shownAtById.remove(id);
    _logDismiss(
      id: id,
      reason: reason,
      elapsed: elapsed,
      minVisibleFor: minVisibleFor,
      deferred: false,
    );
    state = state.where((n) => n.id != id).toList();
  }

  /// Dismiss all notifications
  void dismissAll() {
    for (final timer in _autoDismissTimers.values) {
      timer.cancel();
    }
    _autoDismissTimers.clear();
    for (final timer in _pendingDismissTimers.values) {
      timer.cancel();
    }
    _pendingDismissTimers.clear();
    _shownAtById.clear();
    state = [];
  }

  @override
  void dispose() {
    for (final timer in _autoDismissTimers.values) {
      timer.cancel();
    }
    for (final timer in _pendingDismissTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  void _logDismiss({
    required String id,
    required NotificationDismissReason reason,
    required Duration elapsed,
    required Duration minVisibleFor,
    required bool deferred,
  }) {
    debugPrint(
      '[NotificationPopup] dismiss reason=${reason.name} id=$id elapsedMs=${elapsed.inMilliseconds} minVisibleMs=${minVisibleFor.inMilliseconds}${deferred ? ' deferred=true' : ''}',
    );
  }
}

/// Global notification controller provider
final notificationControllerProvider =
    StateNotifierProvider<NotificationController, List<NotificationData>>(
  (ref) => NotificationController(),
);

// =============================================================================
// NOTIFICATION POPUP WIDGET
// =============================================================================

/// A pixel-perfect notification popup positioned at bottom-left
/// Matches the Google approval notification style in the reference image
class NotificationPopup extends ConsumerStatefulWidget {
  final NotificationData notification;
  final ValueChanged<NotificationDismissReason>? onDismiss;

  const NotificationPopup({
    super.key,
    required this.notification,
    this.onDismiss,
  });

  @override
  ConsumerState<NotificationPopup> createState() => _NotificationPopupState();
}

class _NotificationPopupState extends ConsumerState<NotificationPopup>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Progress animation for smooth updates
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  double _currentProgress = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Initialize progress animation
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _currentProgress = (widget.notification.progress ?? 0).toDouble();
    _progressAnimation = Tween<double>(
      begin: _currentProgress,
      end: _currentProgress,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void didUpdateWidget(NotificationPopup oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Animate progress when it changes
    final newProgress = (widget.notification.progress ?? 0).toDouble();
    if (newProgress != _currentProgress) {
      _progressAnimation = Tween<double>(
        begin: _currentProgress,
        end: newProgress,
      ).animate(CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeOutCubic,
      ));
      _currentProgress = newProgress;
      _progressController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _dismiss(NotificationDismissReason reason) async {
    await _animationController.reverse();
    widget.onDismiss?.call(reason);
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(themeColorsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final brightness = MediaQuery.of(context).platformBrightness;
    final isLightTheme = themeMode == AppThemeMode.light ||
        (themeMode == AppThemeMode.system && brightness == Brightness.light);

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildNotificationCard(colors, isLightTheme),
      ),
    );
  }

  Widget _buildNotificationCard(AppThemeColors colors, bool isLightTheme) {
    // Card colors matching the reference image
    final cardBgColor = isLightTheme
        ? CupertinoColors.white
        : const Color(0xFF252525);

    final borderColor = isLightTheme
        ? const Color(0xFFE5E5EA)
        : colors.primaryBorder.withValues(alpha: 0.3);

    final shadowColor = isLightTheme
        ? const Color(0x1A000000)
        : const Color(0x40000000);

    return GestureDetector(
      onTap: widget.notification.onTap,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 360,
          minWidth: 280,
        ),
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: cardBgColor,
          shape: SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius(
              cornerRadius: 16,
              cornerSmoothing: 0.8,
            ),
            side: BorderSide(
              color: borderColor,
              width: 0.5,
            ),
          ),
          shadows: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: shadowColor.withValues(alpha: 0.05),
              blurRadius: 40,
              spreadRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipSmoothRect(
          radius: SmoothBorderRadius(
            cornerRadius: 16,
            cornerSmoothing: 0.8,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                _buildIcon(colors, isLightTheme),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      Text(
                        widget.notification.title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.primaryText,
                          letterSpacing: -0.2,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 3),

                      // Subtitle
                      Text(
                        widget.notification.subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: colors.secondaryText,
                          letterSpacing: -0.1,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Progress bar (if progress type)
                      if (widget.notification.type == NotificationType.progress &&
                          widget.notification.progress != null) ...[
                        const SizedBox(height: 10),
                        _buildProgressBar(colors, isLightTheme),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Close button
                _buildCloseButton(colors),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(AppThemeColors colors, bool isLightTheme) {
    final iconColor = _getIconColor(colors);
    final iconBgColor = iconColor.withValues(alpha: 0.12);

    // Use custom icon asset if provided
    if (widget.notification.iconAsset != null) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconBgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: SvgPicture.asset(
            widget.notification.iconAsset!,
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          ),
        ),
      );
    }

    // Use custom icon if provided
    if (widget.notification.icon != null) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconBgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Icon(
            widget.notification.icon,
            size: 20,
            color: iconColor,
          ),
        ),
      );
    }

    // Default icon based on type
    final defaultIcon = _getDefaultIcon();
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: iconBgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Icon(
          defaultIcon,
          size: 20,
          color: iconColor,
        ),
      ),
    );
  }

  Color _getIconColor(AppThemeColors colors) {
    switch (widget.notification.type) {
      case NotificationType.success:
        return colors.success;
      case NotificationType.warning:
        return colors.warning;
      case NotificationType.error:
        return colors.error;
      case NotificationType.progress:
      case NotificationType.info:
        return colors.accentPrimary;
    }
  }

  IconData _getDefaultIcon() {
    switch (widget.notification.type) {
      case NotificationType.success:
        return CupertinoIcons.checkmark_circle_fill;
      case NotificationType.warning:
        return CupertinoIcons.exclamationmark_triangle_fill;
      case NotificationType.error:
        return CupertinoIcons.xmark_circle_fill;
      case NotificationType.progress:
        return CupertinoIcons.arrow_2_circlepath;
      case NotificationType.info:
        return CupertinoIcons.info_circle_fill;
    }
  }

  Widget _buildProgressBar(AppThemeColors colors, bool isLightTheme) {
    final progressColor = colors.accentPrimary;
    final trackColor = isLightTheme
        ? const Color(0xFFE5E5EA)
        : colors.primaryBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress track
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(2),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // Progress fill with smooth animation from current to target
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return Container(
                        width: constraints.maxWidth * (_progressAnimation.value / 100),
                        height: 4,
                        decoration: BoxDecoration(
                          color: progressColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        // Progress text with smooth animation
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return Text(
              '${_progressAnimation.value.round()}%',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colors.tertiaryText,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCloseButton(AppThemeColors colors) {
    if (widget.notification.dismissStyle == NotificationDismissStyle.none) {
      return const SizedBox(width: 4);
    }

    final bool isSoft =
        widget.notification.dismissStyle == NotificationDismissStyle.softChevron;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(24, 24),
      onPressed: () {
        HapticFeedback.lightImpact();
        _dismiss(NotificationDismissReason.manual);
      },
      child: Container(
        width: isSoft ? 22 : 24,
        height: isSoft ? 22 : 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.tertiaryText.withValues(alpha: isSoft ? 0.08 : 0.12),
        ),
        child: Center(
          child: SvgPicture.asset(
            'assets/icons/arrow_2_Rounded_fill.svg',
            width: isSoft ? 12 : 10,
            height: isSoft ? 12 : 10,
            colorFilter: ColorFilter.mode(
              colors.tertiaryText.withValues(alpha: isSoft ? 0.8 : 1),
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// NOTIFICATION OVERLAY WIDGET
// =============================================================================

/// Overlay widget that displays notifications at bottom-left of screen
class NotificationOverlay extends ConsumerWidget {
  final Widget child;

  const NotificationOverlay({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationControllerProvider);

    return Stack(
      children: [
        child,

        // Notification popups
        if (notifications.isNotEmpty)
          Positioned(
            left: 20,
            bottom: MediaQuery.of(context).padding.bottom + 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: notifications.map((notification) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: NotificationPopup(
                    key: ValueKey(notification.id),
                    notification: notification,
                    onDismiss: (reason) {
                      ref
                          .read(notificationControllerProvider.notifier)
                          .dismiss(notification.id, reason: reason);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

// =============================================================================
// CONVENIENCE EXTENSION
// =============================================================================

/// Extension on WidgetRef for easy notification access
extension NotificationExtension on WidgetRef {
  /// Show a notification
  void showNotification(NotificationData notification) {
    read(notificationControllerProvider.notifier).show(notification);
  }

  /// Update a notification by ID
  void updateNotification(
      String id, NotificationData Function(NotificationData) updater) {
    read(notificationControllerProvider.notifier).update(id, updater);
  }

  /// Dismiss a notification by ID
  void dismissNotification(
    String id, {
    NotificationDismissReason reason = NotificationDismissReason.programmatic,
  }) {
    read(notificationControllerProvider.notifier).dismiss(id, reason: reason);
  }

  /// Show a success notification
  void showSuccessNotification(String title, String subtitle,
      {Duration? autoDismissAfter}) {
    showNotification(NotificationData(
      id: 'success_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      subtitle: subtitle,
      type: NotificationType.success,
      autoDismissAfter: autoDismissAfter ?? const Duration(seconds: 4),
    ));
  }

  /// Show an error notification
  void showErrorNotification(String title, String subtitle,
      {Duration? autoDismissAfter}) {
    showNotification(NotificationData(
      id: 'error_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      subtitle: subtitle,
      type: NotificationType.error,
      autoDismissAfter: autoDismissAfter ?? const Duration(seconds: 6),
    ));
  }

  /// Show a progress notification
  void showProgressNotification(String id, String title, String subtitle,
      {int progress = 0}) {
    showNotification(NotificationData(
      id: id,
      title: title,
      subtitle: subtitle,
      type: NotificationType.progress,
      progress: progress,
    ));
  }
}
