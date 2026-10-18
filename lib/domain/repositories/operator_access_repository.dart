import 'package:meta/meta.dart';

/// Failed attempts at one secret (PIN or recovery code) since the last
/// success.
@immutable
final class AttemptHistory {
  const AttemptHistory({this.failures = 0, this.lastFailureAt});

  static const none = AttemptHistory();

  final int failures;
  final DateTime? lastFailureAt;

  AttemptHistory failedAt(DateTime moment) =>
      AttemptHistory(failures: failures + 1, lastFailureAt: moment);

  @override
  bool operator ==(Object other) =>
      other is AttemptHistory &&
      other.failures == failures &&
      other.lastFailureAt == lastFailureAt;

  @override
  int get hashCode => Object.hash(failures, lastFailureAt);
}

/// Operator access state kept in the app database: the recovery code's
/// verifier (a slow hash of an 80-bit code, safe at rest) and the failed
/// attempt counters that drive lockouts (A-12, ADR-0009).
@immutable
final class OperatorAccessRecord {
  const OperatorAccessRecord({
    this.recoveryVerifier,
    this.pinAttempts = AttemptHistory.none,
    this.recoveryAttempts = AttemptHistory.none,
  });

  final String? recoveryVerifier;
  final AttemptHistory pinAttempts;
  final AttemptHistory recoveryAttempts;

  OperatorAccessRecord copyWith({
    String? recoveryVerifier,
    AttemptHistory? pinAttempts,
    AttemptHistory? recoveryAttempts,
  }) => OperatorAccessRecord(
    recoveryVerifier: recoveryVerifier ?? this.recoveryVerifier,
    pinAttempts: pinAttempts ?? this.pinAttempts,
    recoveryAttempts: recoveryAttempts ?? this.recoveryAttempts,
  );

  @override
  bool operator ==(Object other) =>
      other is OperatorAccessRecord &&
      other.recoveryVerifier == recoveryVerifier &&
      other.pinAttempts == pinAttempts &&
      other.recoveryAttempts == recoveryAttempts;

  @override
  int get hashCode =>
      Object.hash(recoveryVerifier, pinAttempts, recoveryAttempts);
}

abstract interface class OperatorAccessRepository {
  Future<OperatorAccessRecord> read();

  Future<void> write(OperatorAccessRecord record);
}

/// The operator PIN's verifier, kept in platform secure storage (Keychain
/// on iPadOS, Keystore-protected storage on Android), never in the
/// database or in backups (A-12).
abstract interface class PinVerifierStore {
  /// The stored verifier, or null if none is stored. Throws
  /// [SecretStoreException] when the platform store cannot be read.
  Future<String?> read();

  Future<void> write(String verifier);

  Future<void> delete();
}

/// The platform's secure storage failed. The message never contains the
/// secret or verifier.
final class SecretStoreException implements Exception {
  const SecretStoreException(this.message);

  final String message;

  @override
  String toString() => 'SecretStoreException($message)';
}
