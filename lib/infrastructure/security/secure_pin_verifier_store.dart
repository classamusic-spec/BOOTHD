import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/repositories/operator_access_repository.dart';

/// The operator PIN's verifier in platform secure storage (A-12):
///
/// * iPadOS: a Keychain item readable after first unlock, on this device
///   only, never synchronised, so it is not restored onto another device.
/// * Android: AES-GCM encrypted under a Keystore-wrapped key. Errors are
///   reported rather than silently resetting the store, so a passing fault
///   cannot erase the PIN; the app falls back to the recovery code.
///
/// Only the verifier is stored, never the PIN. Error messages carry the
/// platform's error code only.
final class SecurePinVerifierStore implements PinVerifierStore {
  SecurePinVerifierStore([FlutterSecureStorage? storage])
    : _storage = storage ?? defaultStorage;

  static const defaultStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: false),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      synchronizable: false,
    ),
  );

  static const key = 'porcelain.operator_pin_verifier.v1';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _guard('read', () => _storage.read(key: key));

  @override
  Future<void> write(String verifier) =>
      _guard('write', () => _storage.write(key: key, value: verifier));

  @override
  Future<void> delete() => _guard('delete', () => _storage.delete(key: key));

  Future<T> _guard<T>(String operation, Future<T> Function() action) async {
    try {
      return await action();
    } on PlatformException catch (error) {
      throw SecretStoreException('$operation failed (${error.code})');
    }
  }
}
