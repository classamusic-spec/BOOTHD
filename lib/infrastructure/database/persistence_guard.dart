import 'package:drift/isolate.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../domain/repositories/storage_errors.dart';

/// SQLite's primary result code for constraint, foreign key and trigger
/// (`RAISE(ABORT)`) failures.
const _sqliteConstraint = 19;

/// Runs [action], turning a schema rule failure into
/// [PersistenceRuleException]. SQLite's message names the rule, never the
/// stored values, so it is safe to keep in diagnostics.
Future<T> guardPersistence<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on SqliteException catch (error) {
    final rule = _translate(error);
    if (rule != null) throw rule;
    rethrow;
  } on DriftRemoteException catch (error) {
    final cause = error.remoteCause;
    final rule = cause is SqliteException ? _translate(cause) : null;
    if (rule != null) throw rule;
    rethrow;
  }
}

PersistenceRuleException? _translate(SqliteException error) =>
    error.resultCode == _sqliteConstraint
    ? PersistenceRuleException(error.message)
    : null;
