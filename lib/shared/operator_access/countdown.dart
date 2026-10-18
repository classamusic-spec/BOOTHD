import 'dart:async';

import 'package:flutter/foundation.dart';

/// A seconds countdown for lockout messages. Display only: the service
/// decides when entry is allowed again, so a countdown that drifts can
/// never let anyone in early.
final class Countdown {
  Countdown(this._onTick);

  final VoidCallback _onTick;
  Timer? _timer;
  Duration _remaining = Duration.zero;

  Duration get remaining => _remaining;
  bool get running => _remaining > Duration.zero;

  void start(Duration wait) {
    _timer?.cancel();
    _remaining = wait;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _remaining -= const Duration(seconds: 1);
      if (_remaining <= Duration.zero) {
        _remaining = Duration.zero;
        _timer?.cancel();
      }
      _onTick();
    });
  }

  void dispose() => _timer?.cancel();
}
