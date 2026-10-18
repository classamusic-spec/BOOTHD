/// The current time, injected so rules that depend on it (lockouts,
/// timestamps) can be tested with a controlled clock.
abstract interface class Clock {
  /// The current moment, in UTC.
  DateTime now();
}

final class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now().toUtc();
}
