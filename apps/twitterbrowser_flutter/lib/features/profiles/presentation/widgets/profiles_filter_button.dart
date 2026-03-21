import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_shared_core/theme/providers/theme_provider.dart';
import 'package:flutter_shared_core/widgets/notion_dropdown.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:twitterbrowser_flutter/features/profiles/presentation/providers/profile_providers.dart';
import 'package:twitterbrowser_flutter/shared/widgets/hover_tooltip.dart';

class ProfilesFilterButton extends ConsumerWidget {
  const ProfilesFilterButton({super.key});

  String _labelForFilter(ProfilesStatusFilter filter) {
    return switch (filter) {
      ProfilesStatusFilter.all => 'All',
      ProfilesStatusFilter.running => 'Running',
      ProfilesStatusFilter.available => 'Available',
    };
  }

  void _showFilterDropdown(BuildContext context, WidgetRef ref, Offset tapPosition) {
    final theme = NotionDropdownTheme.fromRef(ref, context);
    final profiles = ref.read(currentProfilesProvider).valueOrNull ?? const [];
    final state = ref.read(profilesViewStateProvider);
    final runningCount = profiles.where((profile) => profile.isRunning).length;
    final availableCount = profiles.length - runningCount;

    showNotionDropdown(
      context: context,
      tapPosition: tapPosition,
      width: 200,
      cornerRadius: 10,
      builder: (context, close) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NotionDropdownHeader(
              title: 'FILTER BY STATUS',
              textColor: theme.secondaryTextColor,
            ),
            NotionDropdownRow(
              leading: Icon(
                CupertinoIcons.circle,
                size: 16,
                color: state.statusFilter == ProfilesStatusFilter.all
                    ? theme.textColor
                    : theme.secondaryTextColor,
              ),
              label: 'All (${profiles.length})',
              trailing: state.statusFilter == ProfilesStatusFilter.all
                  ? Icon(CupertinoIcons.checkmark, size: 14, color: theme.textColor)
                  : null,
              textColor: theme.textColor,
              hoverBgColor: theme.hoverBgColor,
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(profilesViewStateProvider.notifier).state = state.copyWith(
                  statusFilter: ProfilesStatusFilter.all,
                );
                close();
              },
            ),
            NotionDropdownDivider(color: theme.dividerColor),
            ...[
              (ProfilesStatusFilter.running, runningCount),
              (ProfilesStatusFilter.available, availableCount),
            ].map((entry) {
              final filter = entry.$1;
              final count = entry.$2;
              final isSelected = state.statusFilter == filter;
              final icon = filter == ProfilesStatusFilter.running
                  ? CupertinoIcons.play_circle
                  : CupertinoIcons.pause_circle;
              return NotionDropdownRow(
                leading: Icon(
                  icon,
                  size: 16,
                  color: isSelected ? theme.textColor : theme.secondaryTextColor,
                ),
                label: '${_labelForFilter(filter)} ($count)',
                trailing: isSelected
                    ? Icon(CupertinoIcons.checkmark, size: 14, color: theme.textColor)
                    : null,
                textColor: theme.textColor,
                hoverBgColor: theme.hoverBgColor,
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(profilesViewStateProvider.notifier).state = state.copyWith(
                    statusFilter: filter,
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
    final colors = ref.watch(themeColorsProvider);

    return HoverTooltip(
      message: 'Filter',
      topOffset: 32,
      leftOffset: -8,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        onPressed: () {
          HapticFeedback.lightImpact();
          final box = context.findRenderObject() as RenderBox;
          final position = box.localToGlobal(Offset(0, box.size.height));
          _showFilterDropdown(context, ref, position);
        },
        child: SvgPicture.asset(
          'assets/icons/sort_RoundedFill.svg',
          width: 20,
          height: 20,
          colorFilter: ColorFilter.mode(colors.secondaryText, BlendMode.srcIn),
        ),
      ),
    );
  }
}
