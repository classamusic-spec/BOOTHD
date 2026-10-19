import 'dart:async';

import 'package:flutter/widgets.dart';

import 'delivery_service.dart';

/// Drives the delivery queue while the app is in front (PD-05): a pass at
/// start and on every return to the foreground, then one whenever the
/// queue has work due, and a readiness check every ten minutes while
/// paired. Nothing runs while the app is in the background: neither iPadOS
/// nor Android lets the booth send reliably from there, and it does not
/// claim to.
final class DeliveryRunner {
  DeliveryRunner(
    this._service, {
    this.checkEvery = const Duration(minutes: 10),
  });

  final DeliveryService _service;
  final Duration checkEvery;

  AppLifecycleListener? _lifecycle;
  Timer? _work;
  Timer? _check;
  var _active = true;
  var _started = false;

  void start() {
    if (_started) return;
    _started = true;
    final state = WidgetsBinding.instance.lifecycleState;
    _active = state == null || state == AppLifecycleState.resumed;
    _lifecycle = AppLifecycleListener(onStateChange: _onState);
    _service.addListener(_schedule);
    unawaited(_checkReadiness());
    unawaited(_kick());
  }

  void _onState(AppLifecycleState state) {
    final active = state == AppLifecycleState.resumed;
    if (active == _active) return;
    _active = active;
    if (active) {
      unawaited(_checkReadiness());
      unawaited(_kick());
    } else {
      _work?.cancel();
      _check?.cancel();
    }
  }

  Future<void> _kick() async {
    if (!_active || !_started) return;
    await _service.processDue();
    await _scheduleNext();
  }

  void _schedule() => unawaited(_scheduleNext());

  Future<void> _scheduleNext() async {
    if (!_active || !_started) return;
    final Duration? wait;
    try {
      wait = await _service.nextWork();
    } on Object {
      return;
    }
    _work?.cancel();
    if (wait == null || !_active) return;
    final delay = wait < const Duration(seconds: 2)
        ? const Duration(seconds: 2)
        : wait;
    _work = Timer(delay, () => unawaited(_kick()));
  }

  Future<void> _checkReadiness() async {
    _check?.cancel();
    if (!_active || !_started) return;
    var paired = true;
    try {
      paired = await _service.check() != null;
    } on Object {
      // Offline or refused: the link state says so; tried again later.
    }
    // Unpaired booths have nothing to check (pairing checks at once).
    if (paired && _active && _started) {
      _check = Timer(checkEvery, () => unawaited(_checkReadiness()));
    }
  }

  /// Checks readiness now and keeps checking (after pairing).
  void checkSoon() => unawaited(_checkReadiness());

  void stop() {
    _started = false;
    _work?.cancel();
    _check?.cancel();
    _lifecycle?.dispose();
    _lifecycle = null;
    _service.removeListener(_schedule);
  }
}
