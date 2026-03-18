import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_shared_core/theme/providers/theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:twitterbrowser_flutter/features/profiles/data/models/browser_profile_summary.dart';
import 'package:twitterbrowser_flutter/features/profiles/presentation/providers/profile_providers.dart';
import 'package:twitterbrowser_flutter/shared/widgets/rounded_button.dart';

class ProfileDetailScreen extends ConsumerWidget {
  const ProfileDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeColorsProvider);
    final selectedId = ref.watch(selectedProfileIdProvider);
    final profileAsync = ref.watch(selectedProfileProvider);

    return Container(
      color: colors.primaryBackground,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      ref.read(selectedProfileIdProvider.notifier).state = null;
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.chevron_left,
                          size: 18,
                          color: colors.secondaryText,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Back to profiles',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  RoundedButton(
                    text: 'Refresh',
                    onPressed: () {
                      ref.invalidate(selectedProfileProvider);
                      ref.invalidate(currentProfilesProvider);
                    },
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverToBoxAdapter(
              child: profileAsync.when(
                data: (profile) {
                  if (profile == null) {
                    return _DetailEmptyState(colors: colors);
                  }
                  return _ProfileDetailContent(
                    profile: profile,
                    colors: colors,
                  );
                },
                loading: () => const SizedBox(
                  height: 240,
                  child: Center(child: CupertinoActivityIndicator()),
                ),
                error: (error, _) => _DetailErrorState(
                  message: error.toString(),
                  colors: colors,
                  profileId: selectedId,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileDetailContent extends StatelessWidget {
  const _ProfileDetailContent({
    required this.profile,
    required this.colors,
  });

  final BrowserProfileSummary profile;
  final dynamic colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          profile.name,
          style: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: colors.primaryText,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Read-only profile detail view',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: colors.secondaryText,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _InfoCard(
              colors: colors,
              title: 'Browser',
              value: '${profile.browser} ${profile.version}'.trim(),
            ),
            _InfoCard(
              colors: colors,
              title: 'Source',
              value: profile.sourceLabel,
            ),
            _InfoCard(
              colors: colors,
              title: 'Status',
              value: profile.isRunning ? 'Running' : 'Available',
            ),
          ],
        ),
        const SizedBox(height: 20),
        _DetailSection(
          title: 'Profile metadata',
          colors: colors,
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _KeyValue(label: 'Release', value: profile.releaseType, colors: colors),
              _KeyValue(
                label: 'Last active',
                value: _formatTimestamp(profile.activityTimestamp),
                colors: colors,
              ),
              _KeyValue(label: 'Proxy', value: profile.proxyId ?? '—', colors: colors),
              _KeyValue(label: 'VPN', value: profile.vpnId ?? '—', colors: colors),
              _KeyValue(label: 'Host OS', value: profile.hostOs ?? '—', colors: colors),
              _KeyValue(
                label: 'Created by',
                value: profile.createdByEmail ?? '—',
                colors: colors,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _DetailSection(
          title: 'Tags',
          colors: colors,
          child: profile.tags.isEmpty
              ? Text(
                  'No tags assigned',
                  style: GoogleFonts.inter(fontSize: 14, color: colors.secondaryText),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profile.tags
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: colors.secondaryBackground,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: colors.primaryBorder.withValues(alpha: 0.16),
                            ),
                          ),
                          child: Text(
                            tag,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colors.primaryText,
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
        ),
        const SizedBox(height: 20),
        _DetailSection(
          title: 'Notes',
          colors: colors,
          child: Text(
            (profile.note?.trim().isNotEmpty ?? false) ? profile.note! : 'No notes saved.',
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.6,
              color: colors.secondaryText,
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(int timestamp) {
    if (timestamp <= 0) return 'Never';
    return DateFormat('MMM d, y • HH:mm').format(
      DateTime.fromMillisecondsSinceEpoch(timestamp),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.colors,
    required this.child,
  });

  final String title;
  final dynamic colors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.secondaryBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.primaryBorder.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.secondaryText,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.colors,
    required this.title,
    required this.value,
  });

  final dynamic colors;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.secondaryBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.primaryBorder.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.secondaryText,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: colors.primaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyValue extends StatelessWidget {
  const _KeyValue({
    required this.label,
    required this.value,
    required this.colors,
  });

  final String label;
  final String value;
  final dynamic colors;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.tertiaryText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colors.primaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailEmptyState extends StatelessWidget {
  const _DetailEmptyState({required this.colors});

  final dynamic colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      alignment: Alignment.center,
      child: Text(
        'No profile selected.',
        style: GoogleFonts.inter(fontSize: 15, color: colors.secondaryText),
      ),
    );
  }
}

class _DetailErrorState extends StatelessWidget {
  const _DetailErrorState({
    required this.message,
    required this.colors,
    required this.profileId,
  });

  final String message;
  final dynamic colors;
  final String? profileId;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.secondaryBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.primaryBorder.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            profileId == null ? 'Unable to load profile' : 'Unable to load $profileId',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.5,
              color: colors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}
