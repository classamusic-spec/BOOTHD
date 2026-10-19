import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/repositories/session_repository.dart';
import '../../domain/repositories/storage_errors.dart';
import '../../domain/services/export_service.dart';
import '../../domain/session/session_plan.dart';
import '../../domain/session/session_shots.dart';
import '../../domain/value_objects/clock.dart';
import 'booth_database.dart';
import 'persistence_guard.dart';

/// Guest sessions in the booth database (schema version 5, A-10, A-11).
///
/// Every change is one transaction that re-reads the session and applies
/// the domain's rules ([SessionShots]) before writing, so a session's rows
/// always describe a state the guest flow could reach. Photos and finished
/// photos are only ever added; the database's triggers refuse changes.
final class DriftSessionRepository implements SessionRepository {
  DriftSessionRepository(this._db, {required this._clock});

  final BoothDatabase _db;
  final Clock _clock;

  static const _unfinished = [
    SessionStatus.capturing,
    SessionStatus.reviewing,
    SessionStatus.rendering,
  ];

  @override
  Future<void> create({
    required String id,
    required SessionPlan plan,
    required DateTime startedAtUtc,
  }) => _guard(
    () => _db
        .into(_db.captureSessions)
        .insert(
          CaptureSessionsCompanion.insert(
            id: id,
            eventId: plan.eventId,
            templateRevisionId: plan.templateRevisionId,
            plannedShots: plan.shotCount,
            planJson: jsonEncode(plan.toJson()),
            status: SessionStatus.capturing,
            startedAt: startedAtUtc,
            updatedAt: startedAtUtc,
          ),
        ),
  );

  @override
  Future<void> addPhoto(String sessionId, ShotPhoto photo) => _guard(
    () => _db.transaction(() async {
      final session = await _require(sessionId, const {
        SessionStatus.capturing,
        SessionStatus.reviewing,
      });
      try {
        session.shots.record(photo);
      } on InvalidShotPhoto {
        throw const SessionStoreException('SESSION_PHOTO_REJECTED');
      }
      await _db
          .into(_db.sessionPhotos)
          .insert(
            SessionPhotosCompanion.insert(
              sessionId: sessionId,
              shotIndex: photo.shot,
              attempt: photo.attempt,
              round: photo.round,
              slotIndex: session.plan.slotFor(photo.shot),
              originalId: photo.originalId,
              capturedAt: photo.capturedAtUtc,
            ),
          );
      await _touch(sessionId);
    }),
  );

  @override
  Future<void> markReviewing(String sessionId) => _guard(
    () => _db.transaction(() async {
      final session = await _require(sessionId, const {
        SessionStatus.capturing,
        SessionStatus.reviewing,
      });
      if (!session.shots.isComplete) {
        throw const SessionStoreException('SESSION_SET_INCOMPLETE');
      }
      await _setStatus(sessionId, SessionStatus.reviewing);
    }),
  );

  @override
  Future<int> beginRender(String sessionId) => _guard(
    () => _db.transaction(() async {
      final session = await _require(sessionId, const {
        SessionStatus.reviewing,
        SessionStatus.rendering,
      });
      if (!session.shots.isComplete) {
        throw const SessionStoreException('SESSION_SET_INCOMPLETE');
      }
      final attempts = session.renderAttempts + 1;
      await (_db.update(
        _db.captureSessions,
      )..where((s) => s.id.equals(sessionId))).write(
        CaptureSessionsCompanion(
          status: const Value(SessionStatus.rendering),
          renderAttempts: Value(attempts),
          updatedAt: Value(_clock.now()),
        ),
      );
      return attempts;
    }),
  );

  @override
  Future<SessionOutput> complete(String sessionId, ExportedFile output) =>
      _guard(
        () => _db.transaction(() async {
          await _require(sessionId, const {SessionStatus.rendering});
          final now = _clock.now();
          final record = SessionOutput(
            id: output.id,
            sessionId: sessionId,
            relativePath: output.relativePath,
            sha256: output.sha256,
            byteLength: output.byteLength,
            widthPx: output.widthPx,
            heightPx: output.heightPx,
            format: output.format,
            renderVersion: output.renderVersion,
            createdAtUtc: now,
          );
          await _db
              .into(_db.sessionOutputs)
              .insert(
                SessionOutputsCompanion.insert(
                  id: record.id,
                  sessionId: sessionId,
                  relativePath: record.relativePath,
                  sha256: record.sha256,
                  byteLength: record.byteLength,
                  widthPx: record.widthPx,
                  heightPx: record.heightPx,
                  format: record.format,
                  renderVersion: record.renderVersion,
                  createdAt: now,
                ),
              );
          await (_db.update(
            _db.captureSessions,
          )..where((s) => s.id.equals(sessionId))).write(
            CaptureSessionsCompanion(
              status: const Value(SessionStatus.completed),
              outputId: Value(record.id),
              endedAt: Value(now),
              updatedAt: Value(now),
            ),
          );
          return record;
        }),
      );

  @override
  Future<void> end(
    String sessionId, {
    required SessionStatus status,
    required SessionEndReason reason,
  }) {
    if (status != SessionStatus.abandoned && status != SessionStatus.failed) {
      throw ArgumentError.value(status, 'status', 'abandoned or failed');
    }
    return _guard(
      () => _db.transaction(() async {
        await _require(sessionId, _unfinished.toSet());
        final now = _clock.now();
        await (_db.update(
          _db.captureSessions,
        )..where((s) => s.id.equals(sessionId))).write(
          CaptureSessionsCompanion(
            status: Value(status),
            endReason: Value(reason),
            endedAt: Value(now),
            updatedAt: Value(now),
          ),
        );
      }),
    );
  }

  @override
  Future<SessionRecord?> find(String sessionId) => _guard(() async {
    final row = await (_db.select(
      _db.captureSessions,
    )..where((s) => s.id.equals(sessionId))).getSingleOrNull();
    return row == null ? null : _record(row);
  });

  @override
  Future<List<SessionRecord>> unfinished() => _guard(() async {
    final rows =
        await (_db.select(_db.captureSessions)
              ..where((s) => s.status.isInValues(_unfinished))
              ..orderBy([
                (s) => OrderingTerm.asc(s.startedAt),
                (s) => OrderingTerm.asc(s.id),
              ]))
            .get();
    return [for (final row in rows) await _record(row)];
  });

  @override
  Future<SessionOutput?> output(String outputId) => _guard(() async {
    final row = await (_db.select(
      _db.sessionOutputs,
    )..where((o) => o.id.equals(outputId))).getSingleOrNull();
    return row == null
        ? null
        : SessionOutput(
            id: row.id,
            sessionId: row.sessionId,
            relativePath: row.relativePath,
            sha256: row.sha256,
            byteLength: row.byteLength,
            widthPx: row.widthPx,
            heightPx: row.heightPx,
            format: row.format,
            renderVersion: row.renderVersion,
            createdAtUtc: row.createdAt.toUtc(),
          );
  });

  /// The session, which must be in one of [allowed].
  Future<SessionRecord> _require(
    String sessionId,
    Set<SessionStatus> allowed,
  ) async {
    final session = await find(sessionId);
    if (session == null) {
      throw const SessionStoreException('SESSION_UNKNOWN');
    }
    if (!allowed.contains(session.status)) {
      throw const SessionStoreException('SESSION_WRONG_STATUS');
    }
    return session;
  }

  Future<SessionRecord> _record(CaptureSessionRow row) async {
    final photos =
        await (_db.select(_db.sessionPhotos)
              ..where((p) => p.sessionId.equals(row.id))
              ..orderBy([
                (p) => OrderingTerm.asc(p.capturedAt),
                (p) => OrderingTerm.asc(p.attempt),
                (p) => OrderingTerm.asc(p.shotIndex),
              ]))
            .get();
    final SessionPlan plan;
    try {
      plan = SessionPlan.fromJson(
        jsonDecode(row.planJson) as Map<String, Object?>,
      );
    } on Object {
      throw const SessionStoreException('SESSION_PLAN_UNREADABLE');
    }
    return SessionRecord(
      id: row.id,
      plan: plan,
      status: row.status,
      photos: [
        for (final photo in photos)
          ShotPhoto(
            shot: photo.shotIndex,
            attempt: photo.attempt,
            round: photo.round,
            originalId: photo.originalId,
            capturedAtUtc: photo.capturedAt.toUtc(),
          ),
      ],
      startedAtUtc: row.startedAt.toUtc(),
      updatedAtUtc: row.updatedAt.toUtc(),
      endedAtUtc: row.endedAt?.toUtc(),
      endReason: row.endReason,
      outputId: row.outputId,
      renderAttempts: row.renderAttempts,
    );
  }

  Future<void> _setStatus(String sessionId, SessionStatus status) =>
      (_db.update(
        _db.captureSessions,
      )..where((s) => s.id.equals(sessionId))).write(
        CaptureSessionsCompanion(
          status: Value(status),
          updatedAt: Value(_clock.now()),
        ),
      );

  Future<void> _touch(String sessionId) =>
      (_db.update(_db.captureSessions)..where((s) => s.id.equals(sessionId)))
          .write(CaptureSessionsCompanion(updatedAt: Value(_clock.now())));

  /// Schema rule failures become [SessionStoreException]s; the session's
  /// own exceptions pass through.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await guardPersistence(action);
    } on PersistenceRuleException {
      throw const SessionStoreException('SESSION_RULE_REFUSED');
    }
  }
}
