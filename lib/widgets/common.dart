import 'package:flutter/material.dart';

import '../format.dart';
import '../theme.dart';

enum StatusTone { success, error, warning, info, primary, neutral }

class StatusPill extends StatelessWidget {
  const StatusPill({
    required this.label,
    this.icon,
    this.tone = StatusTone.neutral,
    this.dense = false,
    this.onTap,
    super.key,
  });

  final String label;
  final IconData? icon;
  final StatusTone tone;
  final bool dense;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final colors = _toneColors(scheme, dark, tone);

    final padding = dense
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 4)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 6);

    final content = Container(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
      ),
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 13 : 15, color: colors.foreground),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: colors.foreground,
              fontSize: dense ? 11.5 : 12.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: content,
    );
  }

  static _ToneColors _toneColors(
      ColorScheme scheme, bool dark, StatusTone tone) {
    Color base;
    switch (tone) {
      case StatusTone.success:
        base = AppPalette.emerald;
        break;
      case StatusTone.error:
        base = AppPalette.coral;
        break;
      case StatusTone.warning:
        base = AppPalette.amber;
        break;
      case StatusTone.info:
        base = AppPalette.cyan;
        break;
      case StatusTone.primary:
        base = scheme.primary;
        break;
      case StatusTone.neutral:
        base = dark
            ? Colors.white.withValues(alpha: 0.7)
            : const Color(0xFF475569);
    }
    return _ToneColors(
      background: base.withValues(alpha: dark ? 0.18 : 0.12),
      border: base.withValues(alpha: dark ? 0.32 : 0.22),
      foreground: dark ? Color.lerp(base, Colors.white, 0.18)! : base,
    );
  }
}

class _ToneColors {
  const _ToneColors({
    required this.background,
    required this.border,
    required this.foreground,
  });

  final Color background;
  final Color border;
  final Color foreground;
}

class MetricRing extends StatelessWidget {
  const MetricRing({
    required this.value,
    required this.label,
    this.caption,
    this.size = 110,
    this.thickness = 10,
    this.color,
    this.icon,
    super.key,
  });

  final double value;
  final String label;
  final String? caption;
  final double size;
  final double thickness;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ringColor = color ?? scheme.primary;
    final clamped = value.isFinite ? value.clamp(0.0, 1.0) : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: 1,
                  strokeWidth: thickness,
                  valueColor: AlwaysStoppedAnimation(
                    dark
                        ? Colors.white.withValues(alpha: 0.07)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
              ),
              TweenAnimationBuilder<double>(
                duration: AppMotion.slow,
                curve: Curves.easeOutCubic,
                tween: Tween<double>(begin: 0, end: clamped),
                builder: (context, animated, _) => SizedBox(
                  width: size,
                  height: size,
                  child: CircularProgressIndicator(
                    value: animated,
                    strokeCap: StrokeCap.round,
                    strokeWidth: thickness,
                    valueColor: AlwaysStoppedAnimation(ringColor),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: ringColor, size: 18),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    '${(clamped * 100).toStringAsFixed(clamped >= 0.1 ? 0 : 1)}%',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
        ),
        if (caption != null) ...[
          const SizedBox(height: 2),
          Text(
            caption!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: dark
                      ? Colors.white.withValues(alpha: 0.6)
                      : Colors.black.withValues(alpha: 0.55),
                ),
          ),
        ],
      ],
    );
  }
}

class HueAvatar extends StatelessWidget {
  const HueAvatar({
    required this.seed,
    required this.label,
    this.size = 48,
    this.statusTone,
    super.key,
  });

  final String seed;
  final String label;
  final double size;
  final StatusTone? statusTone;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final hue = hueFromString(seed);
    final gradient = AppGradients.ofHue(hue, brightness: brightness);

    final initials = monogramFor(label);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(size * 0.32),
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withValues(alpha: 0.32),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: size * 0.36,
                letterSpacing: 0.4,
              ),
            ),
          ),
          if (statusTone != null)
            Positioned(
              right: -2,
              bottom: -2,
              child: PulseDot(tone: statusTone!),
            ),
        ],
      ),
    );
  }
}

class PulseDot extends StatefulWidget {
  const PulseDot({required this.tone, this.size = 14, super.key});

  final StatusTone tone;
  final double size;

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _baseColor() {
    switch (widget.tone) {
      case StatusTone.success:
        return AppPalette.emerald;
      case StatusTone.error:
        return AppPalette.coral;
      case StatusTone.warning:
        return AppPalette.amber;
      case StatusTone.info:
        return AppPalette.cyan;
      case StatusTone.primary:
        return AppPalette.indigo;
      case StatusTone.neutral:
        return AppPalette.slate700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final base = _baseColor();
    return SizedBox(
      width: widget.size + 12,
      height: widget.size + 12,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = _ctrl.value;
          return CustomPaint(
            painter: _PulsePainter(
              color: base,
              progress: t,
              dotSize: widget.size,
            ),
          );
        },
      ),
    );
  }
}

class _PulsePainter extends CustomPainter {
  _PulsePainter({
    required this.color,
    required this.progress,
    required this.dotSize,
  });

  final Color color;
  final double progress;
  final double dotSize;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    final ringRadius = dotSize / 2 + (maxRadius - dotSize / 2) * progress;
    final ringAlpha = (1 - progress) * 0.5;
    if (ringAlpha > 0) {
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = color.withValues(alpha: ringAlpha);
      canvas.drawCircle(center, ringRadius, paint);
    }
    final dotPaint = Paint()..color = color;
    canvas.drawCircle(center, dotSize / 2, dotPaint);
    final outlinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, dotSize / 2, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant _PulsePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.dotSize != dotSize;
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.icon,
    this.subtitle,
    this.trailing,
    super.key,
  });

  final String title;
  final IconData? icon;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, AppSpacing.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: scheme.primary, size: 18),
            ),
            const SizedBox(width: AppSpacing.s),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.m),
    this.tint,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final base = (tint ?? scheme.surface).withValues(alpha: dark ? 0.86 : 1.0);
    final border = dark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.06);

    return Container(
      decoration: BoxDecoration(
        color: base,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.cloud_outlined,
    super.key,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primary.withValues(alpha: 0.18),
                      scheme.tertiary.withValues(alpha: 0.16),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(icon, size: 44, color: scheme.primary),
              ),
              const SizedBox(height: AppSpacing.m),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.m),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({required this.message, this.onRetry, super.key});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.5),
        border: Border.all(color: scheme.error.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: scheme.error.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.warning_amber_rounded, color: scheme.error),
          ),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connection failed',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: scheme.onErrorContainer,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onErrorContainer.withValues(alpha: 0.9),
                      ),
                ),
              ],
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: AppSpacing.s),
            IconButton.filledTonal(
              onPressed: onRetry,
              tooltip: 'Retry',
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ],
      ),
    );
  }
}

class SkeletonBlock extends StatefulWidget {
  const SkeletonBlock({
    required this.height,
    this.width = double.infinity,
    this.radius = AppRadius.md,
    super.key,
  });

  final double height;
  final double width;
  final double radius;

  @override
  State<SkeletonBlock> createState() => _SkeletonBlockState();
}

class _SkeletonBlockState extends State<SkeletonBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final base = dark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.05);
        final shimmer = dark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.04);
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: Color.lerp(base, shimmer, _ctrl.value),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}

class InfoTile extends StatelessWidget {
  const InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.compact = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.s,
        vertical: compact ? AppSpacing.xs : AppSpacing.s + 2,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: scheme.primary),
          ),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: dark
                        ? Colors.white.withValues(alpha: 0.5)
                        : Colors.black.withValues(alpha: 0.5),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GradientIconBadge extends StatelessWidget {
  const GradientIconBadge({
    required this.icon,
    this.size = 44,
    this.gradient,
    this.color,
    super.key,
  });

  final IconData icon;
  final double size;
  final LinearGradient? gradient;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fallback = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [scheme.primary, scheme.tertiary],
    );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient ?? fallback,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: (color ?? scheme.primary).withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.white, size: size * 0.5),
    );
  }
}
