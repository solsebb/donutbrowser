import 'dart:ui';

import 'package:flutter/material.dart';

class CompanionScaffoldBackground extends StatelessWidget {
  const CompanionScaffoldBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.scaffoldBackgroundColor,
            theme.colorScheme.surface,
            theme.scaffoldBackgroundColor,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            left: -80,
            child: _GlowOrb(
              color: theme.colorScheme.primary.withValues(alpha: 0.16),
              size: 320,
            ),
          ),
          Positioned(
            right: -120,
            bottom: -180,
            child: _GlowOrb(
              color: theme.colorScheme.tertiary.withValues(alpha: 0.14),
              size: 420,
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _GridPainter(
                  color: theme.colorScheme.outline.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class CompanionPanel extends StatelessWidget {
  const CompanionPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: theme.colorScheme.surface.withValues(alpha: 0.88),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.28),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 32,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class CompanionBrandLockup extends StatelessWidget {
  const CompanionBrandLockup({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 42 : 54,
          height: compact ? 42 : 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 14 : 18),
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withValues(alpha: 0.74),
              ],
            ),
          ),
          child: Icon(
            Icons.alternate_email_rounded,
            color: theme.colorScheme.onPrimary,
            size: compact ? 20 : 26,
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'TwitterBrowser',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              compact ? 'Profiles companion' : 'Profiles companion workspace',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class CompanionSectionHeading extends StatelessWidget {
  const CompanionSectionHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Text(title, style: theme.textTheme.headlineMedium),
              if (subtitle case final value?) ...[
                const SizedBox(height: 10),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 16), trailing!],
      ],
    );
  }
}

class CompanionMetricCard extends StatelessWidget {
  const CompanionMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accent,
    this.caption,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? accent;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = accent ?? theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.38,
        ),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: tone, size: 20),
              ),
              const Spacer(),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (caption case final detail?) ...[
            const SizedBox(height: 6),
            Text(
              detail,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class CompanionStatusBanner extends StatelessWidget {
  const CompanionStatusBanner({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.tone,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color? tone;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedTone = tone ?? theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: resolvedTone.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: resolvedTone.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: resolvedTone, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

class CompanionEmptyState extends StatelessWidget {
  const CompanionEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 30),
            ),
            const SizedBox(height: 18),
            Text(title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}

class CompanionTag extends StatelessWidget {
  const CompanionTag({super.key, required this.label, this.accent});

  final String label;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = accent ?? theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: tone,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 44.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    for (double dx = 0; dx < size.width; dx += spacing) {
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), paint);
    }
    for (double dy = 0; dy < size.height; dy += spacing) {
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
