import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import 'common.dart';

class OverviewCard extends StatelessWidget {
  const OverviewCard({required this.status, super.key});

  final GokrazyStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Overview',
            subtitle: 'Hardware, kernel and identity',
            icon: Icons.dashboard_customize_rounded,
          ),
          const SizedBox(height: AppSpacing.xs),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = _columnsFor(constraints.maxWidth);
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: columns,
                childAspectRatio: _tileAspectRatio(
                  constraints.maxWidth,
                  columns: columns,
                ),
                crossAxisSpacing: AppSpacing.s,
                mainAxisSpacing: AppSpacing.s,
                children: [
                  InfoTile(
                    icon: Icons.developer_board_rounded,
                    label: 'MODEL',
                    value: status.model ?? 'Unknown',
                    valueStyle: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  InfoTile(
                    icon: Icons.terminal_rounded,
                    label: 'KERNEL',
                    value: status.kernel ?? 'Unknown',
                    valueStyle: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  InfoTile(
                    icon: Icons.dns_rounded,
                    label: 'HOSTNAME',
                    value: status.hostname ?? 'Unknown',
                    valueStyle: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (status.buildTimestamp != null)
                    InfoTile(
                      icon: Icons.schedule_rounded,
                      label: 'BUILD',
                      value: status.buildTimestamp!,
                      valueStyle: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  if (status.sbomHash != null)
                    InfoTile(
                      icon: Icons.fingerprint_rounded,
                      label: 'SBOM',
                      value: status.sbomHash!,
                      valueStyle: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              );
            },
          ),
          if (status.privateAddrs.isNotEmpty ||
              status.publicAddrs.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.m),
            Container(
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
                      Icon(
                        Icons.lan_rounded,
                        size: 16,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Network',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  if (status.privateAddrs.isNotEmpty) ...[
                    _AddressRow(
                      label: 'Private',
                      addresses: status.privateAddrs,
                      tone: StatusTone.info,
                    ),
                    if (status.publicAddrs.isNotEmpty)
                      const SizedBox(height: 6),
                  ],
                  if (status.publicAddrs.isNotEmpty)
                    _AddressRow(
                      label: 'Public',
                      addresses: status.publicAddrs,
                      tone: StatusTone.warning,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  int _columnsFor(double width) {
    if (width >= AppBreakpoints.desktop) {
      return 3;
    }
    if (width >= AppBreakpoints.tablet) {
      return 2;
    }
    return 2;
  }

  double _tileAspectRatio(double containerWidth, {required int columns}) {
    if (columns <= 0) {
      return 3.4;
    }
    final usableWidth = containerWidth - AppSpacing.s * (columns - 1);
    final tileWidth = usableWidth / columns;
    const minTileHeight = 92.0;
    final ratio = tileWidth / minTileHeight;
    return ratio.isFinite && ratio > 0 ? ratio : 3.4;
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({
    required this.label,
    required this.addresses,
    required this.tone,
  });

  final String label;
  final List<String> addresses;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: SizedBox(
            width: 60,
            child: Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    letterSpacing: 0.6,
                  ),
            ),
          ),
        ),
        ...addresses.map(
          (addr) => StatusPill(
            label: addr,
            tone: tone,
            dense: true,
            icon: tone == StatusTone.warning
                ? Icons.public_rounded
                : Icons.lan_rounded,
          ),
        ),
      ],
    );
  }
}
