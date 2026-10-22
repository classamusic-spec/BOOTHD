/// The adapters that differ between tablets and the browser test build
/// (ADR-0018), chosen at compile time.
library;

export 'platform_bindings_io.dart'
    if (dart.library.js_interop) 'platform_bindings_web.dart';
