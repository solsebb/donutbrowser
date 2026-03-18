import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_shared_core/theme/models/app_theme.dart';
import 'package:flutter_shared_core/theme/providers/theme_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twitterbrowser_flutter/features/auth/data/providers/auth_providers.dart';
import 'package:twitterbrowser_flutter/features/auth/presentation/widgets/web_language_selector.dart';
import 'package:twitterbrowser_flutter/features/profiles/data/models/local_companion_status.dart';
import 'package:twitterbrowser_flutter/features/auth/presentation/widgets/web_theme_selector.dart';
import 'package:twitterbrowser_flutter/features/profiles/presentation/providers/profile_providers.dart';
import 'package:twitterbrowser_flutter/shared/widgets/brand_logo.dart';

class SourceEntryScreen extends ConsumerWidget {
  const SourceEntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go('/auth');
        }
      });
    }

    final colors = ref.watch(themeColorsProvider);
    final localStatus = ref.watch(localCompanionStatusProvider);

    return CupertinoPageScaffold(
      backgroundColor: colors.primaryBackground,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: const SafeArea(
              child: Row(
                children: [
                  BrandLogo(height: 24),
                  SizedBox(width: 16),
                  WebLanguageSelector(),
                  SizedBox(width: 8),
                  WebThemeSelector(),
                ],
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 24,
                ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final stacked = constraints.maxWidth < 860;

                    return Flex(
                      direction: stacked ? Axis.vertical : Axis.horizontal,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _InfoPanel(colors: colors),
                        ),
                        SizedBox(
                          width: stacked ? 0 : 28,
                          height: stacked ? 28 : 0,
                        ),
                        Expanded(
                          child: _SelectorPanel(
                            colors: colors,
                            localStatus: localStatus,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.colors});

  final AppThemeColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colors.secondaryBackground,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.primaryBorder.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose how you want to open TwitterBrowser data.',
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 36,
              fontWeight: FontWeight.w700,
              height: 1.15,
              letterSpacing: -1.0,
            ).copyWith(color: colors.primaryText),
          ),
          const SizedBox(height: 18),
          Text(
            'Use the local desktop companion on this Mac or continue into the hosted account flow. The hosted auth screen stays identical to the IntentBot-style web flow once you choose it.',
            style: GoogleFonts.inter(
              fontSize: 16,
              height: 1.7,
              color: colors.secondaryText,
            ),
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              _FeaturePill(label: 'IntentBot-style auth'),
              _FeaturePill(label: 'Hosted + local sources'),
              _FeaturePill(label: 'Profiles workspace'),
              _FeaturePill(label: 'Read-only companion'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectorPanel extends ConsumerWidget {
  const _SelectorPanel({
    required this.colors,
    required this.localStatus,
  });

  final AppThemeColors colors;
  final AsyncValue<LocalCompanionStatus?> localStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusText = localStatus.when(
      data: (status) {
        if (status == null) {
          return 'Local desktop status will appear here when the companion API is available.';
        }
        return 'Local desktop detected on port ${status.port}. You can open profiles directly from this Mac.';
      },
      loading: () => 'Checking for the local TwitterBrowser desktop API…',
      error: (_, __) =>
          'Local desktop status is unavailable right now. You can still use the hosted account flow.',
    );

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: colors.secondaryBackground,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.primaryBorder.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Open TwitterBrowser',
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.2,
              letterSpacing: -0.4,
            ).copyWith(color: colors.primaryText),
          ),
          const SizedBox(height: 12),
          Text(
            statusText,
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.6,
              color: colors.secondaryText,
            ),
          ),
          const SizedBox(height: 24),
          _ModeButton(
            title: 'Hosted account',
            subtitle: 'Supabase auth, Google sign-in, and hosted profile viewing.',
            onPressed: () {
              ref.read(profileSourceModeProvider.notifier).state =
                  ProfileSourceMode.hosted;
              context.go('/auth');
            },
          ),
          const SizedBox(height: 12),
          _ModeButton(
            title: 'Local desktop',
            subtitle:
                'Read profiles directly from the TwitterBrowser app running on this Mac.',
            onPressed: () {
              ref.read(profileSourceModeProvider.notifier).state =
                  ProfileSourceMode.local;
              context.go('/app/profiles');
            },
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends ConsumerWidget {
  const _ModeButton({
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeColorsProvider);

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: colors.primaryBorder.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF918DF6).withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                CupertinoIcons.arrow_right_circle_fill,
                color: Color(0xFF918DF6),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.55,
                      color: colors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturePill extends ConsumerWidget {
  const _FeaturePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeColorsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.primaryBorder.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: colors.primaryText,
        ),
      ),
    );
  }
}
