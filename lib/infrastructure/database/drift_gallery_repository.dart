import 'package:drift/drift.dart';

import '../../domain/gallery/export_plan.dart';
import '../../domain/gallery/gallery_models.dart';
import '../../domain/models/booth_event.dart';
import '../../domain/repositories/gallery_repository.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/repositories/storage_errors.dart';
import '../../domain/repositories/template_catalog.dart';
import '../../domain/services/gallery_services.dart';
import '../../domain/value_objects/clock.dart';
import '../file_store/managed_thumbnail_store.dart';
import '../file_store/original_store.dart';
import 'booth_database.dart';
import 'drift_session_repository.dart';
import 'persistence_guard.dart';

/// The operator gallery over the booth database (schema version 6, P-11,
/// AC-0801..AC-0805).
///
/// Listing reads light rows with one query per event; images are never
/// read here. Deleting removes the records of sessions, their photos,
/// originals, finished photos and export history in one transaction that
/// also writes every file they owned (thumbnails included) to
/// `pending_file_deletions`; `ManagedStorageCleanup` removes the files.
final class DriftGalleryRepository implements GalleryRepository {
  DriftGalleryRepository(
    this._db, {
    required this._clock,
    required this._templates,
  }) : _sessions = DriftSessionRepository(_db, clock: _clock);

  final BoothDatabase _db;
  final Clock _clock;
  final TemplateCatalog _templates;
  final DriftSessionRepository _sessions;

  /// Sessions a guest is still in; the gallery never deletes them.
  static const _inProgress = ['capturing', 'reviewing'];

  /// Ids per query, well under SQLite's variable limit.
  static const _chunk = 500;

  @override
  Future<List<GalleryEventSummary>> events() => _guard(() async {
    final rows = await _db
        .customSelect(
          'SELECT e.id, e.title, e.status, e.retention_mode, '
          'e.retention_days, e.updated_at, '
          'COUNT(s.id) AS session_count, '
          'COALESCE(SUM(EXISTS (SELECT 1 FROM session_outputs o '
          'WHERE o.session_id = s.id)), 0) AS finished_count, '
          'MIN(s.started_at) AS first_at, MAX(s.started_at) AS last_at '
          'FROM events e LEFT JOIN capture_sessions s ON s.event_id = e.id '
          'GROUP BY e.id '
          'ORDER BY last_at IS NULL, last_at DESC, e.updated_at DESC, e.id',
          readsFrom: {_db.events, _db.captureSessions, _db.sessionOutputs},
        )
        .get();
    return [
      for (final row in rows)
        GalleryEventSummary(
          eventId: row.read<String>('id'),
          title: row.read<String>('title'),
          status: EventStatus.values.byName(row.read<String>('status')),
          retention: switch (RetentionMode.values.byName(
            row.read<String>('retention_mode'),
          )) {
            RetentionMode.keepUntilDeleted =>
              const RetentionPolicy.keepUntilDeleted(),
            RetentionMode.deleteAfterDays => RetentionPolicy.deleteAfterDays(
              row.read<int>('retention_days'),
            ),
          },
          sessionCount: row.read<int>('session_count'),
          finishedCount: row.read<int>('finished_count'),
          firstSessionAtUtc: row.readNullable<DateTime>('first_at')?.toUtc(),
          lastSessionAtUtc: row.readNullable<DateTime>('last_at')?.toUtc(),
        ),
    ];
  });

  @override
  Future<List<GallerySession>> sessions(String eventId) => _guard(() async {
    final rows = await _db
        .customSelect(
          'SELECT s.id, s.event_id, s.sequence, s.status, s.end_reason, '
          's.started_at, s.ended_at, s.planned_shots, '
          '(SELECT COUNT(*) FROM session_photos p '
          'WHERE p.session_id = s.id) AS photo_count, '
          '(SELECT COUNT(*) FROM session_outputs o '
          'WHERE o.session_id = s.id) AS output_count, '
          '(SELECT COUNT(DISTINCT p.shot_index) FROM session_photos p '
          'WHERE p.session_id = s.id AND p.round = (SELECT MAX(q.round) '
          'FROM session_photos q WHERE q.session_id = s.id)) AS set_shots, '
          '(SELECT p.original_id FROM session_photos p '
          'WHERE p.session_id = s.id '
          'ORDER BY p.shot_index, p.attempt DESC LIMIT 1) AS cover_id, '
          '(SELECT MAX(b.created_at) FROM export_batch_items i '
          'JOIN export_batches b ON b.id = i.batch_id '
          'WHERE i.session_id = s.id) AS exported_at, '
          'o.id AS output_id, o.relative_path AS output_path, '
          'o.sha256 AS output_sha256, o.byte_length AS output_bytes, '
          'o.width_px AS output_width, o.height_px AS output_height, '
          'o.format AS output_format '
          'FROM capture_sessions s '
          'LEFT JOIN session_outputs o ON o.id = (SELECT x.id '
          'FROM session_outputs x WHERE x.session_id = s.id '
          'ORDER BY x.created_at DESC, x.id DESC LIMIT 1) '
          'WHERE s.event_id = ? '
          'ORDER BY s.started_at DESC, s.id DESC',
          variables: [Variable<String>(eventId)],
          readsFrom: {
            _db.captureSessions,
            _db.sessionPhotos,
            _db.sessionOutputs,
            _db.exportBatches,
            _db.exportBatchItems,
          },
        )
        .get();
    return [
      for (final row in rows)
        GallerySession(
          id: row.read<String>('id'),
          eventId: row.read<String>('event_id'),
          number: row.read<int>('sequence'),
          status: SessionStatus.values.byName(row.read<String>('status')),
          endReason: switch (row.readNullable<String>('end_reason')) {
            null => null,
            final reason => SessionEndReason.values.byName(reason),
          },
          startedAtUtc: row.read<DateTime>('started_at').toUtc(),
          endedAtUtc: row.readNullable<DateTime>('ended_at')?.toUtc(),
          plannedShots: row.read<int>('planned_shots'),
          photoCount: row.read<int>('photo_count'),
          outputCount: row.read<int>('output_count'),
          setComplete:
              row.read<int>('set_shots') == row.read<int>('planned_shots'),
          coverOriginalId: row.readNullable<String>('cover_id'),
          lastExportedAtUtc: row.readNullable<DateTime>('exported_at')?.toUtc(),
          latestOutput: switch (row.readNullable<String>('output_id')) {
            null => null,
            final id => GalleryOutput(
              id: id,
              relativePath: row.read<String>('output_path'),
              sha256: row.read<String>('output_sha256'),
              byteLength: row.read<int>('output_bytes'),
              widthPx: row.read<int>('output_width'),
              heightPx: row.read<int>('output_height'),
              format: OutputFormat.values.byName(
                row.read<String>('output_format'),
              ),
            ),
          },
        ),
    ];
  });

  @override
  Future<SessionDetail?> detail(String sessionId) => _guard(() async {
    final session = await _sessions.find(sessionId);
    if (session == null) return null;
    final event = await (_db.select(
      _db.events,
    )..where((e) => e.id.equals(session.plan.eventId))).getSingle();
    final outputs = await _sessions.outputs(sessionId);
    final ids = {for (final photo in session.photos) photo.originalId};
    final originals = ids.isEmpty
        ? const <OriginalPhotoRow>[]
        : await (_db.select(
            _db.originalPhotos,
          )..where((o) => o.id.isIn(ids))).get();
    final template = (await _templates.findRevisions([
      session.plan.templateRevisionId,
    ]))[session.plan.templateRevisionId];
    return SessionDetail(
      session: session,
      number: session.number,
      eventTitle: event.title,
      outputs: outputs,
      originals: {
        for (final row in originals) row.id: OriginalStore.stillOf(row),
      },
      exports: await _exportsOf(sessionId),
      template: template,
    );
  });

  Future<List<ExportRecordSummary>> _exportsOf(String sessionId) async {
    final rows =
        await (_db.select(_db.exportBatchItems).join([
                innerJoin(
                  _db.exportBatches,
                  _db.exportBatches.id.equalsExp(_db.exportBatchItems.batchId),
                ),
              ])
              ..where(_db.exportBatchItems.sessionId.equals(sessionId))
              ..orderBy([
                OrderingTerm.desc(_db.exportBatches.createdAt),
                OrderingTerm.asc(_db.exportBatchItems.fileName),
              ]))
            .get();
    final batches = <String, ExportBatchRow>{};
    final names = <String, List<String>>{};
    for (final row in rows) {
      final batch = row.readTable(_db.exportBatches);
      batches[batch.id] = batch;
      (names[batch.id] ??= []).add(
        row.readTable(_db.exportBatchItems).fileName,
      );
    }
    return [
      for (final batch in batches.values)
        ExportRecordSummary(
          id: batch.id,
          createdAtUtc: batch.createdAt.toUtc(),
          outcome: batch.outcome,
          destination: batch.destination,
          fileNames: List.unmodifiable(names[batch.id]!),
        ),
    ];
  }

  @override
  Future<List<SessionFiles>> files(List<String> sessionIds) => _guard(() async {
    final found = <String, SessionFiles>{};
    for (var start = 0; start < sessionIds.length; start += _chunk) {
      final ids = sessionIds
          .sublist(
            start,
            start + _chunk < sessionIds.length
                ? start + _chunk
                : sessionIds.length,
          )
          .toSet();
      final sessions = await (_db.select(_db.captureSessions).join([
        innerJoin(
          _db.events,
          _db.events.id.equalsExp(_db.captureSessions.eventId),
        ),
      ])..where(_db.captureSessions.id.isIn(ids))).get();
      final outputs =
          await (_db.select(_db.sessionOutputs)
                ..where((o) => o.sessionId.isIn(ids))
                ..orderBy([
                  (o) => OrderingTerm.asc(o.createdAt),
                  (o) => OrderingTerm.asc(o.id),
                ]))
              .get();
      final photos =
          await (_db.select(_db.sessionPhotos).join([
                  leftOuterJoin(
                    _db.originalPhotos,
                    _db.originalPhotos.id.equalsExp(
                      _db.sessionPhotos.originalId,
                    ),
                  ),
                ])
                ..where(_db.sessionPhotos.sessionId.isIn(ids))
                ..orderBy([
                  OrderingTerm.asc(_db.sessionPhotos.capturedAt),
                  OrderingTerm.asc(_db.sessionPhotos.shotIndex),
                  OrderingTerm.asc(_db.sessionPhotos.attempt),
                ]))
              .get();
      for (final row in sessions) {
        final session = row.readTable(_db.captureSessions);
        found[session.id] = SessionFiles(
          sessionId: session.id,
          number: session.sequence,
          eventTitle: row.readTable(_db.events).title,
          startedAtUtc: session.startedAt.toUtc(),
          outputs: [
            for (final output in outputs)
              if (output.sessionId == session.id)
                ExportableOutput(
                  id: output.id,
                  relativePath: output.relativePath,
                  sha256: output.sha256,
                  byteLength: output.byteLength,
                  format: output.format,
                ),
          ],
          photos: [
            for (final photo in photos)
              if (photo.readTable(_db.sessionPhotos).sessionId == session.id)
                _exportable(
                  photo.readTable(_db.sessionPhotos),
                  photo.readTableOrNull(_db.originalPhotos),
                ),
          ],
        );
      }
    }
    return [for (final id in sessionIds) ?found[id]];
  });

  static ExportablePhoto _exportable(
    SessionPhotoRow photo,
    OriginalPhotoRow? original,
  ) => ExportablePhoto(
    shot: photo.shotIndex,
    attempt: photo.attempt,
    originalId: photo.originalId,
    relativePath: original?.relativePath,
    sha256: original?.sha256,
    byteLength: original?.byteLength,
  );

  @override
  Future<StorageUsage> usage({String? eventId}) => _guard(() async {
    final scoped = eventId != null;
    final where = scoped ? 'WHERE s.event_id = ?' : '';
    final variables = [if (scoped) Variable<String>(eventId)];
    final sessions = await _db
        .customSelect(
          'SELECT COUNT(*) AS n FROM capture_sessions s $where',
          variables: variables,
          readsFrom: {_db.captureSessions},
        )
        .getSingle();
    final finished = await _db
        .customSelect(
          'SELECT COUNT(o.id) AS n, COALESCE(SUM(o.byte_length), 0) AS bytes '
          'FROM session_outputs o '
          'JOIN capture_sessions s ON s.id = o.session_id $where',
          variables: variables,
          readsFrom: {_db.sessionOutputs, _db.captureSessions},
        )
        .getSingle();
    final originals = await _db
        .customSelect(
          'SELECT COUNT(op.id) AS n, COALESCE(SUM(op.byte_length), 0) AS bytes '
          'FROM session_photos p '
          'JOIN original_photos op ON op.id = p.original_id '
          'JOIN capture_sessions s ON s.id = p.session_id $where',
          variables: variables,
          readsFrom: {
            _db.sessionPhotos,
            _db.originalPhotos,
            _db.captureSessions,
          },
        )
        .getSingle();
    final unassigned = scoped
        ? null
        : await _db
              .customSelect(
                'SELECT COUNT(op.id) AS n, '
                'COALESCE(SUM(op.byte_length), 0) AS bytes '
                'FROM original_photos op WHERE NOT EXISTS (SELECT 1 '
                'FROM session_photos p WHERE p.original_id = op.id)',
                readsFrom: {_db.originalPhotos, _db.sessionPhotos},
              )
              .getSingle();
    final pending = await _db
        .customSelect(
          'SELECT COUNT(*) AS n FROM pending_file_deletions',
          readsFrom: {_db.pendingFileDeletions},
        )
        .getSingle();
    return StorageUsage(
      sessionCount: sessions.read<int>('n'),
      finishedCount: finished.read<int>('n'),
      finishedBytes: finished.read<int>('bytes'),
      originalCount: originals.read<int>('n'),
      originalBytes: originals.read<int>('bytes'),
      unassignedCount: unassigned?.read<int>('n') ?? 0,
      unassignedBytes: unassigned?.read<int>('bytes') ?? 0,
      pendingCleanup: pending.read<int>('n'),
    );
  });

  @override
  Future<List<String>> sessionsStartedBefore(
    String eventId,
    DateTime beforeUtc,
  ) => _guard(() async {
    final rows =
        await (_db.select(_db.captureSessions)
              ..where(
                (s) =>
                    s.eventId.equals(eventId) &
                    s.startedAt.isSmallerThanValue(beforeUtc.toUtc()) &
                    s.status.isNotInValues(const [
                      SessionStatus.capturing,
                      SessionStatus.reviewing,
                    ]),
              )
              ..orderBy([
                (s) => OrderingTerm.asc(s.startedAt),
                (s) => OrderingTerm.asc(s.id),
              ]))
            .get();
    return [for (final row in rows) row.id];
  });

  @override
  Future<void> recordExport(ExportRecord record) => _guard(
    () => _db.transaction(() async {
      final sessionIds = {for (final file in record.files) file.sessionId};
      final existing = <String>{};
      for (final id in sessionIds) {
        final row = await (_db.select(
          _db.captureSessions,
        )..where((s) => s.id.equals(id))).getSingleOrNull();
        if (row != null) existing.add(id);
      }
      final files = [
        for (final file in record.files)
          if (existing.contains(file.sessionId)) file,
      ];
      if (files.isEmpty) return;
      await _db
          .into(_db.exportBatches)
          .insert(
            ExportBatchesCompanion.insert(
              id: record.id,
              outcome: record.outcome,
              destination: Value(_destination(record.destination)),
              fileCount: files.length,
              failureCount: record.failureCount,
              createdAt: record.createdAtUtc,
            ),
          );
      await _db.batch(
        (batch) => batch.insertAll(_db.exportBatchItems, [
          for (final file in files)
            ExportBatchItemsCompanion.insert(
              batchId: record.id,
              sessionId: file.sessionId,
              kind: file.kind,
              sourceId: file.sourceId,
              fileName: file.fileName,
            ),
        ], mode: InsertMode.insertOrIgnore),
      );
    }),
  );

  /// A platform's destination name, trimmed to what the record keeps.
  static String? _destination(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    return value.length > 200 ? value.substring(0, 200) : value;
  }

  @override
  Future<DeletionReceipt> deleteSessions(List<String> sessionIds) => _guard(
    () => _db.transaction(() async {
      final ids = sessionIds.toSet();
      var receipt = const DeletionReceipt(
        sessions: 0,
        originals: 0,
        outputs: 0,
        files: 0,
      );
      final list = ids.toList();
      for (var start = 0; start < list.length; start += _chunk) {
        final chunk = list.sublist(
          start,
          start + _chunk < list.length ? start + _chunk : list.length,
        );
        receipt = _sum(receipt, await _deleteSessionRows(chunk.toSet()));
      }
      return receipt;
    }),
  );

  /// Deletes [ids]' rows and journals their files. Runs inside a
  /// transaction.
  Future<DeletionReceipt> _deleteSessionRows(Set<String> ids) async {
    final sessions = await (_db.select(
      _db.captureSessions,
    )..where((s) => s.id.isIn(ids))).get();
    if (sessions.any((s) => _inProgress.contains(s.status.name))) {
      throw const GalleryException('GALLERY_SESSION_IN_PROGRESS');
    }
    final found = {for (final session in sessions) session.id};
    if (found.isEmpty) {
      return const DeletionReceipt(
        sessions: 0,
        originals: 0,
        outputs: 0,
        files: 0,
      );
    }
    final outputs = await (_db.select(
      _db.sessionOutputs,
    )..where((o) => o.sessionId.isIn(found))).get();
    final photos = await (_db.select(
      _db.sessionPhotos,
    )..where((p) => p.sessionId.isIn(found))).get();
    final originalIds = {for (final photo in photos) photo.originalId};
    final originals = originalIds.isEmpty
        ? const <OriginalPhotoRow>[]
        : await (_db.select(
            _db.originalPhotos,
          )..where((o) => o.id.isIn(originalIds))).get();

    final paths = <String>[
      for (final output in outputs) ...[
        output.relativePath,
        ManagedThumbnailStore.relativePathFor(ThumbnailKind.output, output.id),
      ],
      for (final original in originals) ...[
        original.relativePath,
        ManagedThumbnailStore.relativePathFor(
          ThumbnailKind.original,
          original.id,
        ),
      ],
    ];
    await _journal(paths);
    await (_db.delete(
      _db.exportBatchItems,
    )..where((i) => i.sessionId.isIn(found))).go();
    await (_db.delete(
      _db.sessionOutputs,
    )..where((o) => o.sessionId.isIn(found))).go();
    await (_db.delete(
      _db.sessionPhotos,
    )..where((p) => p.sessionId.isIn(found))).go();
    await (_db.delete(
      _db.captureSessions,
    )..where((s) => s.id.isIn(found))).go();
    if (originalIds.isNotEmpty) {
      await (_db.delete(
        _db.originalPhotos,
      )..where((o) => o.id.isIn(originalIds))).go();
    }
    return DeletionReceipt(
      sessions: found.length,
      originals: originals.length,
      outputs: outputs.length,
      files: outputs.length + originals.length,
    );
  }

  Future<void> _journal(List<String> paths) async {
    final now = _clock.now();
    await _db.batch(
      (batch) => batch.insertAll(_db.pendingFileDeletions, [
        for (final path in paths)
          PendingFileDeletionsCompanion.insert(
            relativePath: path,
            queuedAt: now,
          ),
      ], mode: InsertMode.insertOrIgnore),
    );
  }

  static DeletionReceipt _sum(DeletionReceipt a, DeletionReceipt b) =>
      DeletionReceipt(
        sessions: a.sessions + b.sessions,
        originals: a.originals + b.originals,
        outputs: a.outputs + b.outputs,
        files: a.files + b.files,
      );

  @override
  Future<DeletionReceipt> deleteEvent(String eventId) => _guard(
    () => _db.transaction(() async {
      final event = await (_db.select(
        _db.events,
      )..where((e) => e.id.equals(eventId))).getSingleOrNull();
      if (event == null) throw const GalleryException('GALLERY_EVENT_UNKNOWN');
      if (event.status != EventStatus.archived) {
        throw const GalleryException('GALLERY_EVENT_NOT_ARCHIVED');
      }
      final sessions = await (_db.select(
        _db.captureSessions,
      )..where((s) => s.eventId.equals(eventId))).get();
      var receipt = const DeletionReceipt(
        sessions: 0,
        originals: 0,
        outputs: 0,
        files: 0,
      );
      final ids = [for (final session in sessions) session.id];
      for (var start = 0; start < ids.length; start += _chunk) {
        final chunk = ids.sublist(
          start,
          start + _chunk < ids.length ? start + _chunk : ids.length,
        );
        receipt = _sum(receipt, await _deleteSessionRows(chunk.toSet()));
      }
      await (_db.delete(_db.events)..where((e) => e.id.equals(eventId))).go();
      return receipt;
    }),
  );

  @override
  Future<DeletionReceipt> deleteUnassignedOriginals() => _guard(
    () => _db.transaction(() async {
      final rows = await _db
          .customSelect(
            'SELECT op.id, op.relative_path FROM original_photos op '
            'WHERE NOT EXISTS (SELECT 1 FROM session_photos p '
            'WHERE p.original_id = op.id)',
            readsFrom: {_db.originalPhotos, _db.sessionPhotos},
          )
          .get();
      final ids = [for (final row in rows) row.read<String>('id')];
      await _journal([
        for (final row in rows) ...[
          row.read<String>('relative_path'),
          ManagedThumbnailStore.relativePathFor(
            ThumbnailKind.original,
            row.read<String>('id'),
          ),
        ],
      ]);
      for (var start = 0; start < ids.length; start += _chunk) {
        final chunk = ids.sublist(
          start,
          start + _chunk < ids.length ? start + _chunk : ids.length,
        );
        await (_db.delete(
          _db.originalPhotos,
        )..where((o) => o.id.isIn(chunk))).go();
      }
      return DeletionReceipt(
        sessions: 0,
        originals: ids.length,
        outputs: 0,
        files: ids.length,
      );
    }),
  );

  @override
  Future<void> discardFiles(List<String> relativePaths) => _guard(
    () => _db.transaction(() async {
      final unreferenced = <String>[];
      for (final path in relativePaths.toSet()) {
        final output = await (_db.select(
          _db.sessionOutputs,
        )..where((o) => o.relativePath.equals(path))).getSingleOrNull();
        final original = await (_db.select(
          _db.originalPhotos,
        )..where((o) => o.relativePath.equals(path))).getSingleOrNull();
        if (output == null && original == null) unreferenced.add(path);
      }
      await _journal(unreferenced);
    }),
  );

  /// Schema rule failures become [GalleryException]s.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await guardPersistence(action);
    } on PersistenceRuleException {
      throw const GalleryException('GALLERY_RULE_REFUSED');
    }
  }
}
