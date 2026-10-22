import '../experience/experience_registry.dart';
import '../models/booth_event.dart';
import '../models/booth_profile.dart';
import '../models/event_rules.dart';
import '../repositories/event_repository.dart';
import '../repositories/template_catalog.dart';
import '../value_objects/clock.dart';
import '../value_objects/entity_id.dart';

/// No event has the requested ID.
final class EventNotFoundException implements Exception {
  const EventNotFoundException(this.eventId);

  final String eventId;

  @override
  String toString() => 'EventNotFoundException($eventId)';
}

/// The event breaks a rule that the requested change requires.
final class EventRuleException implements Exception {
  const EventRuleException(this.issues);

  final List<EventIssue> issues;

  @override
  String toString() => 'EventRuleException(${issues.join(', ')})';
}

/// The event's lifecycle does not allow the requested change, e.g. editing
/// an archived event before reopening it (S04).
final class EventLifecycleException implements Exception {
  const EventLifecycleException(this.from, this.to);

  final EventStatus from;
  final EventStatus to;

  @override
  String toString() => 'EventLifecycleException(${from.name} -> ${to.name})';
}

/// Event use cases (A-02 EventUseCases): every change is validated here,
/// then stored atomically by the repository.
///
/// Lifecycle: draft -> active (only when valid) -> draft; draft or active
/// -> archived -> draft (reopen). Archiving never deletes photos.
final class EventService {
  EventService({
    required this._events,
    required this._templates,
    required this._clock,
    required this._ids,
  });

  final EventRepository _events;
  final TemplateCatalog _templates;
  final Clock _clock;
  final IdGenerator _ids;

  /// A new, unsaved draft that starts from [booth]'s defaults.
  BoothEvent newDraft(BoothProfile booth) {
    final now = _clock.now();
    return BoothEvent(
      id: _ids.newId(),
      title: '',
      status: EventStatus.draft,
      boothProfileId: booth.id,
      createdAt: now,
      updatedAt: now,
      capture: booth.defaults.toCaptureSettings(),
      output: booth.defaults.output,
      // Guests see what the booth looks like until the operator picks a
      // pack (EP01).
      experience: ExperienceRegistry.forAppearance(booth.appearance.profile),
    );
  }

  /// Saves the content of [event] (a new draft or an edit) and returns the
  /// stored value. An active event must stay valid; an archived event must
  /// be reopened first. The stored status is never changed here.
  Future<BoothEvent> save(BoothEvent event) async {
    final stored = await _events.findById(event.id);
    final status = stored?.status ?? EventStatus.draft;
    if (status == EventStatus.archived) {
      throw const EventLifecycleException(
        EventStatus.archived,
        EventStatus.archived,
      );
    }
    // The experience's revision moves on with every change to it (EP01).
    final experience = stored == null || stored.experience == event.experience
        ? event.experience.copyWith(
            revision: stored?.experience.revision ?? event.experience.revision,
          )
        : event.experience.copyWith(revision: stored.experience.revision + 1);
    final candidate = event.copyWith(
      title: event.title.trim(),
      experience: experience,
      status: status,
      createdAt: stored?.createdAt ?? event.createdAt,
      updatedAt: _clock.now(),
      archivedAt: null,
    );
    await _validate(candidate, forActive: status == EventStatus.active);
    await _events.save(candidate);
    return candidate;
  }

  /// A copy of the event as a new draft: same settings and templates, a new
  /// ID, no sessions (P-05).
  Future<BoothEvent> duplicate(
    String eventId, {
    required String copySuffix,
  }) async {
    final source = await _find(eventId);
    final now = _clock.now();
    final suffix = ' $copySuffix';
    final base =
        source.title.length + suffix.length > EventLimits.titleMaxLength
        ? source.title
              .substring(0, EventLimits.titleMaxLength - suffix.length)
              .trimRight()
        : source.title;
    final copy = source.copyWith(
      id: _ids.newId(),
      title: '$base$suffix',
      status: EventStatus.draft,
      createdAt: now,
      updatedAt: now,
      archivedAt: null,
    );
    await _validate(copy, forActive: false);
    await _events.save(copy);
    return copy;
  }

  /// Makes a valid draft available to run the booth.
  Future<BoothEvent> activate(String eventId) =>
      _transition(eventId, EventStatus.draft, EventStatus.active);

  /// Takes an active event out of use, back to drafts.
  Future<BoothEvent> returnToDraft(String eventId) =>
      _transition(eventId, EventStatus.active, EventStatus.draft);

  /// Archives a draft or active event. Its photos are kept.
  Future<BoothEvent> archive(String eventId) async {
    final event = await _find(eventId);
    if (event.status == EventStatus.archived) {
      throw const EventLifecycleException(
        EventStatus.archived,
        EventStatus.archived,
      );
    }
    final now = _clock.now();
    final archived = event.copyWith(
      status: EventStatus.archived,
      archivedAt: now,
      updatedAt: now,
    );
    await _events.save(archived);
    return archived;
  }

  /// Reopens an archived event as a draft.
  Future<BoothEvent> reopen(String eventId) =>
      _transition(eventId, EventStatus.archived, EventStatus.draft);

  Future<BoothEvent> _transition(
    String eventId,
    EventStatus from,
    EventStatus to,
  ) async {
    final event = await _find(eventId);
    if (event.status != from) throw EventLifecycleException(event.status, to);
    final now = _clock.now();
    final next = event.copyWith(status: to, updatedAt: now, archivedAt: null);
    await _validate(next, forActive: to == EventStatus.active);
    await _events.save(next);
    return next;
  }

  /// Every issue that would stop [event] from being activated, for display.
  Future<List<EventIssue>> activationIssues(BoothEvent event) async {
    final library = await _templates.findRevisions(event.templates.revisionIds);
    return EventRules.activationIssues(event, library);
  }

  Future<void> _validate(BoothEvent event, {required bool forActive}) async {
    if (!isEntityId(event.id)) {
      throw ArgumentError.value(event.id, 'id', 'not an entity ID');
    }
    final issues = forActive
        ? await activationIssues(event)
        : EventRules.structuralIssues(event);
    final failing = issues.where(
      (issue) =>
          issue.level == IssueLevel.invalid ||
          (forActive && issue.level == IssueLevel.blocking),
    );
    if (failing.isNotEmpty) throw EventRuleException(failing.toList());
  }

  Future<BoothEvent> _find(String eventId) async =>
      await _events.findById(eventId) ??
      (throw EventNotFoundException(eventId));
}
