import 'package:meta/meta.dart';

import 'guest_flow.dart';

/// What a countdown presenter shows (EP03): read from the guest flow,
/// which the session controller moves on with monotonic timers. Presenters
/// only draw it; nothing they do (a dropped frame, a failed animation, a
/// missing sound) can move a capture.
@immutable
final class CountdownState {
  const CountdownState({
    required this.remaining,
    required this.total,
    required this.shot,
    required this.shotCount,
  }) : assert(total > 0),
       assert(remaining >= 0 && remaining <= total);

  /// The countdown in [flow], or null when the guest is not in one.
  static CountdownState? of(GuestFlow flow) {
    final shots = flow.shots;
    if (flow.stage != GuestStage.countdown || shots == null) return null;
    final total = shots.plan.capture.countdownSeconds;
    return CountdownState(
      remaining: flow.secondsLeft.clamp(0, total),
      total: total,
      shot: flow.shot!,
      shotCount: shots.plan.shotCount,
    );
  }

  /// Seconds left: the number guests see.
  final int remaining;

  /// Seconds the countdown started from.
  final int total;

  /// The photo being counted down to (0-based) and how many there are.
  final int shot;
  final int shotCount;

  /// How much of the countdown has passed, 0 to 1, in whole seconds.
  double get progress => (total - remaining) / total;

  /// The last second: presenters may show "go" rather than a number.
  bool get isFinal => remaining <= 1;

  @override
  bool operator ==(Object other) =>
      other is CountdownState &&
      other.remaining == remaining &&
      other.total == total &&
      other.shot == shot &&
      other.shotCount == shotCount;

  @override
  int get hashCode => Object.hash(remaining, total, shot, shotCount);

  @override
  String toString() => 'CountdownState($remaining/$total, shot $shot)';
}
