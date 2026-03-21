import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twitterbrowser_flutter/features/auth/data/providers/auth_providers.dart';
import 'package:twitterbrowser_flutter/features/profiles/data/models/browser_profile_summary.dart';
import 'package:twitterbrowser_flutter/features/profiles/data/models/local_companion_status.dart';
import 'package:twitterbrowser_flutter/features/profiles/data/repositories/profiles_repositories.dart';
import 'package:twitterbrowser_flutter/features/profiles/data/services/local_companion_discovery.dart';

enum ProfilesSortField { name, browser, lastActivity, source }
enum ProfilesStatusFilter { all, running, available }

class ProfilesViewState {
  const ProfilesViewState({
    this.query = '',
    this.sortField = ProfilesSortField.name,
    this.descending = false,
    this.statusFilter = ProfilesStatusFilter.all,
    this.browserFilter,
  });

  final String query;
  final ProfilesSortField sortField;
  final bool descending;
  final ProfilesStatusFilter statusFilter;
  final String? browserFilter;

  ProfilesViewState copyWith({
    String? query,
    ProfilesSortField? sortField,
    bool? descending,
    ProfilesStatusFilter? statusFilter,
    String? browserFilter,
    bool clearBrowserFilter = false,
  }) {
    return ProfilesViewState(
      query: query ?? this.query,
      sortField: sortField ?? this.sortField,
      descending: descending ?? this.descending,
      statusFilter: statusFilter ?? this.statusFilter,
      browserFilter: clearBrowserFilter ? null : browserFilter ?? this.browserFilter,
    );
  }
}

final localCompanionDiscoveryServiceProvider =
    Provider<LocalCompanionDiscoveryService>((ref) {
      final config = ref.watch(appConfigProvider);
      return createLocalCompanionDiscoveryService(config);
    });

final localProfilesRepositoryProvider = Provider<LocalProfilesRepository>((
  ref,
) {
  final discovery = ref.watch(localCompanionDiscoveryServiceProvider);
  return LocalProfilesRepository(discovery);
});

final hostedProfilesRepositoryProvider = Provider<HostedProfilesRepository>((
  ref,
) {
  final authService = ref.watch(hostedAuthServiceProvider);
  return HostedProfilesRepository(authService);
});

final localCompanionStatusProvider = FutureProvider<LocalCompanionStatus?>((
  ref,
) async {
  final sourceMode = ref.watch(profileSourceModeProvider);
  if (sourceMode != ProfileSourceMode.local) {
    return null;
  }

  final repository = ref.watch(localProfilesRepositoryProvider);
  return repository.getCompanionStatus();
});

final profilesViewStateProvider = StateProvider<ProfilesViewState>((ref) {
  return const ProfilesViewState();
});

final selectedProfileIdsProvider = StateProvider<Set<String>>((ref) => <String>{});

final selectedProfileIdProvider = StateProvider<String?>((ref) => null);

final currentProfilesProvider = FutureProvider<List<BrowserProfileSummary>>((
  ref,
) async {
  final sourceMode = ref.watch(profileSourceModeProvider);
  switch (sourceMode) {
    case ProfileSourceMode.local:
      return ref.watch(localProfilesRepositoryProvider).fetchProfiles();
    case ProfileSourceMode.hosted:
      final account = await ref.watch(hostedAccountProfileProvider.future);
      if (account == null || !account.hostedSyncEnabled) {
        return const [];
      }
      return ref.watch(hostedProfilesRepositoryProvider).fetchProfiles();
  }
});

final filteredProfilesProvider = Provider<List<BrowserProfileSummary>>((ref) {
  final viewState = ref.watch(profilesViewStateProvider);
  final profiles = ref.watch(currentProfilesProvider).valueOrNull ?? const [];

  final filtered = profiles
      .where((profile) => profile.matchesQuery(viewState.query))
      .where((profile) {
        return switch (viewState.statusFilter) {
          ProfilesStatusFilter.all => true,
          ProfilesStatusFilter.running => profile.isRunning,
          ProfilesStatusFilter.available => !profile.isRunning,
        };
      })
      .where((profile) {
        final browserFilter = viewState.browserFilter?.trim();
        if (browserFilter == null || browserFilter.isEmpty) {
          return true;
        }
        return profile.browser.toLowerCase() == browserFilter.toLowerCase();
      })
      .toList(growable: false);

  int compare(BrowserProfileSummary a, BrowserProfileSummary b) {
    switch (viewState.sortField) {
      case ProfilesSortField.name:
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      case ProfilesSortField.browser:
        return '${a.browser}-${a.version}'.toLowerCase().compareTo(
          '${b.browser}-${b.version}'.toLowerCase(),
        );
      case ProfilesSortField.lastActivity:
        return (a.lastSync ?? a.lastLaunch ?? 0).compareTo(
          b.lastSync ?? b.lastLaunch ?? 0,
        );
      case ProfilesSortField.source:
        return a.sourceLabel.compareTo(b.sourceLabel);
    }
  }

  filtered.sort(compare);
  if (viewState.descending) {
    return filtered.reversed.toList(growable: false);
  }
  return filtered;
});

final availableProfileBrowsersProvider = Provider<List<String>>((ref) {
  final profiles = ref.watch(currentProfilesProvider).valueOrNull ?? const [];
  final browsers = profiles
      .map((profile) => profile.browser.trim())
      .where((browser) => browser.isNotEmpty)
      .toSet()
      .toList(growable: false)
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return browsers;
});

final selectedProfileProvider = FutureProvider<BrowserProfileSummary?>((
  ref,
) async {
  final selectedId = ref.watch(selectedProfileIdProvider);
  if (selectedId == null || selectedId.isEmpty) {
    return null;
  }

  final sourceMode = ref.watch(profileSourceModeProvider);
  switch (sourceMode) {
    case ProfileSourceMode.local:
      return ref
          .watch(localProfilesRepositoryProvider)
          .fetchProfile(selectedId);
    case ProfileSourceMode.hosted:
      final account = await ref.watch(hostedAccountProfileProvider.future);
      if (account == null || !account.hostedSyncEnabled) {
        return null;
      }
      return ref
          .watch(hostedProfilesRepositoryProvider)
          .fetchProfile(selectedId);
  }
});
