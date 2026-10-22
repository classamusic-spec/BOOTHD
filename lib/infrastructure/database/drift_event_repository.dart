import 'package:collection/collection.dart';
import 'package:drift/drift.dart';

import '../../domain/delivery/delivery_settings.dart';
import '../../domain/models/booth_event.dart';
import '../../domain/repositories/event_repository.dart';
import 'booth_database.dart';
import 'persistence_guard.dart';

/// Events in the booth database. An event, its template selection and its
/// delivery settings are read in one query and written in one transaction.
final class DriftEventRepository implements EventRepository {
  DriftEventRepository(this._db);

  final BoothDatabase _db;

  JoinedSelectStatement<HasResultSet, dynamic> _withTemplates() =>
      _db.select(_db.events).join([
        leftOuterJoin(
          _db.eventTemplates,
          _db.eventTemplates.eventId.equalsExp(_db.events.id),
        ),
        leftOuterJoin(
          _db.eventDeliveryOptions,
          _db.eventDeliveryOptions.eventId.equalsExp(_db.events.id),
        ),
      ])..orderBy([
        OrderingTerm.desc(_db.events.updatedAt),
        OrderingTerm.asc(_db.events.id),
        OrderingTerm.asc(_db.eventTemplates.position),
      ]);

  @override
  Stream<List<BoothEvent>> watchAll() =>
      _withTemplates().watch().map(_assemble);

  @override
  Stream<BoothEvent?> watchById(String id) =>
      (_withTemplates()..where(_db.events.id.equals(id))).watch().map(
        (rows) => _assemble(rows).firstOrNull,
      );

  @override
  Future<BoothEvent?> findById(String id) async =>
      _assemble(await (_withTemplates()..where(_db.events.id.equals(id))).get())
          .firstOrNull;

  @override
  Future<void> save(BoothEvent event) => guardPersistence(
    () => _db.transaction(() async {
      await _db.into(_db.events).insertOnConflictUpdate(_toRow(event));
      final delivery = event.delivery;
      await _db
          .into(_db.eventDeliveryOptions)
          .insertOnConflictUpdate(
            EventDeliveryOptionsCompanion.insert(
              eventId: event.id,
              enabled: delivery.enabled,
              offlineQueue: delivery.offlineQueue,
              linkDays: delivery.linkDays,
              sendLimit: delivery.sendLimit,
            ),
          );
      await (_db.delete(
        _db.eventTemplates,
      )..where((link) => link.eventId.equals(event.id))).go();
      final selection = event.templates;
      for (final (position, revisionId) in selection.revisionIds.indexed) {
        await _db
            .into(_db.eventTemplates)
            .insert(
              EventTemplatesCompanion.insert(
                eventId: event.id,
                templateRevisionId: revisionId,
                position: position,
                isDefault: revisionId == selection.defaultRevisionId,
              ),
            );
      }
    }),
  );

  List<BoothEvent> _assemble(List<TypedResult> rows) {
    final grouped =
        <
          String,
          (EventRow, List<EventTemplateRow>, EventDeliverySettingsRow?)
        >{};
    for (final row in rows) {
      final event = row.readTable(_db.events);
      final link = row.readTableOrNull(_db.eventTemplates);
      final delivery = row.readTableOrNull(_db.eventDeliveryOptions);
      final entry = grouped.putIfAbsent(event.id, () => (event, [], delivery));
      if (link != null) entry.$2.add(link);
    }
    return [
      for (final (event, links, delivery) in grouped.values)
        _toDomain(event, links, delivery),
    ];
  }

  BoothEvent _toDomain(
    EventRow row,
    List<EventTemplateRow> links,
    EventDeliverySettingsRow? delivery,
  ) {
    final ordered = links.sortedBy<num>((link) => link.position);
    return BoothEvent(
      id: row.id,
      title: row.title,
      date: row.eventDate,
      venue: row.venue,
      notes: row.notes,
      status: row.status,
      boothProfileId: row.boothProfileId,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      archivedAt: row.archivedAt,
      capture: CaptureSettings(
        lens: row.lens,
        mirrorPreview: row.mirrorPreview,
        mirrorOutput: row.mirrorOutput,
        orientation: row.guestOrientation,
        shotCount: row.shotCount,
        countdownSeconds: row.countdownSeconds,
        shotIntervalSeconds: row.shotIntervalSeconds,
        retakePolicy: row.retakePolicy,
        retakeLimit: row.retakeLimit,
      ),
      guest: GuestSettings(
        welcomeTitle: row.welcomeTitle,
        welcomeMessage: row.welcomeMessage,
        consentText: row.consentText,
        guestChoosesTemplate: row.guestChoosesTemplate,
        finishTimeoutSeconds: row.finishTimeoutSeconds,
      ),
      experience: row.experienceJson,
      output: OutputProfile(
        format: row.outputFormat,
        jpegQuality: row.jpegQuality,
      ),
      retention: switch (row.retentionMode) {
        RetentionMode.keepUntilDeleted =>
          const RetentionPolicy.keepUntilDeleted(),
        RetentionMode.deleteAfterDays => RetentionPolicy.deleteAfterDays(
          row.retentionDays!,
        ),
      },
      templates: TemplateSelection(
        revisionIds: [for (final link in ordered) link.templateRevisionId],
        defaultRevisionId: ordered
            .firstWhereOrNull((link) => link.isDefault)
            ?.templateRevisionId,
      ),
      delivery: delivery == null
          ? const EventDeliverySettings()
          : EventDeliverySettings(
              enabled: delivery.enabled,
              offlineQueue: delivery.offlineQueue,
              linkDays: delivery.linkDays,
              sendLimit: delivery.sendLimit,
            ),
    );
  }

  EventsCompanion _toRow(BoothEvent event) => EventsCompanion.insert(
    id: event.id,
    boothProfileId: event.boothProfileId,
    title: event.title,
    eventDate: Value(event.date),
    venue: Value(event.venue),
    notes: Value(event.notes),
    status: event.status,
    lens: event.capture.lens,
    mirrorPreview: event.capture.mirrorPreview,
    mirrorOutput: event.capture.mirrorOutput,
    guestOrientation: event.capture.orientation,
    shotCount: event.capture.shotCount,
    countdownSeconds: event.capture.countdownSeconds,
    shotIntervalSeconds: event.capture.shotIntervalSeconds,
    retakePolicy: event.capture.retakePolicy,
    retakeLimit: event.capture.retakeLimit,
    welcomeTitle: Value(event.guest.welcomeTitle),
    welcomeMessage: Value(event.guest.welcomeMessage),
    consentText: Value(event.guest.consentText),
    guestChoosesTemplate: event.guest.guestChoosesTemplate,
    finishTimeoutSeconds: event.guest.finishTimeoutSeconds,
    experienceJson: event.experience,
    outputFormat: event.output.format,
    jpegQuality: event.output.jpegQuality,
    retentionMode: event.retention.mode,
    retentionDays: Value(event.retention.days),
    createdAt: event.createdAt,
    updatedAt: event.updatedAt,
    archivedAt: Value(event.archivedAt),
  );
}
