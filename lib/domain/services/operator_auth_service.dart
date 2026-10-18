import 'dart:async';

import 'package:meta/meta.dart';

import '../repositories/operator_access_repository.dart';
import '../value_objects/clock.dart';
import 'operator_secrets.dart';

/// Proof that the operator just entered the PIN or a recovery code. Needed
/// to change the PIN or the recovery code; valid for a few minutes and only
/// with the service that issued it.
final class OperatorProof {
  OperatorProof._(this._issuer, this.issuedAt);

  final OperatorAuthService _issuer;
  final DateTime issuedAt;
}

/// The result of checking a PIN or recovery code.
@immutable
sealed class AccessCheck {
  const AccessCheck();
}

final class AccessGranted extends AccessCheck {
  const AccessGranted(this.proof);

  final OperatorProof proof;
}

/// Wrong secret. [lockout] is non-zero when this failure started a lockout.
final class AccessDenied extends AccessCheck {
  const AccessDenied({
    required this.attemptsBeforeLockout,
    required this.lockout,
  });

  final int attemptsBeforeLockout;
  final Duration lockout;
}

/// Too many failures; nothing was checked.
final class AccessLockedOut extends AccessCheck {
  const AccessLockedOut(this.retryAfter);

  final Duration retryAfter;
}

/// Why the stored PIN cannot be used.
enum CredentialProblem {
  /// No verifier is stored (for example after the platform's secure
  /// storage was reset).
  missing,

  /// The platform's secure storage failed to read it.
  unreadable,
}

/// The PIN (or recovery code) cannot be checked on this device; the
/// operator needs the recovery code (or, failing that, the reset described
/// in the operator manual).
final class CredentialUnavailable extends AccessCheck {
  const CredentialUnavailable(this.problem);

  final CredentialProblem problem;
}

/// A refused new PIN.
final class PinRejectedException implements Exception {
  const PinRejectedException(this.problem);

  final PinProblem problem;

  @override
  String toString() => 'PinRejectedException(${problem.name})';
}

/// An [OperatorProof] that is expired or from another service.
final class ProofRejectedException implements Exception {
  const ProofRejectedException();

  @override
  String toString() => 'ProofRejectedException';
}

/// Created at first-run setup: the PIN verifier is already stored; the
/// caller stores [recoveryVerifier] with the rest of the setup and shows
/// [recoveryCode] once.
@immutable
final class SetupCredentials {
  const SetupCredentials({
    required this.recoveryCode,
    required this.recoveryVerifier,
  });

  final String recoveryCode;
  final String recoveryVerifier;
}

/// What the unlock screen shows before anyone types.
@immutable
final class PinStatus {
  const PinStatus({
    required this.available,
    required this.retryAfter,
    required this.attemptsBeforeLockout,
  });

  /// A stored PIN can be checked on this device.
  final bool available;
  final Duration retryAfter;
  final int attemptsBeforeLockout;
}

/// Operator PIN and recovery code checks (A-04 OperatorAuthService, P-14,
/// AC-0301).
///
/// * The PIN's slow, salted verifier is kept in platform secure storage;
///   neither the PIN nor the recovery code is ever stored or logged.
/// * Failed attempts are counted in the app database and lock entry for
///   growing periods ([AttemptPolicy]); a success clears them.
/// * Checks run one at a time, so rapid repeated submissions cannot race
///   the failure counter.
final class OperatorAuthService {
  OperatorAuthService({
    required this._pins,
    required this._access,
    required this._hasher,
    required this._clock,
    String Function()? newRecoveryCode,
    this.pinPolicy = AttemptPolicy.pin,
    this.recoveryPolicy = AttemptPolicy.recovery,
  }) : _newRecoveryCode = newRecoveryCode ?? RecoveryCodes.generate;

  static const proofLifetime = Duration(minutes: 5);

  final PinVerifierStore _pins;
  final OperatorAccessRepository _access;
  final PinHasher _hasher;
  final Clock _clock;
  final String Function() _newRecoveryCode;
  final AttemptPolicy pinPolicy;
  final AttemptPolicy recoveryPolicy;

  Future<void> _queue = Future.value();

  /// Runs [action] after every earlier call has finished.
  Future<T> _serialised<T>(Future<T> Function() action) {
    final result = _queue.then((_) => action());
    _queue = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  /// First-run setup: checks [pin] against [PinPolicy], stores its verifier
  /// and creates a recovery code. Throws [PinRejectedException].
  Future<SetupCredentials> setUp(String pin) => _serialised(() async {
    _requireAcceptable(pin);
    await _pins.write(await _hasher.hash(pin));
    final code = _newRecoveryCode();
    return SetupCredentials(
      recoveryCode: code,
      recoveryVerifier: await _hasher.hash(RecoveryCodes.normalise(code)!),
    );
  });

  /// Lockout and availability, for the unlock screen.
  Future<PinStatus> pinStatus() => _serialised(() async {
    final record = await _access.read();
    final available = await _pinVerifier() is String;
    return PinStatus(
      available: available,
      retryAfter: pinPolicy.remainingLockout(record.pinAttempts, _clock.now()),
      attemptsBeforeLockout: pinPolicy.attemptsBeforeLockout(
        record.pinAttempts,
      ),
    );
  });

  /// Whether a recovery code is stored.
  Future<bool> hasRecoveryCode() =>
      _serialised(() async => (await _access.read()).recoveryVerifier != null);

  Future<AccessCheck> verifyPin(String pin) => _serialised(() async {
    final record = await _access.read();
    final now = _clock.now();
    final wait = pinPolicy.remainingLockout(record.pinAttempts, now);
    if (wait > Duration.zero) return AccessLockedOut(wait);

    final verifier = await _pinVerifier();
    if (verifier is CredentialProblem) return CredentialUnavailable(verifier);
    verifier as String;

    if (!await _hasher.verify(pin, verifier)) {
      final attempts = record.pinAttempts.failedAt(now);
      await _access.write(record.copyWith(pinAttempts: attempts));
      return AccessDenied(
        attemptsBeforeLockout: pinPolicy.attemptsBeforeLockout(attempts),
        lockout: pinPolicy.lockoutAfter(attempts.failures),
      );
    }
    if (record.pinAttempts != AttemptHistory.none) {
      await _access.write(record.copyWith(pinAttempts: AttemptHistory.none));
    }
    if (_hasher.needsRehash(verifier)) {
      await _pins.write(await _hasher.hash(pin));
    }
    return AccessGranted(OperatorProof._(this, now));
  });

  /// Checks a recovery code as typed (separators and case don't matter).
  Future<AccessCheck> verifyRecoveryCode(String typed) => _serialised(() async {
    final record = await _access.read();
    final now = _clock.now();
    final wait = recoveryPolicy.remainingLockout(record.recoveryAttempts, now);
    if (wait > Duration.zero) return AccessLockedOut(wait);

    final verifier = record.recoveryVerifier;
    if (verifier == null) {
      return const CredentialUnavailable(CredentialProblem.missing);
    }
    final code = RecoveryCodes.normalise(typed);
    if (code == null || !await _hasher.verify(code, verifier)) {
      final attempts = record.recoveryAttempts.failedAt(now);
      await _access.write(record.copyWith(recoveryAttempts: attempts));
      return AccessDenied(
        attemptsBeforeLockout: recoveryPolicy.attemptsBeforeLockout(attempts),
        lockout: recoveryPolicy.lockoutAfter(attempts.failures),
      );
    }
    await _access.write(
      record.copyWith(
        recoveryAttempts: AttemptHistory.none,
        pinAttempts: AttemptHistory.none,
      ),
    );
    return AccessGranted(OperatorProof._(this, now));
  });

  /// Replaces the PIN. Throws [ProofRejectedException] or
  /// [PinRejectedException].
  Future<void> replacePin(OperatorProof proof, String newPin) => _serialised(
    () async {
      _requireFresh(proof);
      _requireAcceptable(newPin);
      await _pins.write(await _hasher.hash(newPin));
      final record = await _access.read();
      if (record.pinAttempts != AttemptHistory.none) {
        await _access.write(record.copyWith(pinAttempts: AttemptHistory.none));
      }
    },
  );

  /// Replaces the recovery code, invalidating the old one, and returns the
  /// new code for display. Throws [ProofRejectedException].
  Future<String> replaceRecoveryCode(OperatorProof proof) =>
      _serialised(() async {
        _requireFresh(proof);
        final code = _newRecoveryCode();
        final verifier = await _hasher.hash(RecoveryCodes.normalise(code)!);
        final record = await _access.read();
        await _access.write(
          record.copyWith(
            recoveryVerifier: verifier,
            recoveryAttempts: AttemptHistory.none,
          ),
        );
        return code;
      });

  /// Whether [proof] was issued by this service and is still fresh.
  bool accepts(OperatorProof proof) {
    final age = _clock.now().difference(proof.issuedAt);
    return identical(proof._issuer, this) &&
        !age.isNegative &&
        age <= proofLifetime;
  }

  void _requireAcceptable(String pin) {
    final problem = PinPolicy.check(pin);
    if (problem != null) throw PinRejectedException(problem);
  }

  void _requireFresh(OperatorProof proof) {
    if (!accepts(proof)) throw const ProofRejectedException();
  }

  /// The stored verifier, or the problem reading it.
  Future<Object> _pinVerifier() async {
    try {
      return await _pins.read() ?? CredentialProblem.missing;
    } on SecretStoreException {
      return CredentialProblem.unreadable;
    }
  }
}
