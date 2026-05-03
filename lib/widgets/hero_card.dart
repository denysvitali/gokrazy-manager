import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../theme.dart';
import 'common.dart';

class HeroHeaderCard extends StatelessWidget {
  const HeroHeaderCard({
    required this.instance,
    required this.status,
    required this.hasError,
    required this.onRefresh,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final GokrazyInstance instance;
  final GokrazyStatus? status;
  final bool hasError;
  final VoidCallback onRefresh;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brightness = theme.brightness;
    final hue = hueFromString(instance.id);
    final gradient = AppGradients.ofHue(hue, brightness: brightness);
    final dark = brightness == Brightness.dark;

    final servicesRatio = status == null || status!.totalServices == 0
        ? 0.0
        : status!.runningServices / status!.totalServices;
    final memTotal = status?.memTotal ?? 0;
    final memUsed = memTotal - (status?.memAvailable ?? 0);
    final memRatio = memTotal == 0 ? 0.0 : memUsed / memTotal;
    final permTotal = status?.permTotal ?? 0;
    final permUsed = status?.permUsed ?? 0;
    final permRatio = permTotal == 0 ? 0.0 : permUsed / permTotal;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: gradient),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Colors.black.withValues(alpha: dark ? 0.45 : 0.0),
                    Colors.black.withValues(alpha: dark ? 0.10 : 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: -42,
            top: -42,
            child: _PatternBlob(
              size: 220,
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          Positioned(
            left: -32,
            bottom: -54,
            child: _PatternBlob(
              size: 160,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HeroStatusBar(
                            instance: instance,
                            status: status,
                            hasError: hasError,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            instance.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            instance.baseUrl,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                          ),
                        ],
                      ),
                    ),
                    _ActionButton(
                      icon: Icons.sync_rounded,
                      tooltip: 'Refresh',
                      onPressed: onRefresh,
                    ),
                    const SizedBox(width: 4),
                    _ActionButton(
                      icon: Icons.edit_rounded,
                      tooltip: 'Edit',
                      onPressed: onEdit,
                    ),
                    const SizedBox(width: 4),
                    _ActionButton(
                      icon: Icons.delete_outline_rounded,
                      tooltip: 'Delete',
                      onPressed: onDelete,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.l),
                if (status != null)
                  _HeroMetrics(
                    servicesRatio: servicesRatio,
                    runningServices: status!.runningServices,
                    totalServices: status!.totalServices,
                    memUsed: memUsed,
                    memTotal: memTotal,
                    memRatio: memRatio,
                    permUsed: permUsed,
                    permTotal: permTotal,
                    permRatio: permRatio,
                  )
                else if (hasError)
                  _HeroMessage(
                    icon: Icons.error_outline_rounded,
                    text: 'Connection failed. Tap retry to try again.',
                    actionLabel: 'Retry',
                    onAction: onRefresh,
                  )
                else
                  _HeroMessage(
                    icon: Icons.satellite_alt_rounded,
                    text: 'Reaching out to the appliance...',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStatusBar extends StatelessWidget {
  const _HeroStatusBar({
    required this.instance,
    required this.status,
    required this.hasError,
  });

  final GokrazyInstance instance;
  final GokrazyStatus? status;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final pillStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w700,
      fontSize: 12,
      letterSpacing: 0.4,
    );
    final lastSeenLabel = instance.lastSeen == null
        ? 'never'
        : formatTimeAgo(instance.lastSeen!);
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _GlassPill(
          icon: hasError
              ? Icons.cloud_off_rounded
              : status != null
                  ? Icons.cloud_done_rounded
                  : Icons.cloud_sync_rounded,
          label: hasError
              ? 'Offline'
              : status != null
                  ? 'Live'
                  : 'Syncing',
          textStyle: pillStyle,
        ),
        _GlassPill(
          icon: Icons.history_rounded,
          label: 'Seen $lastSeenLabel',
          textStyle: pillStyle,
        ),
        if (status?.hostname != null && status!.hostname!.isNotEmpty)
          _GlassPill(
            icon: Icons.dns_rounded,
            label: status!.hostname!,
            textStyle: pillStyle,
          ),
      ],
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({
    required this.icon,
    required this.label,
    required this.textStyle,
  });

  final IconData icon;
  final String label;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(label, style: textStyle),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.16),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}

class _HeroMetrics extends StatelessWidget {
  const _HeroMetrics({
    required this.servicesRatio,
    required this.runningServices,
    required this.totalServices,
    required this.memUsed,
    required this.memTotal,
    required this.memRatio,
    required this.permUsed,
    required this.permTotal,
    required this.permRatio,
  });

  final double servicesRatio;
  final int runningServices;
  final int totalServices;
  final int memUsed;
  final int memTotal;
  final double memRatio;
  final int permUsed;
  final int permTotal;
  final double permRatio;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s,
        vertical: AppSpacing.m,
      ),
      child: Row(
        children: [
          Expanded(
            child: _RingMetric(
              icon: Icons.bolt_rounded,
              ratio: servicesRatio,
              title: 'Services',
              subtitle: totalServices == 0
                  ? 'No services'
                  : '$runningServices of $totalServices running',
            ),
          ),
          _MetricDivider(),
          Expanded(
            child: _RingMetric(
              icon: Icons.memory_rounded,
              ratio: memRatio,
              title: 'Memory',
              subtitle: memTotal == 0
                  ? 'Unknown'
                  : '${formatBytes(memUsed)} / ${formatBytes(memTotal)}',
            ),
          ),
          _MetricDivider(),
          Expanded(
            child: _RingMetric(
              icon: Icons.storage_rounded,
              ratio: permRatio,
              title: 'Storage',
              subtitle: permTotal == 0
                  ? 'Unknown'
                  : '${formatBytes(permUsed)} / ${formatBytes(permTotal)}',
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 70,
      color: Colors.white.withValues(alpha: 0.18),
    );
  }
}

class _RingMetric extends StatelessWidget {
  const _RingMetric({
    required this.icon,
    required this.ratio,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final double ratio;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final clamped = ratio.isFinite ? ratio.clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 78,
            height: 78,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 78,
                  height: 78,
                  child: CircularProgressIndicator(
                    value: 1,
                    strokeWidth: 6,
                    valueColor: AlwaysStoppedAnimation(
                      Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                ),
                TweenAnimationBuilder<double>(
                  duration: AppMotion.slow,
                  curve: Curves.easeOutCubic,
                  tween: Tween<double>(begin: 0, end: clamped),
                  builder: (context, animated, _) => SizedBox(
                    width: 78,
                    height: 78,
                    child: CircularProgressIndicator(
                      value: animated,
                      strokeCap: StrokeCap.round,
                      strokeWidth: 6,
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white, size: 16),
                    const SizedBox(height: 2),
                    Text(
                      '${(clamped * 100).toStringAsFixed(clamped >= 0.1 ? 0 : 1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMessage extends StatelessWidget {
  const _HeroMessage({
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.92),
                foregroundColor: AppPalette.slate900,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.m,
                  vertical: 0,
                ),
                minimumSize: const Size(0, 36),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  letterSpacing: 0.2,
                ),
              ),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

class _PatternBlob extends StatelessWidget {
  const _PatternBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
