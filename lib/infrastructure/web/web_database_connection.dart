import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../core/diagnostics/safe_log.dart';

/// The booth database in the browser (ADR-0018): the same schema in
/// WebAssembly SQLite, kept in the browser's private file system where it
/// can, in IndexedDB otherwise. `web/sqlite3.wasm` and
/// `web/drift_worker.js` are built by `tool/web/build_web_assets.sh`.
/// Connection settings come from the schema's `beforeOpen` (foreign keys);
/// the browser's storage takes care of durability.
QueryExecutor openBrowserBoothDatabase() => driftDatabase(
  name: 'porcelain_booth',
  web: DriftWebOptions(
    sqlite3Wasm: Uri.parse('sqlite3.wasm'),
    driftWorker: Uri.parse('drift_worker.js'),
    onResult: (result) => SafeLog.event(
      'web database',
      '${result.chosenImplementation.name}'
          '${result.missingFeatures.isEmpty ? '' : ' (missing ${result.missingFeatures.map((f) => f.name).join(', ')})'}',
    ),
  ),
);
