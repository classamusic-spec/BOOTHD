import 'package:flutter/material.dart';

import '../../../core/design_system/porcelain_icons.dart';
import '../../../core/design_system/porcelain_metrics.dart';
import '../../../core/design_system/porcelain_theme.dart';
import '../../../core/design_system/porcelain_theme_data.dart';
import '../../../core/design_system/theme_profiles.dart';
import '../../../domain/models/event_rules.dart';
import '../../../domain/value_objects/orientation.dart';
import '../../../shared/formatters/theme_profile_names.dart';
import '../../../shared/guest/event_welcome_copy.dart';
import '../../../shared/guest/guest_welcome.dart';
import '../../../shared/guest/guest_welcome_sample.dart';
import '../../../shared/widgets/porcelain_segmented_control.dart';
import '../../../shared/widgets/porcelain_stepper.dart';
import '../../../shared/widgets/porcelain_text_field.dart';
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
              hint: event.title.trim().isEmpty
                  ? 'The event title'
                  : event.title,
              helper: 'The largest words guests see. Defaults to the title.',
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
              hint: sampleGuestWelcomeCopy.subtitle,
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
          title: 'Guest theme',
          subtitle:
              'The Studio keeps the booth theme; only guest screens change.',
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: PorcelainSegmentedControl<_ThemeChoice>(
                selected: _ThemeChoice.of(guest.themeOverride),
                onChanged: tab.edit(
                  (choice) => event.copyWith(
                    guest: guest.copyWith(themeOverride: choice.profile),
                  ),
                ),
                disabledReason: reason,
                segments: [
                  for (final choice in _ThemeChoice.values)
                    PorcelainSegment(
                      value: choice,
                      label: choice.profile?.title ?? 'Same as the booth',
                    ),
                ],
              ),
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
