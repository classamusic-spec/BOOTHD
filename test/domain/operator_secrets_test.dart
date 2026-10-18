// AC-0301: PIN rules, recovery codes and the lockout policy.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/repositories/operator_access_repository.dart';
import 'package:porcelain_photo_booth/domain/services/operator_secrets.dart';

void main() {
  group('PIN policy', () {
    test('accepts six digits that are not trivially guessable', () {
      for (final pin in ['482916', '070725', '135792', '908172']) {
        expect(PinPolicy.check(pin), isNull, reason: pin);
      }
    });

    test('refuses anything but exactly six digits', () {
      for (final pin in [
        '',
        '12345',
        '1234567',
        '12345a',
        ' 48291',
        '４８２９１６',
      ]) {
        expect(PinPolicy.check(pin), PinProblem.wrongFormat, reason: pin);
      }
    });

    test('refuses repeats, straight runs and common patterns', () {
      for (final pin in [
        '000000',
        '999999',
        '123456',
        '234567',
        '987654',
        '654321',
        '121212',
        '112233',
        '123123',
      ]) {
        expect(PinPolicy.check(pin), PinProblem.tooGuessable, reason: pin);
      }
    });
  });

  group('recovery codes', () {
    test('are 16 alphabet characters in four groups', () {
      final code = RecoveryCodes.generate(Random(1));
      expect(
        code,
        matches(RegExp(r'^[0-9A-HJKMNP-TV-Z]{4}(-[0-9A-HJKMNP-TV-Z]{4}){3}$')),
      );
    });

    test('differ every time from a secure source', () {
      final codes = {for (var i = 0; i < 50; i++) RecoveryCodes.generate()};
      expect(codes, hasLength(50));
    });

    test('are read forgivingly: case, separators and look-alikes', () {
      expect(
        RecoveryCodes.normalise('k7qm-2xrd 9bwe-h4tc'),
        'K7QM2XRD9BWEH4TC',
      );
      expect(
        RecoveryCodes.normalise('O1IL-0000-0000-0000'),
        '0111000000000000',
      );
      expect(
        RecoveryCodes.normalise('K7QM-2XRD-9BWE'),
        isNull,
        reason: 'short',
      );
      expect(
        RecoveryCodes.normalise('K7QM-2XRD-9BWE-H4TU'),
        isNull,
        reason: 'U is not in the alphabet',
      );
    });
  });

  group('attempt policy', () {
    const policy = AttemptPolicy.pin;
    final start = DateTime.utc(2026, 10, 18, 12);

    AttemptHistory failures(int count, [DateTime? at]) =>
        AttemptHistory(failures: count, lastFailureAt: at ?? start);

    test('five free attempts, then growing lockouts that cap at an hour', () {
      expect(policy.lockoutAfter(4), Duration.zero);
      expect(policy.lockoutAfter(5), const Duration(seconds: 30));
      expect(policy.lockoutAfter(6), const Duration(minutes: 1));
      expect(policy.lockoutAfter(7), const Duration(minutes: 5));
      expect(policy.lockoutAfter(10), const Duration(hours: 1));
      expect(policy.lockoutAfter(50), const Duration(hours: 1));
      expect(policy.attemptsBeforeLockout(failures(3)), 2);
      expect(policy.attemptsBeforeLockout(failures(7)), 0);
    });

    test('the lockout counts down from the last failure', () {
      final history = failures(6);
      expect(
        policy.remainingLockout(history, start),
        const Duration(minutes: 1),
      );
      expect(
        policy.remainingLockout(
          history,
          start.add(const Duration(seconds: 45)),
        ),
        const Duration(seconds: 15),
      );
      expect(
        policy.remainingLockout(history, start.add(const Duration(minutes: 2))),
        Duration.zero,
      );
    });

    test(
      'turning the clock back restarts the lockout instead of ending it',
      () {
        final history = failures(8);
        expect(
          policy.remainingLockout(
            history,
            start.subtract(const Duration(days: 1)),
          ),
          const Duration(minutes: 15),
        );
      },
    );

    test('recovery codes allow fewer attempts', () {
      expect(AttemptPolicy.recovery.lockoutAfter(2), Duration.zero);
      expect(
        AttemptPolicy.recovery.lockoutAfter(3),
        const Duration(minutes: 1),
      );
    });
  });
}
