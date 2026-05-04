import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import 'common.dart';

class ServicesCard extends StatelessWidget {
  const ServicesCard({
    required this.services,
    required this.busy,
    required this.onStart,
    required this.onStop,
    required this.onRestart,
    required this.onLogs,
    required this.onArgs,
    super.key,
  });

  final List<GokrazyService> services;
  final bool busy;
  final ValueChanged<GokrazyService> onStart;
  final ValueChanged<GokrazyService> onStop;
  final ValueChanged<GokrazyService> onRestart;
  final ValueChanged<GokrazyService> onLogs;
  final ValueChanged<GokrazyService> onArgs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final running = services.where((svc) => svc.running).length;
    final total = services.length;
    final ratio = total == 0 ? 0.0 : running / total;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Services',
            subtitle: total == 0
                ? 'Nothing supervised here yet'
                : '$running of $total running',
            icon: Icons.miscellaneous_services_rounded,
            trailing: total == 0
                ? null
                : _RunningBadge(
                    running: running,
                    total: total,
                    ratio: ratio,
                  ),
          ),
          if (services.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
              child: Row(
                children: [
                  Icon(
                    Icons.inbox_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: Text(
                      'No services found on this appliance.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(
                services.length,
                (index) {
                  final svc = services[index];
                  final row = _ServiceTile(
                    key: ValueKey('${svc.path}-$index'),
                    service: svc,
                    busy: busy,
                    onStart: () => onStart(svc),
                    onStop: () => onStop(svc),
                    onRestart: () => onRestart(svc),
                    onLogs: () => onLogs(svc),
                    onArgs: svc.args.isEmpty ? null : () => onArgs(svc),
                  );
                  return index == services.length - 1
                      ? row
                      : Column(
                          children: [
                            row,
                            const SizedBox(height: AppSpacing.s),
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

class _RunningBadge extends StatelessWidget {
  const _RunningBadge({
    required this.running,
    required this.total,
    required this.ratio,
  });

  final int running;
  final int total;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    final tone = ratio >= 0.99
        ? StatusTone.success
        : ratio >= 0.5
            ? StatusTone.info
            : ratio > 0
                ? StatusTone.warning
                : StatusTone.error;
    return StatusPill(
      label: '$running / $total',
      icon: Icons.bolt_rounded,
      tone: tone,
      dense: true,
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    super.key,
    required this.service,
    required this.busy,
    required this.onStart,
    required this.onStop,
    required this.onRestart,
    required this.onLogs,
    required this.onArgs,
  });

  final GokrazyService service;
  final bool busy;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onRestart;
  final VoidCallback onLogs;
  final VoidCallback? onArgs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final running = service.running;
    final tone = running ? StatusTone.success : StatusTone.error;

    final subtitle = running
        ? 'PID ${service.pid ?? '–'} • since ${service.startTime ?? 'unknown'}'
        : 'Stopped';

    return Container(
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s + 2,
        AppSpacing.s + 2,
        AppSpacing.s + 2,
        AppSpacing.s,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HueAvatar(
                seed: service.path,
                label: service.name,
                size: 44,
                statusTone: tone,
              ),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      service.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                            color: dark
                                ? Colors.white.withValues(alpha: 0.6)
                                : Colors.black.withValues(alpha: 0.55),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      service.path,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                            color: dark
                                ? Colors.white.withValues(alpha: 0.4)
                                : Colors.black.withValues(alpha: 0.4),
                            letterSpacing: 0.2,
                            fontFamily: 'monospace',
                          ),
                    ),
                  ],
                ),
              ),
                if (onArgs != null)
                Semantics(
                  button: true,
                  label: 'Service arguments',
                  hint: 'Open environment and process args for ${service.name}',
                  child: IconButton(
                    tooltip: 'Args (${service.args.length})',
                    onPressed: onArgs,
                    icon: const Icon(Icons.tune_rounded, size: 18),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _ServiceAction(
                icon: running ? Icons.stop_rounded : Icons.play_arrow_rounded,
                label: running ? 'Stop' : 'Start',
                tone: running ? StatusTone.error : StatusTone.success,
                onTap: busy ? null : (running ? onStop : onStart),
              ),
              _ServiceAction(
                icon: Icons.refresh_rounded,
                label: 'Restart',
                tone: StatusTone.warning,
                onTap: busy ? null : onRestart,
              ),
              _ServiceAction(
                icon: Icons.terminal_rounded,
                label: 'Logs',
                tone: StatusTone.primary,
                onTap: onLogs,
                primaryColor: scheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ServiceAction extends StatelessWidget {
  const _ServiceAction({
    required this.icon,
    required this.label,
    required this.tone,
    required this.onTap,
    this.primaryColor,
  });

  final IconData icon;
  final String label;
  final StatusTone tone;
  final VoidCallback? onTap;
  final Color? primaryColor;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    Color base;
    switch (tone) {
      case StatusTone.error:
        base = AppPalette.coral;
        break;
      case StatusTone.warning:
        base = AppPalette.amber;
        break;
      case StatusTone.success:
        base = AppPalette.emerald;
        break;
      case StatusTone.info:
        base = AppPalette.cyan;
        break;
      case StatusTone.primary:
        base = primaryColor ?? AppPalette.indigo;
        break;
      case StatusTone.neutral:
        base = AppPalette.slate700;
    }
    final disabled = onTap == null;
    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: Material(
        color: base.withValues(alpha: dark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s + 2,
              vertical: 8,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: base, size: 16),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: base,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
