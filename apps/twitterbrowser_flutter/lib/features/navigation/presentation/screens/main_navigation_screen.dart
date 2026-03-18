import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_shared_core/theme/providers/theme_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twitterbrowser_flutter/features/auth/data/providers/auth_providers.dart';
import 'package:twitterbrowser_flutter/features/profiles/presentation/providers/profile_providers.dart';
import 'package:twitterbrowser_flutter/features/settings/data/models/language_locale.dart';
import 'package:twitterbrowser_flutter/features/settings/data/providers/language_locale_provider.dart';
import 'package:twitterbrowser_flutter/shared/widgets/brand_logo.dart';
import 'package:twitterbrowser_flutter/shared/widgets/rounded_button.dart';

class MainNavigationScreen extends ConsumerWidget {
  const MainNavigationScreen({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeColorsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final brightness = MediaQuery.of(context).platformBrightness;
    final isLightTheme =
        themeMode == AppThemeMode.light ||
        (themeMode == AppThemeMode.system && brightness == Brightness.light);

    return CupertinoPageScaffold(
      backgroundColor: colors.primaryBackground,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            _Sidebar(isLightTheme: isLightTheme),
            Expanded(
              child: Column(
                children: [
                  _WorkspaceTopBar(isLightTheme: isLightTheme),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({required this.isLightTheme});

  final bool isLightTheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeColorsProvider);
    final sourceMode = ref.watch(profileSourceModeProvider);
    final hostedAccount = ref.watch(hostedAccountProfileProvider).valueOrNull;
    final localStatus = ref.watch(localCompanionStatusProvider).valueOrNull;
    final navBarBgColor =
        isLightTheme ? const Color(0xFFF8F8F6) : colors.secondaryBackground;

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: navBarBgColor,
        border: Border(
          right: BorderSide(
            color: colors.primaryBorder.withValues(alpha: 0.32),
          ),
        ),
      ),
      child: SafeArea(
        right: false,
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: 62,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: const [
                    BrandLogo.icon(size: 26),
                    SizedBox(width: 12),
                    BrandLogo(height: 20),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SidebarSectionLabel(
                      title: 'Engage',
                      isLightTheme: isLightTheme,
                    ),
                    const SizedBox(height: 8),
                    _SidebarItem(
                      iconPath: 'assets/icons/chat_RoundedFill.svg',
                      label: 'Profiles',
                      selected: true,
                      isLightTheme: isLightTheme,
                      onTap: () => context.go('/app/profiles'),
                    ),
                    const SizedBox(height: 24),
                    _SidebarSectionLabel(
                      title: 'Data',
                      isLightTheme: isLightTheme,
                    ),
                    const SizedBox(height: 8),
                    _SourceSummaryTile(
                      sourceMode: sourceMode,
                      hostedAccount: hostedAccount,
                      localStatus: localStatus,
                      isLightTheme: isLightTheme,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: [
                  _AccountCard(
                    sourceMode: sourceMode,
                    hostedAccount: hostedAccount,
                    isLightTheme: isLightTheme,
                    onSignOut: sourceMode == ProfileSourceMode.hosted
                        ? () async {
                            await ref.read(hostedAuthServiceProvider).signOut();
                            if (context.mounted) {
                              context.go('/auth');
                            }
                          }
                        : null,
                  ),
                  const SizedBox(height: 12),
                  const _SidebarFooterRow(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceTopBar extends ConsumerWidget {
  const _WorkspaceTopBar({required this.isLightTheme});

  final bool isLightTheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeColorsProvider);
    final sourceMode = ref.watch(profileSourceModeProvider);
    final hostedAccount = ref.watch(hostedAccountProfileProvider).valueOrNull;

    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colors.primaryBorder.withValues(alpha: 0.38),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'App',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colors.secondaryText,
            ),
          ),
          Text(
            ' / ',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colors.secondaryText,
            ),
          ),
          Text(
            'Profiles',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.primaryText,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: colors.accentPrimary,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const Spacer(),
          _TopHeaderChip(
            label: sourceMode == ProfileSourceMode.hosted
                ? 'Hosted account'
                : 'Local desktop',
            selected: false,
            isLightTheme: isLightTheme,
          ),
          if (sourceMode == ProfileSourceMode.hosted && hostedAccount != null) ...[
            const SizedBox(width: 12),
            _TopHeaderChip(
              label: hostedAccount.email,
              selected: false,
              isLightTheme: isLightTheme,
            ),
          ],
        ],
      ),
    );
  }
}

class _SidebarSectionLabel extends ConsumerWidget {
  const _SidebarSectionLabel({
    required this.title,
    required this.isLightTheme,
  });

  final String title;
  final bool isLightTheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeColorsProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isLightTheme
              ? const Color(0xFF888888)
              : colors.secondaryText.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

class _SidebarItem extends ConsumerWidget {
  const _SidebarItem({
    required this.iconPath,
    required this.label,
    required this.selected,
    required this.isLightTheme,
    required this.onTap,
  });

  final String iconPath;
  final String label;
  final bool selected;
  final bool isLightTheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeColorsProvider);
    final selectedBackground = isLightTheme
        ? CupertinoColors.white
        : colors.cardBackground;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? selectedBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: selected
              ? Border.all(
                  color: colors.primaryBorder.withValues(alpha: 0.42),
                )
              : null,
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              iconPath,
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(
                selected ? colors.primaryText : colors.secondaryText,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: selected ? colors.primaryText : colors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceSummaryTile extends ConsumerWidget {
  const _SourceSummaryTile({
    required this.sourceMode,
    required this.hostedAccount,
    required this.localStatus,
    required this.isLightTheme,
  });

  final ProfileSourceMode sourceMode;
  final dynamic hostedAccount;
  final dynamic localStatus;
  final bool isLightTheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeColorsProvider);
    final title = sourceMode == ProfileSourceMode.hosted
        ? 'Hosted sync'
        : 'Local companion';
    final subtitle = sourceMode == ProfileSourceMode.hosted
        ? (hostedAccount?.hostedSyncEnabled == true
              ? 'Connected to the hosted catalog.'
              : 'Sign in and enable sync to view hosted profiles.')
        : (localStatus == null
              ? 'Waiting for the TwitterBrowser desktop API.'
              : 'Connected to ${localStatus.baseUrl}');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isLightTheme ? CupertinoColors.white : colors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.primaryBorder.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.primaryText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.45,
              color: colors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends ConsumerWidget {
  const _AccountCard({
    required this.sourceMode,
    required this.hostedAccount,
    required this.isLightTheme,
    required this.onSignOut,
  });

  final ProfileSourceMode sourceMode;
  final dynamic hostedAccount;
  final bool isLightTheme;
  final Future<void> Function()? onSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeColorsProvider);
    final title = sourceMode == ProfileSourceMode.hosted
        ? 'Hosted account'
        : 'Local workspace';
    final subtitle = sourceMode == ProfileSourceMode.hosted
        ? (hostedAccount?.email ?? 'Connected through Supabase.')
        : 'Profiles are loaded from the running TwitterBrowser desktop app.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isLightTheme ? CupertinoColors.white : colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.primaryBorder.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.primaryText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.45,
              color: colors.secondaryText,
            ),
          ),
          if (sourceMode == ProfileSourceMode.hosted && onSignOut != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: RoundedButton(
                text: 'Sign out',
                onPressed: () async => onSignOut!(),
                backgroundColor: isLightTheme ? Colors.black : Colors.white,
                textColor: isLightTheme ? Colors.white : Colors.black,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SidebarFooterRow extends ConsumerWidget {
  const _SidebarFooterRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeColorsProvider);
    final currentLocale = ref.watch(languageLocaleProvider);
    final currentTheme = ref.watch(themeModeProvider);
    final hostedAccount = ref.watch(hostedAccountProfileProvider).valueOrNull;
    final sourceMode = ref.watch(profileSourceModeProvider);

    final accountLabel = sourceMode == ProfileSourceMode.hosted
        ? (hostedAccount?.email ?? 'Hosted')
        : 'Local';
    final initials = _initialsFromLabel(accountLabel);

    return SizedBox(
      width: double.infinity,
      height: 32,
      child: Row(
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size.square(20),
            onPressed: () => _showLanguageDropdown(context, ref),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SvgPicture.asset(
                currentLocale.flagAssetPath,
                width: 20,
                height: 20,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size.square(20),
            onPressed: () {
              final nextTheme = currentTheme == AppThemeMode.light
                  ? AppThemeMode.dark
                  : currentTheme == AppThemeMode.dark
                      ? AppThemeMode.system
                      : AppThemeMode.light;
              ref.read(themeModeProvider.notifier).setThemeMode(nextTheme);
            },
            child: Icon(
              switch (currentTheme) {
                AppThemeMode.light => CupertinoIcons.sun_max_fill,
                AppThemeMode.dark => CupertinoIcons.moon_fill,
                AppThemeMode.system => CupertinoIcons.device_laptop,
              },
              size: 18,
              color: colors.secondaryText.withValues(alpha: 0.72),
            ),
          ),
          const Spacer(),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: colors.secondaryBackground,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: colors.primaryBorder.withValues(alpha: 0.4),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colors.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageDropdown(BuildContext context, WidgetRef ref) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (dialogContext) => CupertinoActionSheet(
        title: const Text('Language'),
        actions: LanguageLocale.supportedLanguages
            .map(
              (language) => CupertinoActionSheetAction(
                onPressed: () async {
                  await ref
                      .read(languageLocaleProvider.notifier)
                      .changeLocale(language);
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                },
                child: Text(language.displayName),
              ),
            )
            .toList(growable: false),
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  String _initialsFromLabel(String value) {
    final parts = value
        .split(RegExp(r'[\s@._-]+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList(growable: false);
    if (parts.isEmpty) {
      return 'TB';
    }
    return parts.map((part) => part.substring(0, 1).toUpperCase()).join();
  }
}

class _TopHeaderChip extends ConsumerWidget {
  const _TopHeaderChip({
    required this.label,
    required this.selected,
    required this.isLightTheme,
  });

  final String label;
  final bool selected;
  final bool isLightTheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeColorsProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: selected
            ? (isLightTheme ? CupertinoColors.white : colors.secondaryBackground)
            : (isLightTheme ? const Color(0xFFF7F7F4) : colors.secondaryBackground),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.primaryBorder.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: colors.primaryText,
        ),
      ),
    );
  }
}
