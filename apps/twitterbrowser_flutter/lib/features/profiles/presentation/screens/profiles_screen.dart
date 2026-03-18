import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_shared_core/theme/models/app_theme.dart';
import 'package:flutter_shared_core/theme/providers/theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twitterbrowser_flutter/features/auth/data/providers/auth_providers.dart';
import 'package:twitterbrowser_flutter/features/profiles/data/models/browser_profile_summary.dart';
import 'package:twitterbrowser_flutter/features/profiles/presentation/providers/profile_providers.dart';
import 'package:twitterbrowser_flutter/features/profiles/presentation/screens/profile_detail_screen.dart';
import 'package:twitterbrowser_flutter/features/profiles/presentation/widgets/profiles_browser_filter_button.dart';
import 'package:twitterbrowser_flutter/features/profiles/presentation/widgets/profiles_empty_state.dart';
import 'package:twitterbrowser_flutter/features/profiles/presentation/widgets/profiles_filter_button.dart';
import 'package:twitterbrowser_flutter/features/profiles/presentation/widgets/profiles_table.dart';
import 'package:twitterbrowser_flutter/shared/widgets/rounded_button.dart';

class ProfilesScreen extends ConsumerStatefulWidget {
  const ProfilesScreen({super.key});

  @override
  ConsumerState<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends ConsumerState<ProfilesScreen> {
  @override
  Widget build(BuildContext context) {
    final selectedProfileId = ref.watch(selectedProfileIdProvider);
    if (selectedProfileId != null) {
      return const ProfileDetailScreen();
    }

    final colors = ref.watch(themeColorsProvider);
    final isLightTheme = colors == AppThemeColors.light;
    final sourceMode = ref.watch(profileSourceModeProvider);
    final profilesAsync = ref.watch(currentProfilesProvider);
    final profilesState = ref.watch(profilesViewStateProvider);
    final filteredProfiles = ref.watch(filteredProfilesProvider);
    final hostedAccount = ref.watch(hostedAccountProfileProvider).valueOrNull;
    final localStatus = ref.watch(localCompanionStatusProvider);

    return Container(
      color: colors.primaryBackground,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: _buildHeader(
                colors: colors,
                sourceMode: sourceMode,
                hostedAccount: hostedAccount,
                onPrimaryAction: () async {
                  if (sourceMode == ProfileSourceMode.hosted &&
                      hostedAccount != null &&
                      !hostedAccount.hostedSyncEnabled) {
                    await ref.read(hostedAuthServiceProvider).enableHostedSync();
                    ref.invalidate(hostedAccountProfileProvider);
                  }
                  ref.invalidate(currentProfilesProvider);
                  ref.invalidate(selectedProfileProvider);
                  ref.invalidate(localCompanionStatusProvider);
                },
              ),
            ),
          ),
          ..._buildProfilesListSlivers(
            colors: colors,
            isLightTheme: isLightTheme,
            sourceMode: sourceMode,
            profilesAsync: profilesAsync,
            filteredProfiles: filteredProfiles,
            profilesState: profilesState,
            hostedAccount: hostedAccount,
            localStatus: localStatus,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader({
    required dynamic colors,
    required ProfileSourceMode sourceMode,
    required dynamic hostedAccount,
    required Future<void> Function() onPrimaryAction,
  }) {
    final showEnableSync =
        sourceMode == ProfileSourceMode.hosted &&
        hostedAccount != null &&
        !hostedAccount.hostedSyncEnabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profiles',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: colors.primaryText,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Spacer(),
            const ProfilesBrowserFilterButton(),
            const SizedBox(width: 8),
            const ProfilesFilterButton(),
            const SizedBox(width: 8),
            RoundedButton(
              text: showEnableSync ? 'Enable sync' : 'Refresh',
              onPressed: () async {
                HapticFeedback.lightImpact();
                await onPrimaryAction();
              },
              backgroundColor: colors.primaryText,
              textColor: colors.primaryBackground,
              borderColor: colors.primaryText.withValues(alpha: 0.2),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildProfilesListSlivers({
    required dynamic colors,
    required bool isLightTheme,
    required ProfileSourceMode sourceMode,
    required AsyncValue<List<BrowserProfileSummary>> profilesAsync,
    required List<BrowserProfileSummary> filteredProfiles,
    required ProfilesViewState profilesState,
    required dynamic hostedAccount,
    required AsyncValue<dynamic> localStatus,
  }) {
    if (sourceMode == ProfileSourceMode.local) {
      if (localStatus.isLoading) {
        return const [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CupertinoActivityIndicator()),
          ),
        ];
      }

      final localError = localStatus.asError?.error;
      if (localError != null) {
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: ProfilesEmptyState(
              colors: colors,
              isLightTheme: isLightTheme,
              title: 'Open TwitterBrowser desktop',
              description: localError.toString(),
              buttonLabel: 'Refresh',
              onPressed: () {
                ref.invalidate(localCompanionStatusProvider);
                ref.invalidate(currentProfilesProvider);
              },
              iconAssetPath: 'assets/icons/home_RoundedFill.svg',
            ),
          ),
        ];
      }
    }

    if (sourceMode == ProfileSourceMode.hosted &&
        hostedAccount != null &&
        !hostedAccount.hostedSyncEnabled) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: ProfilesEmptyState(
            colors: colors,
            isLightTheme: isLightTheme,
            title: 'Enable hosted sync',
            description:
                'Turn on hosted sync to make profile metadata available in this workspace.',
            buttonLabel: 'Enable sync',
            onPressed: () async {
              await ref.read(hostedAuthServiceProvider).enableHostedSync();
              ref.invalidate(hostedAccountProfileProvider);
              ref.invalidate(currentProfilesProvider);
            },
            icon: CupertinoIcons.cloud,
          ),
        ),
      ];
    }

    if (profilesAsync.isLoading) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CupertinoActivityIndicator()),
        ),
      ];
    }

    final profilesError = profilesAsync.asError?.error;
    if (profilesError != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: ProfilesEmptyState(
            colors: colors,
            isLightTheme: isLightTheme,
            title: 'Unable to load profiles',
            description: profilesError.toString(),
            buttonLabel: 'Retry',
            onPressed: () => ref.invalidate(currentProfilesProvider),
            icon: CupertinoIcons.exclamationmark_circle,
          ),
        ),
      ];
    }

    final allProfiles = profilesAsync.valueOrNull ?? const <BrowserProfileSummary>[];
    if (allProfiles.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: ProfilesEmptyState(
            colors: colors,
            isLightTheme: isLightTheme,
            title: 'No profiles yet',
            description: sourceMode == ProfileSourceMode.local
                ? 'Launch TwitterBrowser and create your first profile to see it here.'
                : 'Profiles will appear here after they have been synced to your hosted workspace.',
            buttonLabel: 'Refresh',
            onPressed: () => ref.invalidate(currentProfilesProvider),
            icon: CupertinoIcons.person_2,
          ),
        ),
      ];
    }

    if (filteredProfiles.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: ProfilesEmptyState(
            colors: colors,
            isLightTheme: isLightTheme,
            title: 'No profiles found',
            description: 'Try clearing the active filters to show more profiles.',
            buttonLabel: 'Clear filters',
            onPressed: () {
              ref.read(profilesViewStateProvider.notifier).state = profilesState.copyWith(
                statusFilter: ProfilesStatusFilter.all,
                clearBrowserFilter: true,
                query: '',
              );
            },
            icon: CupertinoIcons.search,
          ),
        ),
      ];
    }

    return [
      CupertinoSliverRefreshControl(
        onRefresh: () async {
          ref.invalidate(currentProfilesProvider);
          ref.invalidate(localCompanionStatusProvider);
          ref.invalidate(hostedAccountProfileProvider);
        },
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        sliver: SliverToBoxAdapter(
          child: ProfilesTable(
            profiles: filteredProfiles,
            colors: colors,
            isLightTheme: isLightTheme,
            onOpen: (profile) {
              ref.read(selectedProfileIdProvider.notifier).state = profile.id;
            },
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 100)),
    ];
  }
}
