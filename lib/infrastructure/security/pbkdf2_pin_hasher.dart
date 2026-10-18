import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import '../../domain/services/operator_secrets.dart';
import 'pbkdf2.dart';

/// Slow, salted verifiers for the operator PIN and recovery code (A-12,
/// ADR-0009): PBKDF2-HMAC-SHA256 with a 16-byte random salt and a 32-byte
/// result, encoded as `pbkdf2-sha256$<iterations>$<salt>$<hash>` (base64url).
///
/// The iteration count is stored in each verifier, so raising [iterations]
/// upgrades old verifiers after their next successful check. Derivation
/// runs on a short-lived isolate, never on the UI isolate.
final class Pbkdf2PinHasher implements PinHasher {
  Pbkdf2PinHasher({
    this.iterations = defaultIterations,
    Random? random,
    this._useIsolate = true,
  }) : _random = random ?? Random.secure();

  /// About 0.37 s on the CI-class host (AOT); expect up to about a second
  /// on slower tablets. Measured again on certified devices in M11.
  static const defaultIterations = 120000;

  /// Verifiers claiming more work than this are rejected as malformed, so a
  /// tampered verifier cannot stall the app.
  static const maxIterations = 5000000;

  static const _scheme = 'pbkdf2-sha256';
  static const _saltLength = 16;
  static const _hashLength = 32;

  final int iterations;
  final Random _random;
  final bool _useIsolate;

  @override
  Future<String> hash(String secret) async {
    final salt = Uint8List.fromList(
      List.generate(_saltLength, (_) => _random.nextInt(256)),
    );
    final derived = await _derive(secret, salt, iterations);
    return [_scheme, '$iterations', _encode(salt), _encode(derived)].join(r'$');
  }

  @override
  Future<bool> verify(String secret, String verifier) async {
    final parsed = _Verifier.parse(verifier);
    if (parsed == null) return false;
    final derived = await _derive(secret, parsed.salt, parsed.iterations);
    return constantTimeEquals(derived, parsed.hash);
  }

  @override
  bool needsRehash(String verifier) {
    final parsed = _Verifier.parse(verifier);
    return parsed == null || parsed.iterations < iterations;
  }

  Future<Uint8List> _derive(String secret, Uint8List salt, int rounds) {
    final password = utf8.encode(secret);
    Uint8List run() => pbkdf2HmacSha256(
      password: password,
      salt: salt,
      iterations: rounds,
      length: _hashLength,
    );
    return _useIsolate ? Isolate.run(run) : Future.sync(run);
  }

  static String _encode(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');
}

final class _Verifier {
  const _Verifier(this.iterations, this.salt, this.hash);

  final int iterations;
  final Uint8List salt;
  final Uint8List hash;

  static _Verifier? parse(String text) {
    final parts = text.split(r'$');
    if (parts.length != 4 || parts[0] != Pbkdf2PinHasher._scheme) return null;
    final iterations = int.tryParse(parts[1]);
    if (iterations == null ||
        iterations < 1 ||
        iterations > Pbkdf2PinHasher.maxIterations) {
      return null;
    }
    final salt = _decode(parts[2]);
    final hash = _decode(parts[3]);
    if (salt == null ||
        hash == null ||
        salt.length != Pbkdf2PinHasher._saltLength ||
        hash.length != Pbkdf2PinHasher._hashLength) {
      return null;
    }
    return _Verifier(iterations, salt, hash);
  }

  static Uint8List? _decode(String text) {
    try {
      return base64Url.decode(base64Url.normalize(text));
    } on FormatException {
      return null;
    }
  }
}
