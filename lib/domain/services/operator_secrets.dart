/// Rules for the operator PIN and recovery code, and the lockout policy for
/// failed attempts (P-14, A-12, AC-0301).
library;

import 'dart:math';

import 'package:meta/meta.dart';

import '../repositories/operator_access_repository.dart';

/// Derives and checks slow, salted verifiers for low-entropy secrets.
/// Implementations must not run the derivation on the UI thread.
abstract interface class PinHasher {
  /// A verifier for [secret] with a fresh random salt. The secret itself is
  /// not recoverable from it.
  Future<String> hash(String secret);

  /// Whether [secret] matches [verifier], compared in constant time. False
  /// for a malformed verifier.
  Future<bool> verify(String secret, String verifier);

  /// Whether [verifier] is weaker than the current policy and should be
  /// replaced after the next successful check.
  bool needsRehash(String verifier);
}

/// Why a proposed PIN is refused.
enum PinProblem {
  /// Not exactly [PinPolicy.length] digits.
  wrongFormat,

  /// The same digit repeated, a straight run such as 123456, or a commonly
  /// chosen pattern.
  tooGuessable,
}

/// The operator PIN is exactly six digits and not trivially guessable.
abstract final class PinPolicy {
  static const length = 6;

  static final _digits = RegExp(r'^\d{6}$');

  /// Common six-digit choices beyond repeats and straight runs.
  static const _common = {
    '112233',
    '121212',
    '123123',
    '101010',
    '111222',
    '159753',
    '147258',
    '696969',
    '102030',
    '000111',
  };

  /// The problem with [pin], or null if it is acceptable.
  static PinProblem? check(String pin) {
    if (!_digits.hasMatch(pin)) return PinProblem.wrongFormat;
    final digits = pin.codeUnits.map((unit) => unit - 0x30).toList();
    if (digits.toSet().length == 1) return PinProblem.tooGuessable;
    bool run(int step) {
      for (var i = 1; i < digits.length; i++) {
        if (digits[i] - digits[i - 1] != step) return false;
      }
      return true;
    }

    if (run(1) || run(-1)) return PinProblem.tooGuessable;
    if (_common.contains(pin)) return PinProblem.tooGuessable;
    return null;
  }
}

/// Recovery codes: 16 characters of Crockford base32 (80 random bits),
/// shown once as four groups of four, e.g. `K7QM-2XRD-9BWE-H4TC`.
abstract final class RecoveryCodes {
  static const alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
  static const length = 16;

  /// A new code in display form.
  static String generate([Random? random]) {
    final source = random ?? Random.secure();
    final chars = List.generate(
      length,
      (_) => alphabet[source.nextInt(alphabet.length)],
    ).join();
    return format(chars);
  }

  /// Groups a normalised code for display.
  static String format(String normalised) => [
    for (var i = 0; i < normalised.length; i += 4)
      normalised.substring(i, min(i + 4, normalised.length)),
  ].join('-');

  /// The canonical form of what an operator typed: upper case, separators
  /// removed, and the look-alikes O, I and L read as 0, 1 and 1. Returns
  /// null unless that leaves exactly [length] alphabet characters.
  static String? normalise(String typed) {
    final buffer = StringBuffer();
    for (final char in typed.toUpperCase().split('')) {
      if (char == '-' || char == ' ') continue;
      final mapped = switch (char) {
        'O' => '0',
        'I' || 'L' => '1',
        _ => char,
      };
      if (!alphabet.contains(mapped)) return null;
      buffer.write(mapped);
    }
    final code = buffer.toString();
    return code.length == length ? code : null;
  }
}

/// Lockouts after repeated failures (A-12). The first [freeAttempts]
/// failures cost nothing; each later failure locks entry for the next
/// duration in [lockouts], staying at the last one.
@immutable
final class AttemptPolicy {
  const AttemptPolicy({required this.freeAttempts, required this.lockouts});

  /// Operator PIN: five tries, then 30 s, 1 min, 5 min, 15 min, 30 min and
  /// an hour per further failure.
  static const pin = AttemptPolicy(
    freeAttempts: 5,
    lockouts: [
      Duration(seconds: 30),
      Duration(minutes: 1),
      Duration(minutes: 5),
      Duration(minutes: 15),
      Duration(minutes: 30),
      Duration(hours: 1),
    ],
  );

  /// Recovery code: three tries, then 1 min, 5 min, 15 min and an hour.
  static const recovery = AttemptPolicy(
    freeAttempts: 3,
    lockouts: [
      Duration(minutes: 1),
      Duration(minutes: 5),
      Duration(minutes: 15),
      Duration(hours: 1),
    ],
  );

  final int freeAttempts;
  final List<Duration> lockouts;

  /// The lockout that follows the [failures]th consecutive failure.
  Duration lockoutAfter(int failures) {
    if (failures < freeAttempts) return Duration.zero;
    return lockouts[min(failures - freeAttempts, lockouts.length - 1)];
  }

  /// Failures still allowed before a lockout starts.
  int attemptsBeforeLockout(AttemptHistory history) =>
      max(0, freeAttempts - history.failures);

  /// How long entry stays locked at [now].
  ///
  /// If the clock reads earlier than the last failure (it was turned back),
  /// the full lockout applies from now, so changing the time cannot skip
  /// it.
  Duration remainingLockout(AttemptHistory history, DateTime now) {
    final last = history.lastFailureAt;
    final lockout = lockoutAfter(history.failures);
    if (last == null || lockout == Duration.zero) return Duration.zero;
    if (now.isBefore(last)) return lockout;
    final remaining = last.add(lockout).difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }
}
