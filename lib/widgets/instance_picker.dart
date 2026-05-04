import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../theme.dart';
import 'common.dart';

class InstanceStrip extends StatelessWidget {
  const InstanceStrip({
    required this.instances,
    required this.statuses,
    required this.errors,
    required this.loadingIds,
    required this.selectedId,
    required this.selectedIds,
    required this.onLongPress,
    required this.onSelect,
    required this.onAdd,
    super.key,
  });

  final List<GokrazyInstance> instances;
  final Map<String, GokrazyStatus> statuses;
  final Map<String, String> errors;
  final Set<String> loadingIds;
  final String? selectedId;
  final Set<String> selectedIds;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onLongPress;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
        itemCount: instances.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s),
        itemBuilder: (context, index) {
          if (index == instances.length) {
            return _AddTile(key: const ValueKey('instance-add-tile'), onTap: onAdd);
          }
          final instance = instances[index];
          final selected = selectedId == instance.id;
          final selectedForBatch = selectedIds.contains(instance.id);
          final status = statuses[instance.id];
          final error = errors[instance.id];
          final isLoading = loadingIds.contains(instance.id);
          return _InstanceTile(
            key: ValueKey(instance.id),
            instance: instance,
            status: status,
            error: error,
            isLoading: isLoading,
            selected: selected,
            selectedForBatch: selectedForBatch,
            onTap: () => onSelect(instance.id),
            onLongPress: () => onLongPress(instance.id),
          );
        },
      ),
    );
  }
}

class _InstanceTile extends StatelessWidget {
  const _InstanceTile({
    super.key,
    required this.instance,
    required this.status,
    required this.error,
    required this.isLoading,
    required this.selected,
    required this.selectedForBatch,
    required this.onTap,
    required this.onLongPress,
  });

  final GokrazyInstance instance;
  final GokrazyStatus? status;
  final String? error;
  final bool isLoading;
  final bool selected;
  final bool selectedForBatch;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final isMarked = selected || selectedForBatch;
    final tone = error != null
        ? StatusTone.error
        : status != null
            ? StatusTone.success
            : isLoading
                ? StatusTone.info
                : StatusTone.neutral;

    final subtitle = error != null
        ? 'Error'
        : status != null
            ? '${status!.runningServices}/${status!.totalServices} svc'
            : isLoading
                ? 'Refreshing...'
                : 'Tap to load';

    final selectedColor = scheme.primary;
    final baseBg = dark ? AppPalette.slate800 : Colors.white;

    return AnimatedContainer(
      duration: motionDuration(context, AppMotion.fast),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isMarked
            ? selectedColor.withValues(alpha: dark ? 0.18 : 0.10)
            : baseBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isMarked
              ? selectedColor.withValues(alpha: 0.7)
              : (dark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.black.withValues(alpha: 0.06)),
          width: isMarked ? 1.6 : 1,
        ),
        boxShadow: isMarked
            ? [
                BoxShadow(
                  color: selectedColor.withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s,
              AppSpacing.s,
              AppSpacing.s,
              AppSpacing.s,
            ),
            child: Row(
              children: [
                HueAvatar(
                  seed: instance.id,
                  label: instance.name,
                  size: 52,
                  statusTone: tone,
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        instance.name,
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
                              color: error != null
                                  ? scheme.error
                                  : dark
                                      ? Colors.white.withValues(alpha: 0.65)
                                      : Colors.black.withValues(alpha: 0.55),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                if (selectedForBatch)
                  Icon(
                    Icons.check_circle_rounded,
                    color: selectedColor,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 96,
      child: DottedBorderBox(
        color: scheme.primary.withValues(alpha: 0.5),
        radius: AppRadius.lg,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: onTap,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(
                        alpha: dark ? 0.18 : 0.12,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      color: scheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Add',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Container with a subtle dashed border, used for the "Add" affordance.
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({
    required this.child,
    this.color = Colors.grey,
    this.radius = AppRadius.lg,
    super.key,
  });

  final Widget child;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(color: color, radius: radius),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final dashWidth = 5.0;
    final dashGap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

/// Vertical instance list used in tablet/desktop sidebar layout.
class InstanceSidebar extends StatelessWidget {
  const InstanceSidebar({
    required this.instances,
    required this.statuses,
    required this.errors,
    required this.loadingIds,
    required this.selectedId,
    required this.selectedIds,
    required this.onLongPress,
    required this.onSelect,
    required this.onAdd,
    required this.onRefresh,
    super.key,
  });

  final List<GokrazyInstance> instances;
  final Map<String, GokrazyStatus> statuses;
  final Map<String, String> errors;
  final Set<String> loadingIds;
  final String? selectedId;
  final Set<String> selectedIds;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onLongPress;
  final VoidCallback onAdd;
  final ValueChanged<GokrazyInstance> onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Fleet',
                style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s,
                  vertical: 0,
                ),
                minimumSize: const Size(0, 36),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: instances.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s),
            itemBuilder: (context, index) {
              final instance = instances[index];
              final selected = selectedId == instance.id;
              final selectedForBatch = selectedIds.contains(instance.id);
              final status = statuses[instance.id];
              final error = errors[instance.id];
              final isLoading = loadingIds.contains(instance.id);
              return _SidebarTile(
                instance: instance,
                status: status,
                error: error,
                isLoading: isLoading,
                selected: selected,
                selectedForBatch: selectedForBatch,
                onTap: () => onSelect(instance.id),
                onLongPress: () => onLongPress(instance.id),
                onRefresh: () => onRefresh(instance),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.instance,
    required this.status,
    required this.error,
    required this.isLoading,
    required this.selected,
    required this.selectedForBatch,
    required this.onTap,
    required this.onLongPress,
    required this.onRefresh,
  });

  final GokrazyInstance instance;
  final GokrazyStatus? status;
  final String? error;
  final bool isLoading;
  final bool selected;
  final bool selectedForBatch;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final isMarked = selected || selectedForBatch;
    final tone = error != null
        ? StatusTone.error
        : status != null
            ? StatusTone.success
            : isLoading
                ? StatusTone.info
                : StatusTone.neutral;

    final subtitle = error != null
        ? 'Connection issue'
        : status != null
            ? '${status!.runningServices}/${status!.totalServices} services running'
            : isLoading
                ? 'Refreshing...'
                : instance.baseUrl;

    final lastSeenText = instance.lastSeen == null
        ? 'Never checked'
        : 'Seen ${formatTimeAgo(instance.lastSeen!)}';

    return AnimatedContainer(
      duration: motionDuration(context, AppMotion.fast),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isMarked
            ? scheme.primary.withValues(alpha: dark ? 0.16 : 0.10)
            : (dark ? AppPalette.slate800 : Colors.white),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isMarked
              ? scheme.primary.withValues(alpha: 0.65)
              : (dark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.black.withValues(alpha: 0.06)),
          width: isMarked ? 1.6 : 1,
        ),
        boxShadow: isMarked
            ? [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s + 2),
            child: Row(
              children: [
                HueAvatar(
                  seed: instance.id,
                  label: instance.name,
                  size: 48,
                  statusTone: tone,
                  ),
                  const SizedBox(width: AppSpacing.s),
                  if (selectedForBatch)
                    Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: scheme.primary,
                    ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        instance.name,
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
                              color: error != null
                                  ? scheme.error
                                  : (dark
                                      ? Colors.white.withValues(alpha: 0.65)
                                      : Colors.black.withValues(alpha: 0.55)),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lastSeenText,
                        style: theme.textTheme.labelSmall?.copyWith(
                              color: dark
                                  ? Colors.white.withValues(alpha: 0.45)
                                  : Colors.black.withValues(alpha: 0.45),
                              letterSpacing: 0.5,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
