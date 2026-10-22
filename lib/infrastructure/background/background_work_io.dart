import 'dart:isolate';

/// Runs [work] on a short-lived isolate, off the UI isolate.
Future<T> runInBackground<T>(T Function() work) => Isolate.run(work);
