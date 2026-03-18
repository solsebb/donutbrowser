import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_shared_core/widgets/notion_dropdown.dart';
import 'package:twitterbrowser_flutter/features/profiles/presentation/providers/profile_providers.dart';
import 'package:twitterbrowser_flutter/shared/widgets/selector_trigger_button.dart';

class ProfilesBrowserFilterButton extends ConsumerWidget {
  const ProfilesBrowserFilterButton({super.key, this.compact = false});

  final bool compact;

  void _showFilterDropdown(BuildContext context, WidgetRef ref, Offset tapPosition) {
    final theme = NotionDropdownTheme.fromRef(ref, context);
    final profiles = ref.read(currentProfilesProvider).valueOrNull ?? const [];
    final browsers = ref.read(availableProfileBrowsersProvider);
    final state = ref.read(profilesViewStateProvider);

    final browserCounts = <String, int>{};
    for (final profile in profiles) {
      final browser = profile.browser.trim();
      if (browser.isEmpty) continue;
      browserCounts[browser] = (browserCounts[browser] ?? 0) + 1;
    }

    showNotionDropdown(
      context: context,
      tapPosition: tapPosition,
      width: 240,
      cornerRadius: 10,
      builder: (ctx, close) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NotionDropdownHeader(
              title: 'FILTER BY BROWSER',
              textColor: theme.secondaryTextColor,
            ),
            NotionDropdownRow(
              leading: Icon(
                CupertinoIcons.circle_grid_3x3_fill,
                size: 16,
                color: state.browserFilter == null
                    ? theme.textColor
                    : theme.secondaryTextColor,
              ),
              label: 'View all browsers (${profiles.length})',
              trailing: state.browserFilter == null
                  ? Icon(CupertinoIcons.checkmark, size: 14, color: theme.textColor)
                  : null,
              textColor: theme.textColor,
              hoverBgColor: theme.hoverBgColor,
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(profilesViewStateProvider.notifier).state = state.copyWith(
                  clearBrowserFilter: true,
                );
                close();
              },
            ),
            if (browsers.isNotEmpty)
              NotionDropdownDivider(color: theme.dividerColor),
            ...browsers.map((browser) {
              final isSelected = state.browserFilter?.toLowerCase() ==
                  browser.toLowerCase();
              final count = browserCounts[browser] ?? 0;
              return NotionDropdownRow(
                leading: Icon(
                  CupertinoIcons.globe,
                  size: 16,
                  color: isSelected ? theme.textColor : theme.secondaryTextColor,
                ),
                label: '$browser ($count)',
                trailing: isSelected
                    ? Icon(CupertinoIcons.checkmark, size: 14, color: theme.textColor)
                    : null,
                textColor: theme.textColor,
                hoverBgColor: theme.hoverBgColor,
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(profilesViewStateProvider.notifier).state = state.copyWith(
                    browserFilter: browser,
                  );
                  close();
                },
              );
            }),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profilesViewStateProvider);
    final label = state.browserFilter == null || state.browserFilter!.isEmpty
        ? 'View all browsers'
        : state.browserFilter!;

    return SelectorTriggerButton(
      label: label,
      compact: compact,
      tooltip: 'Filter by browser',
      onPressed: () {
        final box = context.findRenderObject() as RenderBox;
        final position = box.localToGlobal(Offset(0, box.size.height));
        _showFilterDropdown(context, ref, position);
      },
    );
  }
}
