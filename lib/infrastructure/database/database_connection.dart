import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:sqlite3/common.dart' show CommonDatabase;

/// Opens the booth database file on a background isolate (A-11): WAL
/// journal, full synchronous commits (a committed event survives power
/// loss) and foreign keys enforced.
QueryExecutor openBoothDatabaseFile(Future<File> Function() file) =>
    driftDatabase(
      name: 'porcelain_booth',
      native: DriftNativeOptions(
        databasePath: () async => (await file()).path,
        setup: configureConnection,
      ),
    );

/// The same database on the calling isolate, for tests and tools.
QueryExecutor openBoothDatabaseFileInline(File file) =>
    NativeDatabase(file, setup: configureConnection);

/// A throwaway in-memory database with the same connection settings.
QueryExecutor openBoothDatabaseInMemory() =>
    NativeDatabase.memory(setup: configureConnection);

/// Applied to every new connection, before migrations run.
void configureConnection(CommonDatabase database) {
  database
    ..execute('PRAGMA journal_mode = WAL')
    ..execute('PRAGMA synchronous = FULL')
    ..execute('PRAGMA foreign_keys = ON')
    ..execute('PRAGMA busy_timeout = 5000');
}
