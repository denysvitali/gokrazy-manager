import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    final scheme = Theme.of(context).colorScheme;
    final addressColor = tone == StatusTone.warning
        ? Colors.amber
        : scheme.primary;
    final addressTypeLabel = label.toLowerCase();
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 0.6,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label.toUpperCase(),
            style: labelStyle,
          ),
        ),
        const SizedBox(height: 4),
        ...addresses.asMap().entries.expand(
          (entry) => [
            _AddressCopyRow(
              address: entry.value,
              addressColor: addressColor,
              addressTypeLabel: addressTypeLabel,
            ),
            if (entry.key + 1 < addresses.length)
              const SizedBox(height: 5),
          ],
        ),
      ],
    );
  }

}

class _AddressCopyRow extends StatelessWidget {
  const _AddressCopyRow({
    required this.address,
    required this.addressColor,
    required this.addressTypeLabel,
  });

  final String address;
  final Color addressColor;
  final String addressTypeLabel;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: address));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied $addressTypeLabel address to clipboard'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Copy $addressTypeLabel address $address',
      hint: 'Tap or long-press to copy to clipboard',
      child: Material(
        color: addressColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: () => _copy(context),
          onLongPress: () => _copy(context),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: addressColor.withValues(alpha: 0.22),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    address,
                    style: TextStyle(
                      color: addressColor,
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.content_copy_rounded,
                  color: addressColor.withValues(alpha: 0.5),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
