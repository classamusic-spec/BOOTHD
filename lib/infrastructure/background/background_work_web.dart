/// Browsers have no isolates for Flutter code (ADR-0018): [work] runs on
/// the page's thread after the current frame, so a short pause is the cost
/// of an encode in the web test build.
Future<T> runInBackground<T>(T Function() work) =>
    Future<void>.delayed(Duration.zero).then((_) => work());
