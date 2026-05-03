import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../theme.dart';
import 'common.dart';

class ResourceCard extends StatelessWidget {
  const ResourceCard({required this.status, super.key});

  final GokrazyStatus status;

  @override
  Widget build(BuildContext context) {
    final memTotal = status.memTotal ?? 0;
    final memUsed = memTotal - (status.memAvailable ?? 0);
    final permTotal = status.permTotal ?? 0;
    final permUsed = status.permUsed ?? 0;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Resources',
            subtitle: 'Memory and persistent storage',
            icon: Icons.tune_rounded,
          ),
          _ResourceRow(
            icon: Icons.memory_rounded,
            label: 'Memory',
            used: memUsed,
            total: memTotal,
          ),
          const SizedBox(height: AppSpacing.s + 2),
          _ResourceRow(
            icon: Icons.storage_rounded,
            label: 'Persistent storage',
            used: permUsed,
            total: permTotal,
          ),
          const SizedBox(height: AppSpacing.s),
          _Footnote(),
        ],
      ),
    );
  }
}

class _ResourceRow extends StatelessWidget {
  const _ResourceRow({
    required this.icon,
    required this.label,
    required this.used,
    required this.total,
  });

  final IconData icon;
  final String label;
  final int used;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final ratio = total <= 0 ? 0.0 : (used / total).clamp(0.0, 1.0);
    final percent = (ratio * 100);
    final color = ratio >= 0.9
        ? AppPalette.coral
        : ratio >= 0.75
            ? AppPalette.amber
            : ratio >= 0.5
                ? AppPalette.cyan
                : AppPalette.emerald;

    final usageLabel = total <= 0
        ? '–'
        : '${formatBytes(used)} / ${formatBytes(total)}';

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
      padding: const EdgeInsets.all(AppSpacing.s + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: dark ? 0.18 : 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      usageLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                            color: dark
                                ? Colors.white.withValues(alpha: 0.6)
                                : Colors.black.withValues(alpha: 0.55),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Text(
                total <= 0
                    ? '—'
                    : '${percent.toStringAsFixed(percent >= 10 ? 0 : 1)}%',
                style: theme.textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              duration: motionDuration(context, AppMotion.slow),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(begin: 0, end: ratio),
              builder: (context, animated, _) {
                return Stack(
                  children: [
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: dark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth * animated;
                        return Container(
                          height: 10,
                          width: width,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                color.withValues(alpha: 0.85),
                                color,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(99),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.32),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Footnote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(
          Icons.tips_and_updates_outlined,
          size: 14,
          color: dark
              ? Colors.white.withValues(alpha: 0.55)
              : Colors.black.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Sampled from /proc/meminfo and the persistent volume each refresh.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: dark
                      ? Colors.white.withValues(alpha: 0.55)
                      : Colors.black.withValues(alpha: 0.5),
                ),
          ),
        ),
      ],
    );
  }
}
