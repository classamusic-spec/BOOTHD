import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/porcelain_icons.dart';
import '../../core/di/service_providers.dart';
import '../../domain/models/booth_event.dart';
import '../../domain/models/event_rules.dart';
import '../../domain/services/event_service.dart';
import '../../shared/widgets/porcelain_button.dart';
import '../../shared/widgets/porcelain_sheet.dart';
import '../../shared/widgets/porcelain_toast.dart';
import '../../shared/widgets/tone.dart';
import 'event_copy.dart';

/// Event lifecycle actions shared by the list and the editor, with their
/// confirmations and results (S03, S04).
abstract final class EventActions {
  static const failed =
      "That change couldn't be saved. Nothing was changed; try again.";

  /// Duplicates [event] as a new draft and returns the copy.
  static Future<BoothEvent?> duplicate(
    BuildContext context,
    WidgetRef ref,
    BoothEvent event,
  ) => _run(
    context,
    () => ref
        .read(eventServiceProvider)
        .duplicate(event.id, copySuffix: EventCopy.copySuffix),
    done: (copy) => 'Duplicated as “${copy.title}” in Drafts.',
  );

  /// Asks, then archives [event]. Photos are never deleted.
  static Future<BoothEvent?> archive(
    BuildContext context,
    WidgetRef ref,
    BoothEvent event,
  ) async {
    final confirmed = await showPorcelainSheet<bool>(
      context: context,
      title: 'Archive “${event.title}”?',
      body: const Text(
        'It moves to Archived and can no longer run the booth. Nothing is '
        'deleted, and you can reopen it at any time.',
      ),
      actions: (sheet) => [
        PorcelainButton(
          label: 'Keep it',
          onPressed: () => Navigator.of(sheet).pop(false),
        ),
        PorcelainButton(
          label: 'Archive',
          icon: PorcelainIcons.archive,
          variant: PorcelainButtonVariant.danger,
          onPressed: () => Navigator.of(sheet).pop(true),
        ),
      ],
    );
    if (confirmed != true || !context.mounted) return null;
    return _run(
      context,
      () => ref.read(eventServiceProvider).archive(event.id),
      done: (archived) => '“${archived.title}” is archived.',
    );
  }

  static Future<BoothEvent?> reopen(
    BuildContext context,
    WidgetRef ref,
    BoothEvent event,
  ) => _run(
    context,
    () => ref.read(eventServiceProvider).reopen(event.id),
    done: (reopened) => '“${reopened.title}” is back in Drafts.',
  );

  static Future<BoothEvent?> activate(
    BuildContext context,
    WidgetRef ref,
    BoothEvent event,
  ) => _run(
    context,
    () => ref.read(eventServiceProvider).activate(event.id),
    done: (active) => '“${active.title}” is active.',
  );

  static Future<BoothEvent?> returnToDraft(
    BuildContext context,
    WidgetRef ref,
    BoothEvent event,
  ) => _run(
    context,
    () => ref.read(eventServiceProvider).returnToDraft(event.id),
    done: (draft) => '“${draft.title}” is back in Drafts.',
  );

  static Future<BoothEvent?> _run(
    BuildContext context,
    Future<BoothEvent> Function() action, {
    required String Function(BoothEvent result) done,
  }) async {
    try {
      final result = await action();
      if (context.mounted) {
        PorcelainToast.show(context, done(result), tone: PorcelainTone.success);
      }
      return result;
    } on EventRuleException catch (error) {
      if (context.mounted) {
        PorcelainToast.show(
          context,
          error.issues.map(EventCopy.issue).join(' '),
          tone: PorcelainTone.warning,
        );
      }
    } on Exception {
      if (context.mounted) {
        PorcelainToast.show(context, failed, tone: PorcelainTone.danger);
      }
    }
    return null;
  }
}

/// Whether [issues] include anything that stops saving.
bool hasInvalid(Iterable<EventIssue> issues) =>
    issues.any((issue) => issue.level == IssueLevel.invalid);
