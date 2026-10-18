import 'package:drift/drift.dart';

import '../../domain/repositories/operator_access_repository.dart';
import 'booth_database.dart';
import 'persistence_guard.dart';

/// The operator access row: recovery verifier and failed-attempt counters.
final class DriftOperatorAccessRepository implements OperatorAccessRepository {
  DriftOperatorAccessRepository(this._db);

  final BoothDatabase _db;

  @override
  Future<OperatorAccessRecord> read() async {
    final row = await _db.select(_db.operatorAccess).getSingle();
    return OperatorAccessRecord(
      recoveryVerifier: row.recoveryVerifier,
      pinAttempts: AttemptHistory(
        failures: row.pinFailures,
        lastFailureAt: row.pinLastFailureAt,
      ),
      recoveryAttempts: AttemptHistory(
        failures: row.recoveryFailures,
        lastFailureAt: row.recoveryLastFailureAt,
      ),
    );
  }

  @override
  Future<void> write(OperatorAccessRecord record) => guardPersistence(
    () => _db
        .update(_db.operatorAccess)
        .write(
          OperatorAccessCompanion(
            recoveryVerifier: Value(record.recoveryVerifier),
            pinFailures: Value(record.pinAttempts.failures),
            pinLastFailureAt: Value(record.pinAttempts.lastFailureAt),
            recoveryFailures: Value(record.recoveryAttempts.failures),
            recoveryLastFailureAt: Value(record.recoveryAttempts.lastFailureAt),
          ),
        ),
  );
}
