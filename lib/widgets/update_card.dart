import 'package:flutter/material.dart';

import '../theme.dart';
import 'common.dart';

class UpdateCard extends StatelessWidget {
  const UpdateCard({
    required this.busy,
    required this.progress,
    required this.message,
    required this.onUpload,
    required this.onTestboot,
    required this.onSwitch,
    required this.onReboot,
    super.key,
  });

  final bool busy;
  final double? progress;
  final String? message;
  final VoidCallback onUpload;
  final VoidCallback onTestboot;
  final VoidCallback onSwitch;
  final VoidCallback onReboot;

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
          SectionHeader(
            title: 'Update & flash',
            subtitle: 'Squashfs upload, testboot, switch, reboot',
            icon: Icons.system_update_alt_rounded,
            trailing: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
          ),
          if (progress != null) ...[
            const SizedBox(height: AppSpacing.xs),
            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    message ?? 'Uploading',
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${((progress ?? 0) * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ] else if (message != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Semantics(
                liveRegion: true,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: StatusPill(
                    label: message!,
                    icon: Icons.check_circle_rounded,
                    tone: StatusTone.success,
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.s + 4),
          _PrimaryUploadAction(
            busy: busy,
            onPressed: onUpload,
          ),
          const SizedBox(height: AppSpacing.s),
          Row(
            children: [
              Expanded(
                child: _ActionButtonTile(
                  icon: Icons.fact_check_rounded,
                  label: 'Testboot',
                  tone: StatusTone.warning,
                  onTap: busy ? null : onTestboot,
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: _ActionButtonTile(
                  icon: Icons.swap_horiz_rounded,
                  label: 'Switch',
                  tone: StatusTone.info,
                  onTap: busy ? null : onSwitch,
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: _ActionButtonTile(
                  icon: Icons.power_settings_new_rounded,
                  label: 'Reboot',
                  tone: StatusTone.error,
                  onTap: busy ? null : onReboot,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: dark
                    ? Colors.white.withValues(alpha: 0.55)
                    : Colors.black.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Test the new root before switching. Reboot is final.',
                  style: theme.textTheme.bodySmall?.copyWith(
                        color: dark
                            ? Colors.white.withValues(alpha: 0.55)
                            : Colors.black.withValues(alpha: 0.5),
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrimaryUploadAction extends StatelessWidget {
  const _PrimaryUploadAction({
    required this.busy,
    required this.onPressed,
  });

  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [scheme.primary, scheme.tertiary],
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.34),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: busy ? null : onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.l,
                vertical: 14,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cloud_upload_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.s),
                  const Text(
                    'Upload squashfs',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: 0.3,
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

class _ActionButtonTile extends StatelessWidget {
  const _ActionButtonTile({
    required this.icon,
    required this.label,
    required this.tone,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final StatusTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return StatusPill(
      icon: icon,
      label: label,
      tone: tone,
      dense: true,
      onTap: onTap,
    );
  }
}
