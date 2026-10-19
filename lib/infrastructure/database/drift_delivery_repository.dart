import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/delivery/delivery_intent.dart';
import '../../domain/repositories/delivery_repository.dart';
import '../../domain/services/delivery_api.dart';
import 'booth_database.dart';
import 'persistence_guard.dart';

/// The delivery queue, the booth's pairing and the revocation journal in
/// the booth database (schema version 7).
final class DriftDeliveryRepository implements DeliveryRepository {
  DriftDeliveryRepository(this._db);

  final BoothDatabase _db;

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await guardPersistence(action);
    } on Object catch (error) {
      if (error is DeliveryStoreException) rethrow;
      throw const DeliveryStoreException('DELIVERY_STORE_FAILED');
    }
  }

  @override
  Future<void> add(DeliveryIntent intent) =>
      _guard(() => _db.into(_db.deliveryIntents).insert(_toRow(intent)));

  @override
  Future<DeliveryIntent?> find(String id) => _guard(() async {
    final row = await (_db.select(
      _db.deliveryIntents,
    )..where((i) => i.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  });

  @override
  Future<void> update(DeliveryIntent intent) => _guard(() async {
    final updated = await (_db.update(
      _db.deliveryIntents,
    )..where((i) => i.id.equals(intent.id))).write(_toRow(intent));
    if (updated == 0) throw const DeliveryStoreException('DELIVERY_NOT_FOUND');
  });

  @override
  Future<List<DeliveryIntent>> open() => _guard(() async {
    final rows =
        await (_db.select(_db.deliveryIntents)
              ..where(
                (i) => i.state.equalsValue(DeliveryIntentState.finished).not(),
              )
              ..orderBy([(i) => OrderingTerm.asc(i.createdAt)]))
            .get();
    return rows.map(_toDomain).toList();
  });

  Selectable<DeliveryIntentRow> _session(String sessionId) =>
      _db.select(_db.deliveryIntents)
        ..where((i) => i.sessionId.equals(sessionId))
        ..orderBy([(i) => OrderingTerm.asc(i.createdAt)]);

  @override
  Future<List<DeliveryIntent>> forSession(String sessionId) => _guard(
    () async => (await _session(sessionId).get()).map(_toDomain).toList(),
  );

  @override
  Stream<List<DeliveryIntent>> watchSession(String sessionId) =>
      _session(sessionId).watch().map((rows) => rows.map(_toDomain).toList());

  @override
  Stream<List<DeliveryIntent>> watchRecent({String? eventId, int limit = 50}) {
    final query = _db.select(_db.deliveryIntents)
      ..orderBy([(i) => OrderingTerm.desc(i.createdAt)])
      ..limit(limit);
    if (eventId != null) query.where((i) => i.eventId.equals(eventId));
    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<DeliveryCounts> counts({String? eventId}) => _guard(() async {
    final query = _db.select(_db.deliveryIntents);
    if (eventId != null) query.where((i) => i.eventId.equals(eventId));
    final byPhase = <DeliveryPhase, int>{};
    for (final row in await query.get()) {
      final phase = _toDomain(row).phase;
      byPhase[phase] = (byPhase[phase] ?? 0) + 1;
    }
    return DeliveryCounts(byPhase);
  });

  @override
  Future<int> requestedForEvent(String eventId) => _guard(() async {
    final rows = await (_db.select(
      _db.deliveryIntents,
    )..where((i) => i.eventId.equals(eventId))).get();
    return rows.map(_toDomain).where((intent) {
      final phase = intent.phase;
      return phase != DeliveryPhase.canceled &&
          phase != DeliveryPhase.expired &&
          !(phase == DeliveryPhase.failed && intent.remoteJobId == null);
    }).length;
  });

  @override
  Future<DeliveryPairing?> pairing() => _guard(() async {
    final row = await _db.select(_db.deliveryPairings).getSingleOrNull();
    return row == null ? null : _pairing(row);
  });

  @override
  Stream<DeliveryPairing?> watchPairing() => _db
      .select(_db.deliveryPairings)
      .watchSingleOrNull()
      .map((row) => row == null ? null : _pairing(row));

  @override
  Future<void> savePairing(DeliveryPairing? pairing) => _guard(() async {
    if (pairing == null) {
      await _db.delete(_db.deliveryPairings).go();
      return;
    }
    await _db
        .into(_db.deliveryPairings)
        .insertOnConflictUpdate(
          DeliveryPairingsCompanion.insert(
            id: const Value(1),
            baseUrl: pairing.baseUrl.toString(),
            boothId: pairing.boothId,
            boothName: pairing.boothName,
            brandName: pairing.brandName,
            pairedAt: pairing.pairedAtUtc,
            paused: Value(pairing.paused),
            capabilitiesJson: Value(
              pairing.capabilities == null
                  ? null
                  : jsonEncode(pairing.capabilities!.toJson()),
            ),
            checkedAt: Value(pairing.checkedAtUtc),
          ),
        );
  });

  @override
  Future<List<String>> pendingRevocations() => _guard(() async {
    final rows = await (_db.select(
      _db.deliveryRemoteRevocations,
    )..orderBy([(r) => OrderingTerm.asc(r.requestedAt)])).get();
    return [for (final row in rows) row.remoteJobId];
  });

  @override
  Future<void> revocationDone(String remoteJobId) => _guard(
    () => (_db.delete(
      _db.deliveryRemoteRevocations,
    )..where((r) => r.remoteJobId.equals(remoteJobId))).go(),
  );

  static DeliveryPairing _pairing(DeliveryPairingRow row) {
    DeliveryCapabilities? capabilities;
    final json = row.capabilitiesJson;
    if (json != null) {
      try {
        final decoded = jsonDecode(json);
        if (decoded is Map<String, Object?>) {
          capabilities = DeliveryCapabilities.fromJson(decoded);
        }
      } on FormatException {
        capabilities = null;
      }
    }
    return DeliveryPairing(
      baseUrl: Uri.parse(row.baseUrl),
      boothId: row.boothId,
      boothName: row.boothName,
      brandName: row.brandName,
      pairedAtUtc: row.pairedAt.toUtc(),
      paused: row.paused,
      capabilities: capabilities,
      checkedAtUtc: row.checkedAt?.toUtc(),
    );
  }

  static DeliveryIntentsCompanion _toRow(DeliveryIntent intent) =>
      DeliveryIntentsCompanion.insert(
        id: intent.id,
        sessionId: intent.sessionId,
        eventId: intent.eventId,
        outputId: intent.outputId,
        phoneLast4: intent.phoneLast4,
        phoneStored: intent.phoneStored,
        consentTextVersion: intent.consentTextVersion,
        consentTextDigest: intent.consentTextDigest,
        consentAcceptedAt: intent.consentAcceptedAtUtc,
        locale: intent.locale,
        linkDays: intent.linkDays,
        sendLimit: intent.sendLimit,
        queueAllowed: intent.queueAllowed,
        idempotencyKey: intent.idempotencyKey,
        state: intent.state,
        localOutcome: Value(intent.localOutcome),
        remoteJobId: Value(intent.remoteJobId),
        remoteStatus: Value(intent.remoteStatus?.name),
        remoteUpdatedAt: Value(intent.remoteUpdatedAtUtc),
        lastErrorCode: Value(intent.lastErrorCode),
        attemptCount: Value(intent.attemptCount),
        retryAt: Value(intent.retryAtUtc),
        expiresAt: intent.expiresAtUtc,
        historyJson: Value(
          jsonEncode([for (final step in intent.history) step.toJson()]),
        ),
        createdAt: intent.createdAtUtc,
        updatedAt: intent.updatedAtUtc,
      );

  static DeliveryIntent _toDomain(DeliveryIntentRow row) {
    List<DeliveryStep> history;
    try {
      final decoded = jsonDecode(row.historyJson);
      history = [
        if (decoded is List)
          for (final entry in decoded) ?DeliveryStep.fromJson(entry),
      ];
    } on FormatException {
      history = const [];
    }
    return DeliveryIntent(
      id: row.id,
      sessionId: row.sessionId,
      eventId: row.eventId,
      outputId: row.outputId,
      phoneLast4: row.phoneLast4,
      phoneStored: row.phoneStored,
      consentTextVersion: row.consentTextVersion,
      consentTextDigest: row.consentTextDigest,
      consentAcceptedAtUtc: row.consentAcceptedAt.toUtc(),
      locale: row.locale,
      linkDays: row.linkDays,
      sendLimit: row.sendLimit,
      queueAllowed: row.queueAllowed,
      idempotencyKey: row.idempotencyKey,
      state: row.state,
      localOutcome: row.localOutcome,
      remoteJobId: row.remoteJobId,
      remoteStatus: RemoteDeliveryStatus.fromName(row.remoteStatus),
      remoteUpdatedAtUtc: row.remoteUpdatedAt?.toUtc(),
      lastErrorCode: row.lastErrorCode,
      attemptCount: row.attemptCount,
      retryAtUtc: row.retryAt?.toUtc(),
      expiresAtUtc: row.expiresAt.toUtc(),
      createdAtUtc: row.createdAt.toUtc(),
      updatedAtUtc: row.updatedAt.toUtc(),
      history: List.unmodifiable(history),
    );
  }
}
