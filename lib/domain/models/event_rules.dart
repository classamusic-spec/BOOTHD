/// Event validation (P-05 rules, AC-0306). Issues are typed values with a
/// diagnostic code (A-14); screens turn them into words.
library;

import 'package:meta/meta.dart';

import 'booth_event.dart';
import 'template_revision_summary.dart';

/// An inclusive range of whole numbers.
@immutable
final class IntRange {
  const IntRange(this.min, this.max);

  final int min;
  final int max;

  bool contains(int value) => value >= min && value <= max;

  @override
  String toString() => '$min–$max';
}

/// Limits on event fields, shared by the editor, the rules and the
/// database's CHECK constraints.
abstract final class EventLimits {
  static const titleMaxLength = 80;
  static const venueMaxLength = 80;
  static const notesMaxLength = 1000;
  static const welcomeTitleMaxLength = 60;
  static const welcomeMessageMaxLength = 200;
  static const consentTextMaxLength = 400;

  static const shotCount = IntRange(1, 4);
  static const countdownSeconds = IntRange(2, 10);
  static const shotIntervalSeconds = IntRange(1, 10);

  /// Retakes when a retake policy is on; exactly 0 when it is off.
  static const retakeLimit = IntRange(1, 5);
  static const finishTimeoutSeconds = IntRange(10, 120);
  static const jpegQuality = IntRange(80, 100);
  static const retentionDays = IntRange(1, 365);

  /// Templates one event may offer guests.
  static const maxTemplates = 12;
}

/// How serious an issue is.
enum IssueLevel {
  /// The event cannot be saved like this.
  invalid,

  /// The event can be saved as a draft but cannot be activated or launched.
  blocking,

  /// Worth fixing; nothing is blocked.
  warning,
}

/// Free-text event fields with a length limit.
enum EventTextField {
  title(EventLimits.titleMaxLength),
  venue(EventLimits.venueMaxLength),
  notes(EventLimits.notesMaxLength),
  welcomeTitle(EventLimits.welcomeTitleMaxLength),
  welcomeMessage(EventLimits.welcomeMessageMaxLength),
  consentText(EventLimits.consentTextMaxLength);

  const EventTextField(this.maxLength);

  final int maxLength;
}

/// Numeric event settings with an allowed range.
enum EventSetting {
  shotCount,
  countdownSeconds,
  shotIntervalSeconds,
  retakeLimit,
  finishTimeoutSeconds,
  jpegQuality,
  retentionDays,
}

/// A problem with an event's configuration.
@immutable
sealed class EventIssue {
  const EventIssue();

  IssueLevel get level;

  /// Machine-readable code for diagnostics (A-14).
  String get code;

  @override
  String toString() => code;
}

final class TitleRequired extends EventIssue {
  const TitleRequired();

  @override
  IssueLevel get level => IssueLevel.invalid;

  @override
  String get code => 'EVENT_TITLE_REQUIRED';

  @override
  bool operator ==(Object other) => other is TitleRequired;

  @override
  int get hashCode => code.hashCode;
}

final class TextTooLong extends EventIssue {
  const TextTooLong(this.field);

  final EventTextField field;

  @override
  IssueLevel get level => IssueLevel.invalid;

  @override
  String get code => 'EVENT_TEXT_TOO_LONG';

  @override
  bool operator ==(Object other) =>
      other is TextTooLong && other.field == field;

  @override
  int get hashCode => Object.hash(code, field);
}

final class SettingOutOfRange extends EventIssue {
  const SettingOutOfRange(this.setting, this.range, this.value);

  final EventSetting setting;
  final IntRange range;
  final int value;

  @override
  IssueLevel get level => IssueLevel.invalid;

  @override
  String get code => 'EVENT_SETTING_OUT_OF_RANGE';

  @override
  bool operator ==(Object other) =>
      other is SettingOutOfRange &&
      other.setting == setting &&
      other.value == value;

  @override
  int get hashCode => Object.hash(code, setting, value);
}

/// No template is selected.
final class NoTemplates extends EventIssue {
  const NoTemplates();

  @override
  IssueLevel get level => IssueLevel.blocking;

  @override
  String get code => 'EVENT_TEMPLATE_NONE';

  @override
  bool operator ==(Object other) => other is NoTemplates;

  @override
  int get hashCode => code.hashCode;
}

final class TooManyTemplates extends EventIssue {
  const TooManyTemplates(this.count);

  final int count;

  @override
  IssueLevel get level => IssueLevel.invalid;

  @override
  String get code => 'EVENT_TEMPLATE_TOO_MANY';

  @override
  bool operator ==(Object other) =>
      other is TooManyTemplates && other.count == count;

  @override
  int get hashCode => Object.hash(code, count);
}

final class DuplicateTemplate extends EventIssue {
  const DuplicateTemplate(this.revisionId);

  final String revisionId;

  @override
  IssueLevel get level => IssueLevel.invalid;

  @override
  String get code => 'EVENT_TEMPLATE_DUPLICATE';

  @override
  bool operator ==(Object other) =>
      other is DuplicateTemplate && other.revisionId == revisionId;

  @override
  int get hashCode => Object.hash(code, revisionId);
}

/// Templates are selected but none is the default.
final class DefaultTemplateMissing extends EventIssue {
  const DefaultTemplateMissing();

  @override
  IssueLevel get level => IssueLevel.blocking;

  @override
  String get code => 'EVENT_TEMPLATE_DEFAULT_MISSING';

  @override
  bool operator ==(Object other) => other is DefaultTemplateMissing;

  @override
  int get hashCode => code.hashCode;
}

/// The default template is not one of the allowed templates.
final class DefaultTemplateNotAllowed extends EventIssue {
  const DefaultTemplateNotAllowed(this.revisionId);

  final String revisionId;

  @override
  IssueLevel get level => IssueLevel.invalid;

  @override
  String get code => 'EVENT_TEMPLATE_DEFAULT_NOT_ALLOWED';

  @override
  bool operator ==(Object other) =>
      other is DefaultTemplateNotAllowed && other.revisionId == revisionId;

  @override
  int get hashCode => Object.hash(code, revisionId);
}

/// A selected template revision is not in the library (A-15: needs explicit
/// operator recovery).
final class TemplateNotFound extends EventIssue {
  const TemplateNotFound(this.revisionId);

  final String revisionId;

  @override
  IssueLevel get level => IssueLevel.blocking;

  @override
  String get code => 'EVENT_TEMPLATE_NOT_FOUND';

  @override
  bool operator ==(Object other) =>
      other is TemplateNotFound && other.revisionId == revisionId;

  @override
  int get hashCode => Object.hash(code, revisionId);
}

/// A selected template was archived in the library. Its revision still
/// exists, so the event keeps working.
final class TemplateArchived extends EventIssue {
  const TemplateArchived(this.template);

  final TemplateRevisionSummary template;

  @override
  IssueLevel get level => IssueLevel.warning;

  @override
  String get code => 'EVENT_TEMPLATE_ARCHIVED';

  @override
  bool operator ==(Object other) =>
      other is TemplateArchived && other.template == template;

  @override
  int get hashCode => Object.hash(code, template.revisionId);
}

/// A template's photo slots don't match the event's photos per session.
/// The mapping is one photo per slot (ADR-0009), so the counts must match.
final class TemplateSlotsMismatch extends EventIssue {
  const TemplateSlotsMismatch(this.template, this.shotCount);

  final TemplateRevisionSummary template;
  final int shotCount;

  @override
  IssueLevel get level => IssueLevel.blocking;

  @override
  String get code => 'EVENT_TEMPLATE_SLOTS_MISMATCH';

  @override
  bool operator ==(Object other) =>
      other is TemplateSlotsMismatch &&
      other.template == template &&
      other.shotCount == shotCount;

  @override
  int get hashCode => Object.hash(code, template.revisionId, shotCount);
}

/// Only active events can run the booth.
final class EventNotActive extends EventIssue {
  const EventNotActive(this.status);

  final EventStatus status;

  @override
  IssueLevel get level => IssueLevel.blocking;

  @override
  String get code => switch (status) {
    EventStatus.draft => 'EVENT_STATUS_DRAFT',
    EventStatus.archived => 'EVENT_STATUS_ARCHIVED',
    EventStatus.active => 'EVENT_STATUS_ACTIVE',
  };

  @override
  bool operator ==(Object other) =>
      other is EventNotActive && other.status == status;

  @override
  int get hashCode => Object.hash(code, status);
}

/// Validation rules for events (P-05).
abstract final class EventRules {
  /// Problems that stop [event] from being saved at all.
  static List<EventIssue> structuralIssues(BoothEvent event) {
    final issues = <EventIssue>[];

    if (event.title.trim().isEmpty) issues.add(const TitleRequired());
    // Counted in Unicode code points, as SQLite's length() counts them.
    void text(EventTextField field, String? value) {
      if (value != null && value.runes.length > field.maxLength) {
        issues.add(TextTooLong(field));
      }
    }

    text(EventTextField.title, event.title);
    text(EventTextField.venue, event.venue);
    text(EventTextField.notes, event.notes);
    text(EventTextField.welcomeTitle, event.guest.welcomeTitle);
    text(EventTextField.welcomeMessage, event.guest.welcomeMessage);
    text(EventTextField.consentText, event.guest.consentText);

    void range(EventSetting setting, IntRange allowed, int value) {
      if (!allowed.contains(value)) {
        issues.add(SettingOutOfRange(setting, allowed, value));
      }
    }

    final capture = event.capture;
    range(EventSetting.shotCount, EventLimits.shotCount, capture.shotCount);
    range(
      EventSetting.countdownSeconds,
      EventLimits.countdownSeconds,
      capture.countdownSeconds,
    );
    range(
      EventSetting.shotIntervalSeconds,
      EventLimits.shotIntervalSeconds,
      capture.shotIntervalSeconds,
    );
    range(
      EventSetting.retakeLimit,
      capture.retakePolicy == RetakePolicy.none
          ? const IntRange(0, 0)
          : EventLimits.retakeLimit,
      capture.retakeLimit,
    );
    range(
      EventSetting.finishTimeoutSeconds,
      EventLimits.finishTimeoutSeconds,
      event.guest.finishTimeoutSeconds,
    );
    range(
      EventSetting.jpegQuality,
      EventLimits.jpegQuality,
      event.output.jpegQuality,
    );
    if (event.retention.mode == RetentionMode.deleteAfterDays) {
      range(
        EventSetting.retentionDays,
        EventLimits.retentionDays,
        event.retention.days ?? 0,
      );
    }

    final selection = event.templates;
    if (selection.revisionIds.length > EventLimits.maxTemplates) {
      issues.add(TooManyTemplates(selection.revisionIds.length));
    }
    final seen = <String>{};
    for (final id in selection.revisionIds) {
      if (!seen.add(id)) issues.add(DuplicateTemplate(id));
    }
    final defaultId = selection.defaultRevisionId;
    if (defaultId != null && !selection.revisionIds.contains(defaultId)) {
      issues.add(DefaultTemplateNotAllowed(defaultId));
    }
    return issues;
  }

  /// Problems with the event's templates, given what the library holds
  /// ([library] maps revision IDs to summaries; absent IDs are missing).
  static List<EventIssue> templateIssues(
    BoothEvent event,
    Map<String, TemplateRevisionSummary> library,
  ) {
    final selection = event.templates;
    if (selection.isEmpty) return const [NoTemplates()];
    final issues = <EventIssue>[];
    if (selection.defaultRevisionId == null) {
      issues.add(const DefaultTemplateMissing());
    }
    for (final id in selection.revisionIds) {
      final template = library[id];
      if (template == null) {
        issues.add(TemplateNotFound(id));
        continue;
      }
      if (template.photoSlotCount != event.capture.shotCount) {
        issues.add(TemplateSlotsMismatch(template, event.capture.shotCount));
      }
      if (template.templateArchived) issues.add(TemplateArchived(template));
    }
    return issues;
  }

  /// Everything that matters before activating [event].
  static List<EventIssue> activationIssues(
    BoothEvent event,
    Map<String, TemplateRevisionSummary> library,
  ) => [...structuralIssues(event), ...templateIssues(event, library)];

  /// Whether [issues] stop an event from being active.
  static bool blocksActivation(Iterable<EventIssue> issues) =>
      issues.any((issue) => issue.level != IssueLevel.warning);
}
