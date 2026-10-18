import 'package:flutter/material.dart';

import '../../../core/design_system/porcelain_icons.dart';
import '../../../core/design_system/porcelain_metrics.dart';
import '../../../core/design_system/porcelain_theme.dart';
import '../../../domain/models/event_rules.dart';
import '../../../domain/value_objects/calendar_date.dart';
import '../../../shared/formatters/date_format.dart';
import '../../../shared/widgets/porcelain_button.dart';
import '../../../shared/widgets/porcelain_text_field.dart';
import 'editor_parts.dart';

/// Title, date, venue and notes (S04 General).
class GeneralTab extends StatefulWidget {
  const GeneralTab({super.key, required this.tab, required this.status});

  final EditorTabContext tab;

  /// The lifecycle card, built by the editor (it knows what is saved).
  final Widget status;

  @override
  State<GeneralTab> createState() => _GeneralTabState();
}

class _GeneralTabState extends State<GeneralTab> {
  late final _title = TextEditingController(text: widget.tab.event.title);
  late final _venue = TextEditingController(text: widget.tab.event.venue);
  late final _notes = TextEditingController(text: widget.tab.event.notes);

  @override
  void dispose() {
    _title.dispose();
    _venue.dispose();
    _notes.dispose();
    super.dispose();
  }

  static String? _optional(String text) => text.trim().isEmpty ? null : text;

  Future<void> _pickDate() async {
    final event = widget.tab.event;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: event.date?.toLocalDateTime() ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2999, 12, 31),
      helpText: 'Event date',
    );
    if (picked != null) {
      widget.tab.onChanged(
        widget.tab.event.copyWith(date: CalendarDate.fromDateTime(picked)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.porcelain;
    final tab = widget.tab;
    final event = tab.event;
    final reason = tab.readOnlyReason;
    final titleProblem = event.title.trim().isEmpty
        ? 'Give the event a title.'
        : event.title.runes.length > EventLimits.titleMaxLength
        ? 'Use at most ${EventLimits.titleMaxLength} characters.'
        : null;
    final date = event.date;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EditorCard(
          title: 'Event',
          subtitle: 'For operators. Guests see the welcome title instead.',
          children: [
            PorcelainTextField(
              label: 'Title',
              controller: _title,
              error: reason == null ? titleProblem : null,
              enabled: !tab.readOnly,
              disabledReason: reason,
              maxLength: EventLimits.titleMaxLength,
              showCounter: true,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (text) => tab.onChanged(event.copyWith(title: text)),
            ),
            MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date', style: theme.text.labelLarge),
                  const SizedBox(height: PorcelainSpace.xs),
                  Wrap(
                    spacing: PorcelainSpace.sm,
                    runSpacing: PorcelainSpace.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      PorcelainButton(
                        label: date == null
                            ? 'Choose a date'
                            : formatCalendarDate(date),
                        icon: PorcelainIcons.events,
                        onPressed: tab.readOnly ? null : _pickDate,
                        disabledReason: reason,
                      ),
                      if (date != null)
                        PorcelainButton(
                          label: 'Clear date',
                          icon: PorcelainIcons.close,
                          variant: PorcelainButtonVariant.quiet,
                          size: PorcelainButtonSize.compact,
                          onPressed: tab.readOnly
                              ? null
                              : () => tab.onChanged(event.copyWith(date: null)),
                          disabledReason: reason,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            PorcelainTextField(
              label: 'Venue',
              controller: _venue,
              hint: 'Optional',
              enabled: !tab.readOnly,
              disabledReason: reason,
              maxLength: EventLimits.venueMaxLength,
              textCapitalization: TextCapitalization.words,
              onChanged: (text) =>
                  tab.onChanged(event.copyWith(venue: _optional(text))),
            ),
            PorcelainTextField(
              label: 'Notes',
              controller: _notes,
              hint: 'Optional. Never shown to guests.',
              enabled: !tab.readOnly,
              disabledReason: reason,
              maxLength: EventLimits.notesMaxLength,
              showCounter: true,
              maxLines: 6,
              minLines: 3,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (text) =>
                  tab.onChanged(event.copyWith(notes: _optional(text))),
            ),
          ],
        ),
        const SizedBox(height: PorcelainSpace.xl),
        widget.status,
      ],
    );
  }
}
