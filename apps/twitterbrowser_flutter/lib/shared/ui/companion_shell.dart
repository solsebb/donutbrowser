import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:twitterbrowser_flutter/features/auth/data/providers/auth_providers.dart';
import 'package:twitterbrowser_flutter/features/shell/data/providers/shell_providers.dart';
import 'package:twitterbrowser_flutter/shared/ui/companion_components.dart';

class CompanionShell extends ConsumerWidget {
  const CompanionShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(companionDestinationProvider.notifier).state =
        CompanionDestination.profiles;

    final theme = Theme.of(context);
    final sourceMode = ref.watch(profileSourceModeProvider);
    final account = ref.watch(hostedAccountProfileProvider).valueOrNull;
    final isWide = MediaQuery.sizeOf(context).width >= 1120;

    return Scaffold(
      body: CompanionScaffoldBackground(
        child: SafeArea(
          child: Row(
            children: [
              if (isWide)
                _ShellSidebar(
                  sourceLabel: sourceMode == ProfileSourceMode.local
                      ? 'Local TwitterBrowser'
                      : 'Hosted account',
                  accountLabel: sourceMode == ProfileSourceMode.hosted
                      ? (account?.email ?? 'Signed out')
                      : 'Desktop companion',
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CompanionPanel(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 18,
                        ),
                        child: Row(
                          children: [
                            if (!isWide)
                              Builder(
                                builder: (context) {
                                  return IconButton.filledTonal(
                                    onPressed: () {
                                      Scaffold.of(context).openDrawer();
                                    },
                                    icon: const Icon(Icons.menu_rounded),
                                  );
                                },
                              ),
                            if (!isWide) const SizedBox(width: 14),
                            const Expanded(
                              child: CompanionBrandLockup(compact: true),
                            ),
                            CompanionTag(
                              label: sourceMode == ProfileSourceMode.local
                                  ? 'Local source'
                                  : 'Hosted source',
                              accent: sourceMode == ProfileSourceMode.local
                                  ? theme.colorScheme.tertiary
                                  : theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            if (sourceMode == ProfileSourceMode.hosted &&
                                account != null)
                              _HeaderUserPill(email: account.email),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: () => context.go('/auth'),
                              icon: const Icon(Icons.swap_horiz_rounded),
                              label: const Text('Switch source'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      drawer: isWide
          ? null
          : Drawer(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _DrawerContent(
                    sourceLabel: sourceMode == ProfileSourceMode.local
                        ? 'Local TwitterBrowser'
                        : 'Hosted account',
                    accountLabel: sourceMode == ProfileSourceMode.hosted
                        ? (account?.email ?? 'Signed out')
                        : 'Desktop companion',
                  ),
                ),
              ),
            ),
    );
  }
}

class _ShellSidebar extends StatelessWidget {
  const _ShellSidebar({required this.sourceLabel, required this.accountLabel});

  final String sourceLabel;
  final String accountLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 300,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 0, 20),
        child: CompanionPanel(
          child: _DrawerContent(
            sourceLabel: sourceLabel,
            accountLabel: accountLabel,
            desktop: true,
            tone: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _DrawerContent extends ConsumerWidget {
  const _DrawerContent({
    required this.sourceLabel,
    required this.accountLabel,
    this.desktop = false,
    this.tone,
  });

  final String sourceLabel;
  final String accountLabel;
  final bool desktop;
  final Color? tone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = tone ?? theme.colorScheme.primary;
    final destination = ref.watch(companionDestinationProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CompanionBrandLockup(),
        const SizedBox(height: 28),
        Text(
          'Workspace',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        _SidebarNavTile(
          icon: Icons.account_tree_outlined,
          label: 'Profiles',
          selected: destination == CompanionDestination.profiles,
          accent: accent,
          onTap: () {
            ref.read(companionDestinationProvider.notifier).state =
                CompanionDestination.profiles;
            context.go('/app/profiles');
            if (!desktop && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        const Spacer(),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.34,
            ),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current source',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(sourceLabel, style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                accountLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderUserPill extends StatelessWidget {
  const _HeaderUserPill({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.16),
            child: Text(
              email.isEmpty ? '?' : email[0].toUpperCase(),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              email,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarNavTile extends StatelessWidget {
  const _SidebarNavTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: selected ? accent.withValues(alpha: 0.14) : Colors.transparent,
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: 0.28)
                : theme.colorScheme.outline.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? accent : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: selected
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
