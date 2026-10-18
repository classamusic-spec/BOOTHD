import 'package:flutter/material.dart';

import '../../../core/design_system/porcelain_icons.dart';
import '../../../core/design_system/porcelain_metrics.dart';
import '../../../core/design_system/porcelain_motion.dart';
import '../../../core/design_system/porcelain_theme.dart';
import '../../../core/design_system/porcelain_theme_data.dart';
import '../../../core/design_system/theme_profiles.dart';
import '../../../domain/models/event_rules.dart';
import '../../../domain/value_objects/orientation.dart';
import '../../../shared/formatters/theme_profile_names.dart';
import '../../../shared/guest/event_welcome_copy.dart';
import '../../../shared/guest/guest_welcome.dart';
import '../../../shared/guest/guest_welcome_sample.dart';
import '../../../shared/widgets/floral_spray.dart';
import '../../../shared/widgets/porcelain_stepper.dart';
import '../../../shared/widgets/porcelain_text_field.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/tablet_frame.dart';
import '../event_copy.dart';
import 'editor_parts.dart';

/// What guests see (S04 Guest, S20): welcome words, the guest theme and
/// the finished screen's time, with a live preview.
class GuestTab extends StatefulWidget {
  const GuestTab({super.key, required this.tab, required this.boothTheme});

  final EditorTabContext tab;

  /// The booth's own theme, used when the event has no override.
  final PorcelainThemeProfile boothTheme;

  @override
  State<GuestTab> createState() => _GuestTabState();
}

/// "Same as the booth" or one profile.
enum _ThemeChoice {
  booth,
  porcelainStudio,
  lightOak,
  darkroomWalnut;

  PorcelainThemeProfile? get profile => switch (this) {
    booth => null,
    porcelainStudio => PorcelainThemeProfile.porcelainStudio,
    lightOak => PorcelainThemeProfile.lightOak,
    darkroomWalnut => PorcelainThemeProfile.darkroomWalnut,
  };

  static _ThemeChoice of(PorcelainThemeProfile? profile) =>
      values.firstWhere((choice) => choice.profile == profile);
}

class _GuestTabState extends State<GuestTab> {
  late final _title = TextEditingController(
    text: widget.tab.event.guest.welcomeTitle,
  );
  late final _message = TextEditingController(
    text: widget.tab.event.guest.welcomeMessage,
  );

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    super.dispose();
  }

  static String? _optional(String text) => text.trim().isEmpty ? null : text;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final tab = widget.tab;
    final event = tab.event;
    final guest = event.guest;
    final reason = tab.readOnlyReason;
    final shown = guest.themeOverride ?? widget.boothTheme;
    final landscape =
        event.capture.orientation == GuestOrientationPreference.landscape;
    final frame = landscape ? const Size(1180, 820) : const Size(820, 1180);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EditorCard(
          title: 'Welcome screen',
          subtitle: 'Leave a field empty to use the standard words.',
          children: [
            PorcelainTextField(
              label: 'Welcome title',
              controller: _title,
              hint: sampleGuestWelcomeCopy.title,
              helper:
                  'The largest words guests see. The event name and date '
                  'sit above them.',
              enabled: !tab.readOnly,
              disabledReason: reason,
              maxLength: EventLimits.welcomeTitleMaxLength,
              showCounter: true,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (text) => tab.onChanged(
                event.copyWith(
                  guest: guest.copyWith(welcomeTitle: _optional(text)),
                ),
              ),
            ),
            PorcelainTextField(
              label: 'Welcome message',
              controller: _message,
              hint: sampleWelcomeMessage,
              enabled: !tab.readOnly,
              disabledReason: reason,
              maxLength: EventLimits.welcomeMessageMaxLength,
              showCounter: true,
              maxLines: 4,
              minLines: 2,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (text) => tab.onChanged(
                event.copyWith(
                  guest: guest.copyWith(welcomeMessage: _optional(text)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: PorcelainSpace.xl),
        EditorCard(
          title: 'Choose guest experience',
          subtitle:
              'The look of every guest screen. The Studio keeps the booth '
              'theme.',
          children: [
            Wrap(
              spacing: PorcelainSpace.md,
              runSpacing: PorcelainSpace.md,
              children: [
                for (final choice in _ThemeChoice.values)
                  _ExperienceCard(
                    profile: choice.profile ?? widget.boothTheme,
                    title: choice.profile?.title ?? 'Same as the booth',
                    detail: choice.profile == null
                        ? widget.boothTheme.title
                        : null,
                    selected: _ThemeChoice.of(guest.themeOverride) == choice,
                    disabledReason: reason,
                    onPressed: tab.readOnly
                        ? null
                        : () => tab.onChanged(
                            event.copyWith(
                              guest: guest.copyWith(
                                themeOverride: choice.profile,
                              ),
                            ),
                          ),
                  ),
              ],
            ),
            Center(
              child: SizedBox(
                height: 260,
                width: 260 * frame.width / frame.height + 18,
                child: Theme(
                  data: porcelainThemeData(
                    shown,
                    highContrast: theme.highContrast,
                  ),
                  child: TabletFrame(
                    logicalSize: frame,
                    semanticLabel:
                        'Preview of the guest welcome in ${shown.title}, '
                        '${EventCopy.orientation(event.capture.orientation).toLowerCase()}',
                    child: GuestWelcome(
                      copy: welcomeCopyFor(event),
                      onStart: () {},
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: PorcelainSpace.xl),
        EditorCard(
          title: 'Finished screen',
          subtitle:
              'How long the finished photo stays before the booth resets for '
              'the next guest.',
          children: [
            EditorSetting(
              title: EventCopy.setting(EventSetting.finishTimeoutSeconds),
              control: PorcelainStepper(
                label: EventCopy.setting(EventSetting.finishTimeoutSeconds),
                value: guest.finishTimeoutSeconds,
                min: EventLimits.finishTimeoutSeconds.min,
                max: EventLimits.finishTimeoutSeconds.max,
                step: 5,
                formatValue: EventCopy.seconds,
                decreaseLabel: 'Shorter',
                increaseLabel: 'Longer',
                onChanged: tab.edit(
                  (seconds) => event.copyWith(
                    guest: guest.copyWith(finishTimeoutSeconds: seconds),
                  ),
                ),
                disabledReason: reason,
                minimumReason:
                    reason ??
                    'At least ${EventLimits.finishTimeoutSeconds.min} '
                        'seconds.',
                maximumReason:
                    reason ??
                    'At most ${EventLimits.finishTimeoutSeconds.max} seconds.',
              ),
            ),
            const EditorNote(
              icon: PorcelainIcons.info,
              text: 'Guest sessions, and this screen, arrive in M07.',
            ),
          ],
        ),
      ],
    );
  }
}

/// One guest experience, as the reference board's Event Setup shows it: a
/// small emblem in that theme's own colours, its name, a gold edge and a
/// check mark when chosen.
class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard({
    required this.profile,
    required this.title,
    required this.selected,
    required this.onPressed,
    this.detail,
    this.disabledReason,
  });

  final PorcelainThemeProfile profile;
  final String title;
  final String? detail;
  final bool selected;
  final VoidCallback? onPressed;
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final colors = theme.colors;
    final motion = PorcelainMotion.of(context);
    return Pressable(
      onPressed: onPressed,
      semanticLabel: detail == null ? title : '$title, now $detail',
      selected: selected,
      inMutuallyExclusiveGroup: true,
      disabledReason: disabledReason,
      builder: (context, state) => AnimatedContainer(
        duration: motion.press,
        width: 148,
        padding: const EdgeInsets.all(PorcelainSpace.sm),
        decoration: BoxDecoration(
          color: colors.raised,
          borderRadius: PorcelainRadius.cardAll,
          border: Border.all(
            color: selected
                ? colors.accentIcon
                : state.focused
                ? colors.focusRing
                : colors.hairline,
            width: selected || state.focused ? 2.5 : 1,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              children: [
                Theme(
                  data: porcelainThemeData(
                    profile,
                    highContrast: theme.highContrast,
                  ),
                  child: const _ExperienceEmblem(),
                ),
                const SizedBox(height: PorcelainSpace.sm),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.text.labelLarge.copyWith(color: colors.ink),
                ),
                if (detail != null)
                  Text(
                    detail!,
                    textAlign: TextAlign.center,
                    style: theme.text.bodySmall.copyWith(
                      color: colors.inkMuted,
                    ),
                  ),
              ],
            ),
            if (selected)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [colors.primaryTop, colors.primaryBottom],
                    ),
                    border: Border.all(color: colors.primaryEdge),
                  ),
                  child: Icon(
                    PorcelainIcons.check,
                    size: 16,
                    color: colors.onPrimary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A theme in miniature: its guest canvas, a sprig of blossoms and the
/// pearl start button in its gold rim.
class _ExperienceEmblem extends StatelessWidget {
  const _ExperienceEmblem();

  @override
  Widget build(BuildContext context) {
    final colors = context.porcelain.colors;
    return ExcludeSemantics(
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            radius: 1.1,
            colors: [colors.surface, colors.canvas],
          ),
          borderRadius: PorcelainRadius.controlAll,
          border: Border.all(color: colors.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            const Positioned(
              right: -10,
              top: -8,
              child: FloralSpray(
                kind: FloralSprayKind.corner,
                width: 64,
                height: 64,
                mirrorX: true,
              ),
            ),
            Center(
              child: Container(
                width: 56,
                height: 56,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      colors.primaryTop,
                      colors.primaryEdge,
                      colors.primaryBottom,
                      colors.primaryTop,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadowKey,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.surface,
                  ),
                  child: Icon(
                    PorcelainIcons.camera,
                    size: 20,
                    color: colors.guestAccentText,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
