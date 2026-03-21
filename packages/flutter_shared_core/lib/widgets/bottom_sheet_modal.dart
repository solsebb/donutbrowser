import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show showModalBottomSheet, Colors;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

/// A standard bottom sheet modal with a title bar and close button
class BottomSheetModal extends StatelessWidget {
  /// The title displayed in the header
  final String title;

  /// The content to display in the modal
  final Widget child;

  /// Callback when the modal is dismissed
  final VoidCallback? onDismiss;

  /// Background color for the modal
  final Color backgroundColor;

  /// Whether to use haptic feedback
  final bool useHaptics;

  const BottomSheetModal({
    super.key,
    required this.title,
    required this.child,
    this.onDismiss,
    this.backgroundColor = const Color(0xFF1C1C1E),
    this.useHaptics = true,
  });

  @override
  Widget build(BuildContext context) {
    // Get bottom safe area to ensure content doesn't overlap system UI
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Modal header with title and close button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: CupertinoColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    if (useHaptics) HapticFeedback.lightImpact();
                    if (onDismiss != null) {
                      onDismiss!();
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Icon(
                    CupertinoIcons.xmark,
                    color: CupertinoColors.systemGrey,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          // Horizontal divider
          Container(
            height: 1,
            color: CupertinoColors.systemGrey.withOpacity(0.2),
          ),

          // Main content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: child,
          ),

          // Bottom safe area padding
          SizedBox(height: bottomSafeArea + 16),
        ],
      ),
    );
  }
}

/// Shows a modal bottom sheet with the standard styling
Future<T?> showBottomSheetModal<T>({
  required BuildContext context,
  required String title,
  VoidCallback? onDismiss,
  Color backgroundColor = const Color(0xFF1C1C1E),
  bool isDismissible = true,
  bool enableDrag = true,
  bool useHaptics = true,
  required Widget child,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    builder: (context) => BottomSheetModal(
      title: title,
      onDismiss: onDismiss,
      backgroundColor: backgroundColor,
      useHaptics: useHaptics,
      child: child,
    ),
  );
}
