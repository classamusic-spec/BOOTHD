import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/operator_auth_service.dart';
import '../booth/booth_providers.dart';
import '../di/service_providers.dart';

/// Who may use the app right now (UX-04). The router lets each phase reach
/// only its own routes (`accessRedirect`).
enum AccessPhase {
  /// Storage is opening.
  starting,

  /// Storage could not be opened; see [AccessState.failure].
  startupFailed,

  /// First-run setup has not finished (S01).
  setup,

  /// The Studio needs the operator PIN.
  locked,

  /// The operator is using the Studio.
  operator,

  /// Booth Mode: guests only, until the operator exits with the PIN.
  booth,
}

@immutable
final class AccessState {
  const AccessState(this.phase, {this.boothEventId, this.failure});

  final AccessPhase phase;

  /// The event Booth Mode runs, in [AccessPhase.booth].
  final String? boothEventId;

  /// Why startup failed, in [AccessPhase.startupFailed].
  final Object? failure;

  @override
  bool operator ==(Object other) =>
      other is AccessState &&
      other.phase == phase &&
      other.boothEventId == boothEventId &&
      other.failure == failure;

  @override
  int get hashCode => Object.hash(phase, boothEventId, failure);
}

/// The operator is not allowed to do this without a fresh PIN check.
final class AccessDeniedError extends StateError {
  AccessDeniedError(super.message);
}

/// Tracks the access phase. A cold start always lands on setup, the PIN
/// screen or (if the booth was running) Booth Mode, never straight in the
/// Studio. Leaving the lock or Booth Mode needs an [OperatorProof].
final class AccessController extends Notifier<AccessState> {
  @override
  AccessState build() {
    final startup = ref.watch(startupProvider);
    return switch (startup) {
      AsyncData(value: final booth) when !booth.setupComplete =>
        const AccessState(AccessPhase.setup),
      AsyncData(value: final booth) when booth.boothEventId != null =>
        AccessState(AccessPhase.booth, boothEventId: booth.boothEventId),
      AsyncData() => const AccessState(AccessPhase.locked),
      AsyncError(:final error) => AccessState(
        AccessPhase.startupFailed,
        failure: error,
      ),
      _ => const AccessState(AccessPhase.starting),
    };
  }

  /// Setup finished: the operator who just chose the PIN is signed in.
  void completeSetup() {
    _require(AccessPhase.setup);
    state = const AccessState(AccessPhase.operator);
  }

  /// Opens the Studio after a successful PIN or recovery check.
  void unlock(OperatorProof proof) {
    _require(AccessPhase.locked);
    _requireProof(proof);
    state = const AccessState(AccessPhase.operator);
  }

  /// Locks the Studio; the PIN is needed again.
  void lock() {
    if (state.phase == AccessPhase.operator) {
      state = const AccessState(AccessPhase.locked);
    }
  }

  /// Starts Booth Mode for [eventId]. Stored first, so a restart returns to
  /// the booth.
  Future<void> startBooth(String eventId) async {
    _require(AccessPhase.operator);
    await ref.read(boothSettingsRepositoryProvider).setBoothEvent(eventId);
    state = AccessState(AccessPhase.booth, boothEventId: eventId);
  }

  /// Ends Booth Mode after the operator's PIN check (S28) and opens the
  /// Studio.
  Future<void> exitBooth(OperatorProof proof) async {
    _require(AccessPhase.booth);
    _requireProof(proof);
    await ref.read(boothSettingsRepositoryProvider).setBoothEvent(null);
    state = const AccessState(AccessPhase.operator);
  }

  /// Tries to open storage again after a startup failure.
  void retryStartup() => ref.invalidate(startupProvider);

  void _require(AccessPhase phase) {
    if (state.phase != phase) {
      throw AccessDeniedError('Not allowed in ${state.phase.name}');
    }
  }

  void _requireProof(OperatorProof proof) {
    if (!ref.read(operatorAuthServiceProvider).accepts(proof)) {
      throw AccessDeniedError('Operator proof rejected');
    }
  }
}

final accessControllerProvider =
    NotifierProvider<AccessController, AccessState>(AccessController.new);
