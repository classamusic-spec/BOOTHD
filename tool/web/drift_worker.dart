// The browser's database worker (ADR-0018): compiled to web/drift_worker.js
// by tool/web/build_web_assets.sh from the pinned drift version.
import 'package:drift/wasm.dart';

void main() => WasmDatabase.workerMainForOpen();
