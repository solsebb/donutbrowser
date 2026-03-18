import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_shared_core/theme/models/app_theme.dart';
import 'package:flutter_shared_core/widgets/notion_table.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:twitterbrowser_flutter/features/profiles/data/models/browser_profile_summary.dart';
import 'package:twitterbrowser_flutter/features/profiles/presentation/providers/profile_providers.dart';

class ProfilesTable extends ConsumerStatefulWidget {
  const ProfilesTable({
    super.key,
    required this.profiles,
    required this.colors,
    required this.isLightTheme,
    required this.onOpen,
  });

  final List<BrowserProfileSummary> profiles;
  final AppThemeColors colors;
  final bool isLightTheme;
  final ValueChanged<BrowserProfileSummary> onOpen;

  @override
  ConsumerState<ProfilesTable> createState() => _ProfilesTableState();
}

class _ProfilesTableState extends ConsumerState<ProfilesTable> {
  List<NotionTableColumn<BrowserProfileSummary>> get _columns => [
        NotionTableColumn<BrowserProfileSummary>(
          header: '',
          flex: 0,
          headerWidget: _buildSelectAllCheckbox(),
          cellBuilder: (profile, _, __) => _buildCheckbox(profile),
        ),
        NotionTableColumn<BrowserProfileSummary>(
          header: 'Status',
          flex: 1,
          cellBuilder: (profile, _, __) => _buildStatusIndicator(profile),
        ),
        NotionTableColumn<BrowserProfileSummary>(
          header: 'Profile Name',
          flex: 4,
          cellBuilder: (profile, _, __) => _buildNameCell(profile),
        ),
        NotionTableColumn<BrowserProfileSummary>(
          header: 'Browser',
          flex: 2,
          cellBuilder: (profile, _, __) => _buildBrowserCell(profile),
        ),
        NotionTableColumn<BrowserProfileSummary>(
          header: 'Proxy / VPN',
          flex: 2,
          cellBuilder: (profile, _, __) => _buildConnectionCell(profile),
        ),
        NotionTableColumn<BrowserProfileSummary>(
          header: 'Source',
          flex: 2,
          cellBuilder: (profile, _, __) => _buildSourceCell(profile),
        ),
        NotionTableColumn<BrowserProfileSummary>(
          header: 'Last active',
          flex: 2,
          cellBuilder: (profile, _, __) => _buildActivityCell(profile),
        ),
        NotionTableColumn<BrowserProfileSummary>(
          header: 'Actions',
          flex: 2,
          cellBuilder: (profile, _, __) => _buildActionsCell(profile),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = !kIsWeb || screenWidth <= 768;

    Widget table = NotionTable<BrowserProfileSummary>(
      items: widget.profiles,
      columns: _columns,
      isLightTheme: widget.isLightTheme,
      onRowTap: (profile, _) {
        HapticFeedback.lightImpact();
        widget.onOpen(profile);
      },
      minRowHeight: 52,
      headerMinHeight: 38,
      headerCellPadding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      borderRadius: 8,
    );

    if (isMobile) {
      table = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(width: 980, child: table),
      );
    }

    return table;
  }

  Widget _buildSelectAllCheckbox() {
    final selectedIds = ref.watch(selectedProfileIdsProvider);
    final allSelected =
        widget.profiles.isNotEmpty &&
        widget.profiles.every((profile) => selectedIds.contains(profile.id));
    final someSelected = selectedIds.isNotEmpty && !allSelected;

    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          ref.read(selectedProfileIdsProvider.notifier).state = allSelected
              ? <String>{}
              : widget.profiles.map((profile) => profile.id).toSet();
        },
        child: _buildHeaderCheckboxWidget(
          isSelected: allSelected,
          isPartial: someSelected,
        ),
      ),
    );
  }

  Widget _buildCheckbox(BrowserProfileSummary profile) {
    final selectedIds = ref.watch(selectedProfileIdsProvider);
    final isSelected = selectedIds.contains(profile.id);

    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          final next = {...selectedIds};
          if (!next.add(profile.id)) {
            next.remove(profile.id);
          }
          ref.read(selectedProfileIdsProvider.notifier).state = next;
        },
        child: _buildRowCheckboxWidget(isSelected: isSelected),
      ),
    );
  }

  Widget _buildRowCheckboxWidget({required bool isSelected}) {
    final checkColor = widget.colors.accentPrimary;
    const cardGrey = Color(0xFFE5E5EA);

    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: isSelected ? checkColor : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected ? checkColor : cardGrey,
          width: 1.5,
        ),
      ),
      child: isSelected
          ? const Center(
              child: Icon(
                CupertinoIcons.check_mark,
                size: 11,
                color: CupertinoColors.white,
              ),
            )
          : null,
    );
  }

  Widget _buildHeaderCheckboxWidget({
    required bool isSelected,
    bool isPartial = false,
  }) {
    final checkColor = widget.colors.accentPrimary;
    const borderGrey = Color(0xFF6B7280);

    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: isSelected || isPartial ? checkColor : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected || isPartial ? checkColor : borderGrey,
          width: 1.5,
        ),
      ),
      child: isSelected
          ? const Center(
              child: Icon(
                CupertinoIcons.check_mark,
                size: 11,
                color: CupertinoColors.white,
              ),
            )
          : isPartial
              ? Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                )
              : null,
    );
  }

  Widget _buildStatusIndicator(BrowserProfileSummary profile) {
    final isActive = profile.isRunning;
    final background = isActive
        ? widget.colors.success.withValues(alpha: 0.16)
        : widget.colors.secondaryBackground;
    final foreground =
        isActive ? widget.colors.success : widget.colors.secondaryText;

    return Container(
      width: 54,
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: foreground.withValues(alpha: 0.12),
        ),
      ),
      child: Align(
        alignment: isActive ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: foreground,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Icon(
            isActive ? CupertinoIcons.play_fill : CupertinoIcons.pause_solid,
            size: 10,
            color: CupertinoColors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildNameCell(BrowserProfileSummary profile) {
    final secondaryText = [
      if (profile.note?.trim().isNotEmpty ?? false) profile.note!.trim(),
      if (profile.tags.isNotEmpty) profile.tags.take(2).join(' • '),
    ].where((value) => value.isNotEmpty).join('  •  ');

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          profile.name,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: widget.colors.primaryText,
            letterSpacing: -0.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (secondaryText.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            secondaryText,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: widget.colors.secondaryText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildBrowserCell(BrowserProfileSummary profile) {
    final hostLabel = profile.hostOs?.trim();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${profile.browser} ${profile.version}'.trim(),
          style: NotionTableTextStyles.primary(
            widget.isLightTheme,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (hostLabel != null && hostLabel.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            hostLabel,
            style: NotionTableTextStyles.secondary(widget.isLightTheme, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildConnectionCell(BrowserProfileSummary profile) {
    final proxy = profile.proxyId?.trim();
    final vpn = profile.vpnId?.trim();
    if ((proxy == null || proxy.isEmpty) && (vpn == null || vpn.isEmpty)) {
      return Text('—', style: NotionTableTextStyles.muted(widget.isLightTheme));
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (proxy != null && proxy.isNotEmpty)
          Text(
            'Proxy • $proxy',
            style: NotionTableTextStyles.secondary(widget.isLightTheme, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        if (vpn != null && vpn.isNotEmpty)
          Text(
            'VPN • $vpn',
            style: NotionTableTextStyles.secondary(widget.isLightTheme, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Widget _buildSourceCell(BrowserProfileSummary profile) {
    final isHosted = profile.source == ProfileDataSource.hosted;
    final background = isHosted
        ? const Color(0xFF918DF6).withValues(alpha: 0.16)
        : widget.colors.secondaryBackground;
    final foreground =
        isHosted ? const Color(0xFF918DF6) : widget.colors.secondaryText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: foreground.withValues(alpha: 0.18),
        ),
      ),
      child: Text(
        profile.sourceLabel,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }

  Widget _buildActivityCell(BrowserProfileSummary profile) {
    final activity = profile.activityTimestamp;
    final text = activity > 0
        ? DateFormat('MMM d, HH:mm').format(
            DateTime.fromMillisecondsSinceEpoch(activity),
          )
        : 'Never';

    return Text(
      text,
      style: NotionTableTextStyles.secondary(widget.isLightTheme),
    );
  }

  Widget _buildActionsCell(BrowserProfileSummary profile) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: const Size(28, 28),
          onPressed: () => widget.onOpen(profile),
          child: Icon(
            CupertinoIcons.arrow_up_right_circle,
            size: 18,
            color: widget.colors.secondaryText,
          ),
        ),
        const SizedBox(width: 4),
        CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: const Size(28, 28),
          onPressed: () => widget.onOpen(profile),
          child: Icon(
            CupertinoIcons.ellipsis,
            size: 18,
            color: widget.colors.secondaryText,
          ),
        ),
      ],
    );
  }
}
