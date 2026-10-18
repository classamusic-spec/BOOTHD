import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/appearance.dart';
import '../../core/design_system/porcelain_depth.dart';
import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/design_system/porcelain_theme_data.dart';
import '../../core/design_system/theme_profiles.dart';
import '../../core/routing/route_paths.dart';
import '../../shared/guest/guest_welcome.dart';
import '../../shared/guest/guest_welcome_sample.dart';
import '../../shared/widgets/botanical_ornament.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/porcelain_button.dart';
import '../../shared/widgets/porcelain_card.dart';
import '../../shared/widgets/porcelain_segmented_control.dart';
import '../../shared/widgets/porcelain_toast.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/tablet_frame.dart';
import '../../shared/widgets/tone.dart';

/// Operator-facing names of the theme profiles.
extension ThemeProfileCopy on PorcelainThemeProfile {
  String get title => switch (this) {
    PorcelainThemeProfile.porcelainStudio => 'Porcelain Studio',
    PorcelainThemeProfile.lightOak => 'Light Oak',
    PorcelainThemeProfile.darkroomWalnut => 'Darkroom Walnut',
  };

  String get description => switch (this) {
    PorcelainThemeProfile.porcelainStudio =>
      'Warm ivory and champagne gold. The default.',
    PorcelainThemeProfile.lightOak =>
      'Pale oak, honey gold and sage, for light wood kiosks.',
    PorcelainThemeProfile.darkroomWalnut =>
      'Deep walnut and brass, for dim venues.',
  };
}

/// Appearance settings (S17): preview a theme before applying it, plus
/// contrast and motion preferences that apply immediately.
class AppearanceSettings extends ConsumerStatefulWidget {
  const AppearanceSettings({super.key});

  static const persistenceNote =
      'Choices apply to this tablet until the app restarts. Saving them per '
      'booth arrives with booth storage in M03.';

  @override
  ConsumerState<AppearanceSettings> createState() => _AppearanceSettingsState();
}

class _AppearanceSettingsState extends ConsumerState<AppearanceSettings> {
  PorcelainThemeProfile? _preview;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final appearance = ref.watch(appearanceProvider);
    final controller = ref.read(appearanceProvider.notifier);
    final applied = appearance.profile;
    final preview = _preview ?? applied;
    final previewing = preview != applied;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          title: 'Theme',
          subtitle:
              'Preview a theme, then apply it to the Studio and the guest '
              'screens.',
        ),
        for (final profile in PorcelainThemeProfile.values)
          Padding(
            padding: const EdgeInsets.only(bottom: PorcelainSpace.sm),
            child: _ThemeCard(
              profile: profile,
              selected: profile == preview,
              inUse: profile == applied,
              onPressed: () => setState(() => _preview = profile),
            ),
          ),
        const SizedBox(height: PorcelainSpace.xl),
        _ThemePreview(profile: preview, highContrast: theme.highContrast),
        const SizedBox(height: PorcelainSpace.lg),
        Wrap(
          spacing: PorcelainSpace.sm,
          runSpacing: PorcelainSpace.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            PorcelainButton(
              label: 'Apply ${preview.title}',
              icon: PorcelainIcons.check,
              variant: PorcelainButtonVariant.primary,
              onPressed: previewing
                  ? () {
                      controller.setProfile(preview);
                      setState(() => _preview = null);
                      PorcelainToast.show(
                        context,
                        '${preview.title} is now in use.',
                        tone: PorcelainTone.success,
                      );
                    }
                  : null,
              disabledReason: '${preview.title} is already in use.',
            ),
            PorcelainButton(
              label: 'Cancel preview',
              variant: PorcelainButtonVariant.quiet,
              onPressed: previewing
                  ? () => setState(() => _preview = null)
                  : null,
              disabledReason: 'Nothing is being previewed.',
            ),
          ],
        ),
        const SizedBox(height: PorcelainSpace.md),
        Text(
          AppearanceSettings.persistenceNote,
          style: theme.text.bodyMedium.copyWith(color: theme.colors.inkMuted),
        ),
        const SizedBox(height: PorcelainSpace.xxxl),
        const SectionHeader(
          title: 'Accessibility',
          subtitle: 'Applied immediately, everywhere, in every theme.',
        ),
        PorcelainCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Preference(
                title: 'Contrast',
                description:
                    'High contrast darkens text, outlines and focus rings. '
                    'Guest text already meets at least 7:1 in every theme.',
                control: PorcelainSegmentedControl<ContrastPreference>(
                  selected: appearance.contrast,
                  onChanged: controller.setContrast,
                  segments: const [
                    PorcelainSegment(
                      value: ContrastPreference.system,
                      label: 'Follow system',
                    ),
                    PorcelainSegment(
                      value: ContrastPreference.standard,
                      label: 'Standard',
                    ),
                    PorcelainSegment(
                      value: ContrastPreference.high,
                      label: 'High',
                    ),
                  ],
                ),
              ),
              Divider(height: PorcelainSpace.xxxl, color: theme.colors.divider),
              _Preference(
                title: 'Motion',
                description:
                    'Reduced motion removes slides, fades and press travel. '
                    'It always applies when the tablet asks for it.',
                control: PorcelainSegmentedControl<MotionPreference>(
                  selected: appearance.motion,
                  onChanged: controller.setMotion,
                  segments: const [
                    PorcelainSegment(
                      value: MotionPreference.system,
                      label: 'Follow system',
                    ),
                    PorcelainSegment(
                      value: MotionPreference.reduced,
                      label: 'Reduce motion',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: PorcelainSpace.xxxl),
        SectionHeader(
          title: 'Guest screen',
          subtitle: 'See the welcome screen full size, in the current theme.',
          trailing: PorcelainButton(
            label: 'Open preview',
            icon: PorcelainIcons.expand,
            onPressed: () => context.push(RoutePaths.guestPreview),
          ),
        ),
      ],
    );
  }
}

class _Preference extends StatelessWidget {
  const _Preference({
    required this.title,
    required this.description,
    required this.control,
  });

  final String title;
  final String description;
  final Widget control;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.text.titleMedium),
        const SizedBox(height: PorcelainSpace.xxs),
        Text(
          description,
          style: theme.text.bodyMedium.copyWith(color: theme.colors.inkMuted),
        ),
        const SizedBox(height: PorcelainSpace.md),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: control),
      ],
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.profile,
    required this.selected,
    required this.inUse,
    required this.onPressed,
  });

  final PorcelainThemeProfile profile;
  final bool selected;
  final bool inUse;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    return PorcelainCard(
      selected: selected,
      onPressed: onPressed,
      padding: const EdgeInsets.all(PorcelainSpace.md),
      child: Row(
        children: [
          SizedBox(
            width: 136,
            child: Theme(
              data: porcelainThemeData(
                profile,
                highContrast: theme.highContrast,
              ),
              child: const _Swatch(),
            ),
          ),
          const SizedBox(width: PorcelainSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.title, style: theme.text.titleMedium),
                const SizedBox(height: PorcelainSpace.xxs),
                Text(
                  profile.description,
                  style: theme.text.bodyMedium.copyWith(
                    color: theme.colors.inkMuted,
                  ),
                ),
                if (inUse) ...[
                  const SizedBox(height: PorcelainSpace.sm),
                  const StatusBadge(
                    label: 'In use',
                    tone: PorcelainTone.success,
                  ),
                ],
              ],
            ),
          ),
          // Room for the selected mark in the corner.
          const SizedBox(width: PorcelainSpace.xl),
        ],
      ),
    );
  }
}

/// A small still life of a theme: its canvas, a raised card, a gold pill and
/// a sprig, drawn with that theme's own tokens.
class _Swatch extends StatelessWidget {
  const _Swatch();

  @override
  Widget build(BuildContext context) {
    final colors = context.porcelain.colors;
    return ExcludeSemantics(
      child: Container(
        height: 88,
        decoration: BoxDecoration(
          color: colors.canvas,
          borderRadius: PorcelainRadius.controlAll,
          border: Border.all(color: colors.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            const Positioned(
              right: -6,
              bottom: -8,
              child: BotanicalOrnament.sprig(width: 72, height: 72, leaves: 6),
            ),
            Positioned(
              left: 12,
              top: 12,
              right: 40,
              child: Container(
                height: 30,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  border: Border.all(color: colors.hairline),
                  boxShadow: PorcelainDepth.shadows(colors, 1),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.centerLeft,
                child: Container(
                  height: 6,
                  width: 44,
                  decoration: BoxDecoration(
                    color: colors.ink,
                    borderRadius: const BorderRadius.all(Radius.circular(3)),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: Container(
                width: 64,
                height: 22,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [colors.primaryTop, colors.primaryBottom],
                  ),
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  border: Border.all(color: colors.primaryEdge),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The guest welcome screen in the previewed theme, portrait and landscape.
class _ThemePreview extends StatelessWidget {
  const _ThemePreview({required this.profile, required this.highContrast});

  final PorcelainThemeProfile profile;
  final bool highContrast;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    Widget frame(Size size, String label) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 220,
          child: Theme(
            data: porcelainThemeData(profile, highContrast: highContrast),
            child: TabletFrame(
              logicalSize: size,
              semanticLabel: 'Guest welcome in ${profile.title}, $label',
              child: GuestWelcome(copy: sampleGuestWelcomeCopy, onStart: () {}),
            ),
          ),
        ),
        const SizedBox(height: PorcelainSpace.lg),
        Text(
          label,
          style: theme.text.labelMedium.copyWith(color: theme.colors.inkMuted),
        ),
      ],
    );
    return PorcelainCard(
      padding: const EdgeInsets.all(PorcelainSpace.lg),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: PorcelainSpace.xl,
        runSpacing: PorcelainSpace.lg,
        children: [
          frame(const Size(820, 1180), 'Portrait'),
          frame(const Size(1180, 820), 'Landscape'),
        ],
      ),
    );
  }
}
