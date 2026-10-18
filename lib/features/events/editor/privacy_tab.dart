import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../core/design_system/porcelain_icons.dart';
import '../../../core/design_system/porcelain_metrics.dart';
import '../../../domain/models/booth_event.dart';
import '../../../domain/models/event_rules.dart';
import '../../../shared/guest/guest_welcome_sample.dart';
import '../../../shared/widgets/porcelain_segmented_control.dart';
import '../../../shared/widgets/porcelain_text_field.dart';
import 'editor_parts.dart';

/// The guest privacy note and how long photos are kept (S04 Privacy,
/// P-05, P-13).
class PrivacyTab extends StatefulWidget {
  const PrivacyTab({super.key, required this.tab});

  final EditorTabContext tab;

  /// Offered retention periods, in days.
  static const retentionChoices = [7, 30, 90, 365];

  @override
  State<PrivacyTab> createState() => _PrivacyTabState();
}

class _PrivacyTabState extends State<PrivacyTab> {
  late final _consent = TextEditingController(
    text: widget.tab.event.guest.consentText,
  );

  @override
  void dispose() {
    _consent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tab = widget.tab;
    final event = tab.event;
    final retention = event.retention;
    final reason = tab.readOnlyReason;
    final days = retention.days;
    final choices = {...PrivacyTab.retentionChoices, ?days}.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EditorCard(
          title: 'Privacy note for guests',
          subtitle:
              'Shown quietly at the bottom of the welcome screen. Leave it '
              'empty for the standard note.',
          children: [
            PorcelainTextField(
              label: 'Privacy note',
              controller: _consent,
              hint: sampleGuestWelcomeCopy.privacyNote,
              enabled: !tab.readOnly,
              disabledReason: reason,
              maxLength: EventLimits.consentTextMaxLength,
              showCounter: true,
              maxLines: 5,
              minLines: 2,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (text) => tab.onChanged(
                event.copyWith(
                  guest: event.guest.copyWith(
                    consentText: text.trim().isEmpty ? null : text,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: PorcelainSpace.xl),
        EditorCard(
          title: 'Keeping photos',
          subtitle: "How long this event's photos stay on the booth.",
          children: [
            PorcelainSegmentedControl<RetentionMode>(
              selected: retention.mode,
              onChanged: tab.edit(
                (mode) => event.copyWith(
                  retention: mode == RetentionMode.keepUntilDeleted
                      ? const RetentionPolicy.keepUntilDeleted()
                      : const RetentionPolicy.deleteAfterDays(30),
                ),
              ),
              disabledReason: reason,
              segments: const [
                PorcelainSegment(
                  value: RetentionMode.keepUntilDeleted,
                  label: 'Until an operator deletes them',
                ),
                PorcelainSegment(
                  value: RetentionMode.deleteAfterDays,
                  label: 'For a set time',
                ),
              ],
            ),
            if (retention.mode == RetentionMode.deleteAfterDays)
              EditorSetting(
                title: 'Keep photos for',
                control: PorcelainSegmentedControl<int>(
                  selected: days!,
                  onChanged: tab.edit(
                    (value) => event.copyWith(
                      retention: RetentionPolicy.deleteAfterDays(value),
                    ),
                  ),
                  disabledReason: reason,
                  segments: [
                    for (final choice in choices)
                      PorcelainSegment(
                        value: choice,
                        label: choice == 365 ? '1 year' : '$choice days',
                      ),
                  ],
                ),
              ),
            const EditorNote(
              icon: PorcelainIcons.info,
              text:
                  'Automatic deletion starts with the gallery (M08). Until '
                  'then nothing is deleted automatically, and archiving an '
                  'event never deletes photos.',
            ),
          ],
        ),
      ],
    );
  }
}
