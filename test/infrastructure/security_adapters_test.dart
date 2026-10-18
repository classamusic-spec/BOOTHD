// AC-0301: the PIN verifier's key derivation and its secure storage.
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/repositories/operator_access_repository.dart';
import 'package:porcelain_photo_booth/infrastructure/security/pbkdf2.dart';
import 'package:porcelain_photo_booth/infrastructure/security/pbkdf2_pin_hasher.dart';
import 'package:porcelain_photo_booth/infrastructure/security/secure_pin_verifier_store.dart';

String hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

void main() {
  group('PBKDF2-HMAC-SHA256', () {
    test('matches the RFC 7914 test vectors', () {
      expect(
        hex(
          pbkdf2HmacSha256(
            password: utf8.encode('passwd'),
            salt: utf8.encode('salt'),
            iterations: 1,
            length: 64,
          ),
        ),
        '55ac046e56e3089fec1691c22544b605f94185216dde0465e68b9d57c20dacbc'
        '49ca9cccf179b645991664b39d77ef317c71b845b1e30bd509112041d3a19783',
      );
      expect(
        hex(
          pbkdf2HmacSha256(
            password: utf8.encode('Password'),
            salt: utf8.encode('NaCl'),
            iterations: 80000,
            length: 64,
          ),
        ),
        '4ddcd8f60b98be21830cee5ef22701f9641a4418d04c0414aeff08876b34ab56'
        'a1d425a1225833549adb841b51c9b3176a272bdebba1d078478f62b397f33c8d',
      );
    });

    test('compares in constant time', () {
      expect(constantTimeEquals([1, 2, 3], [1, 2, 3]), isTrue);
      expect(constantTimeEquals([1, 2, 3], [1, 2, 4]), isFalse);
      expect(constantTimeEquals([1, 2], [1, 2, 3]), isFalse);
    });
  });

  group('PIN hasher', () {
    test('a verifier records its scheme and work, and never the PIN', () async {
      final hasher = Pbkdf2PinHasher(iterations: 2000, useIsolate: false);
      final first = await hasher.hash('482916');
      final second = await hasher.hash('482916');
      expect(
        first,
        matches(RegExp(r'^pbkdf2-sha256\$2000\$[\w-]{22}\$[\w-]{43}$')),
      );
      expect(first, isNot(second), reason: 'a fresh salt each time');
      expect(first, isNot(contains('482916')));
      expect(await hasher.verify('482916', first), isTrue);
      expect(await hasher.verify('482917', first), isFalse);
    });

    test('the production default runs on another isolate', () async {
      final hasher = Pbkdf2PinHasher();
      expect(hasher.iterations, Pbkdf2PinHasher.defaultIterations);
      final verifier = await hasher.hash('905172');
      expect(verifier, startsWith(r'pbkdf2-sha256$120000$'));
      expect(await hasher.verify('905172', verifier), isTrue);
      expect(hasher.needsRehash(verifier), isFalse);
    });

    test('malformed or tampered verifiers never match', () async {
      final hasher = Pbkdf2PinHasher(iterations: 1000, useIsolate: false);
      final good = await hasher.hash('482916');
      final parts = good.split(r'$');
      for (final bad in [
        '',
        'plain-482916',
        r'pbkdf2-sha256$1000$$',
        [parts[0], '99999999999', parts[2], parts[3]].join(r'$'),
        [parts[0], '0', parts[2], parts[3]].join(r'$'),
        [parts[0], parts[1], 'AAAA', parts[3]].join(r'$'),
        [parts[0], parts[1], parts[2], 'not base64!'].join(r'$'),
        ['md5', parts[1], parts[2], parts[3]].join(r'$'),
      ]) {
        expect(await hasher.verify('482916', bad), isFalse, reason: bad);
        expect(hasher.needsRehash(bad), isTrue, reason: bad);
      }
    });

    test('older, weaker verifiers ask to be upgraded', () async {
      final weak = await Pbkdf2PinHasher(
        iterations: 1000,
        useIsolate: false,
      ).hash('482916');
      expect(
        Pbkdf2PinHasher(iterations: 2000, useIsolate: false).needsRehash(weak),
        isTrue,
      );
    });
  });

  group('secure verifier store', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    test('keeps one verifier under its own key', () async {
      final store = SecurePinVerifierStore();
      expect(await store.read(), isNull);
      await store.write(r'pbkdf2-sha256$1$a$b');
      expect(await store.read(), r'pbkdf2-sha256$1$a$b');
      final all = await const FlutterSecureStorage().readAll();
      expect(all.keys, [SecurePinVerifierStore.key]);
      await store.delete();
      expect(await store.read(), isNull);
    });

    test('device-only Keychain access, no silent reset on Android', () {
      const options = SecurePinVerifierStore.defaultStorage;
      expect(
        options.iOptions.accessibility,
        KeychainAccessibility.first_unlock_this_device,
      );
      expect(options.iOptions.synchronizable, isFalse);
      expect(options.aOptions.toMap()['resetOnError'], 'false');
    });

    test(
      'platform failures become SecretStoreException without data',
      () async {
        final store = SecurePinVerifierStore(_FailingStorage());
        await expectLater(
          store.read(),
          throwsA(
            isA<SecretStoreException>().having(
              (e) => e.message,
              'message',
              'read failed (KeystoreError)',
            ),
          ),
        );
      },
    );
  });
}

final class _FailingStorage extends FlutterSecureStorage {
  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) => throw PlatformException(code: 'KeystoreError', message: 'secret');
}
