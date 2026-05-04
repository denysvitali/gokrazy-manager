import 'package:flutter/material.dart';

import '../theme.dart';
import 'common.dart';

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final padding = width >= AppBreakpoints.tablet
        ? const EdgeInsets.symmetric(
            horizontal: AppSpacing.l,
            vertical: AppSpacing.m,
          )
        : const EdgeInsets.all(AppSpacing.m);

    return SingleChildScrollView(
      padding: padding,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              _SettingsHero(),
              SizedBox(height: AppSpacing.m),
              _AppearanceCard(),
              SizedBox(height: AppSpacing.m),
              _AboutCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsHero extends StatelessWidget {
  const _SettingsHero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppGradients.hero(scheme),
              ),
            ),
          ),
          Positioned(
            right: -32,
            top: -32,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: dark ? 0.10 : 0.18),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.tune_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Settings',
                        style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Personalize the Gokrazy Manager experience.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                      ),
                    ],
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

class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Appearance',
            subtitle: 'Pick the theme that suits the room',
            icon: Icons.color_lens_rounded,
          ),
          const SizedBox(height: AppSpacing.xs),
          ValueListenableBuilder<AppThemeVariant>(
            valueListenable: appThemeVariant,
            builder: (context, selected, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ThemeOption(
                    variant: AppThemeVariant.system,
                    selected: selected,
                    icon: Icons.devices_other_rounded,
                    label: 'System',
                    description: 'Match the OS theme automatically',
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _ThemeOption(
                    variant: AppThemeVariant.light,
                    selected: selected,
                    icon: Icons.light_mode_rounded,
                    label: 'Light',
                    description: 'Bright surfaces with subtle gradients',
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _ThemeOption(
                    variant: AppThemeVariant.dark,
                    selected: selected,
                    icon: Icons.dark_mode_rounded,
                    label: 'Dark',
                    description: 'Deep navy palette, easy on the eyes',
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _ThemeOption(
                    variant: AppThemeVariant.amoledBlack,
                    selected: selected,
                    icon: Icons.nightlight_round,
                    label: 'AMOLED',
                    description: 'True black for OLED displays',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.variant,
    required this.selected,
    required this.icon,
    required this.label,
    required this.description,
  });

  final AppThemeVariant variant;
  final AppThemeVariant selected;
  final IconData icon;
  final String label;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final isSelected = selected == variant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () {
          appThemeVariant.value = variant;
          scheduleThemeSave(variant);
        },
        child: AnimatedContainer(
          duration: motionDuration(context, AppMotion.fast),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isSelected
                ? scheme.primary.withValues(alpha: dark ? 0.18 : 0.10)
                : (dark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.black.withValues(alpha: 0.02)),
            border: Border.all(
              color: isSelected
                  ? scheme.primary.withValues(alpha: 0.65)
                  : (dark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.04)),
              width: isSelected ? 1.6 : 1,
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          padding: const EdgeInsets.all(AppSpacing.s + 2),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(
                    alpha: isSelected ? 0.20 : 0.10,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: scheme.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                            color: dark
                                ? Colors.white.withValues(alpha: 0.6)
                                : Colors.black.withValues(alpha: 0.55),
                          ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: motionDuration(context, AppMotion.fast),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? scheme.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? scheme.primary
                        : (dark
                            ? Colors.white.withValues(alpha: 0.35)
                            : Colors.black.withValues(alpha: 0.3)),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'About',
            subtitle: 'Gokrazy Manager',
            icon: Icons.info_outline_rounded,
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: const [
              StatusPill(
                label: 'Material 3',
                icon: Icons.palette_rounded,
                tone: StatusTone.primary,
                dense: true,
              ),
              StatusPill(
                label: 'Open source',
                icon: Icons.public_rounded,
                tone: StatusTone.info,
                dense: true,
              ),
              StatusPill(
                label: 'Self-signed friendly',
                icon: Icons.verified_user_rounded,
                tone: StatusTone.success,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s + 2),
          Text(
            'A modern dashboard for the gokrazy supervised appliances. '
            'Manage services, flash root images, and stream live logs '
            'from anywhere on the network.',
            style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.8),
                ),
          ),
        ],
      ),
    );
  }
}
