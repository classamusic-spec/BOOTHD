import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/appearance.dart';
import '../../core/design_system/porcelain_icons.dart';
import '../../core/design_system/porcelain_metrics.dart';
import '../../core/design_system/porcelain_theme.dart';
import '../../core/design_system/porcelain_theme_data.dart';
import '../../core/design_system/theme_profiles.dart';
import '../../core/routing/route_paths.dart';
import '../../shared/formatters/theme_profile_names.dart';
import '../../shared/guest/guest_welcome.dart';
import '../../shared/guest/guest_welcome_sample.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/porcelain_button.dart';
import '../../shared/widgets/porcelain_card.dart';
import '../../shared/widgets/porcelain_segmented_control.dart';
import '../../shared/widgets/porcelain_toast.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/tablet_frame.dart';
import '../../shared/widgets/theme_profile_card.dart';
import '../../shared/widgets/tone.dart';

/// Appearance settings (S17): preview a theme before applying it, plus
/// contrast and motion preferences that apply immediately.
class AppearanceSettings extends ConsumerStatefulWidget {
  const AppearanceSettings({super.key});

  static const persistenceNote =
      'Saved with this booth and kept when the app restarts. Events can '
      'give their guest screens a different theme.';

  static const saveFailed =
      "This choice couldn't be saved on the tablet. It applies until the "
      'app restarts.';

  @override
  ConsumerState<AppearanceSettings> createState() => _AppearanceSettingsState();
}

class _AppearanceSettingsState extends ConsumerState<AppearanceSettings> {
  PorcelainThemeProfile? _preview;

  /// Applies a choice at once and reports if it could not be stored.
  Future<void> _save(Future<void> Function() change, {String? applied}) async {
    try {
      await change();
      if (applied != null && mounted) {
        PorcelainToast.show(context, applied, tone: PorcelainTone.success);
      }
    } on Exception {
      if (mounted) {
        PorcelainToast.show(
          context,
          AppearanceSettings.saveFailed,
          tone: PorcelainTone.warning,
        );
      }
    }
  }

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
            child: ThemeProfileCard(
              profile: profile,
              title: profile.title,
              description: profile.description,
              selected: profile == preview,
              badge: profile == applied
                  ? const StatusBadge(
                      label: 'In use',
                      tone: PorcelainTone.success,
                    )
                  : null,
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
                      setState(() => _preview = null);
                      _save(
                        () => controller.setProfile(preview),
                        applied: '${preview.title} is now in use.',
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
                  onChanged: (value) =>
                      _save(() => controller.setContrast(value)),
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
                  onChanged: (value) =>
                      _save(() => controller.setMotion(value)),
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
