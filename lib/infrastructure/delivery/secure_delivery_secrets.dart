import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/services/delivery_api.dart';
import '../security/secure_pin_verifier_store.dart';

/// Delivery secrets in platform secure storage (PD-05, AC-0903, AC-0906):
/// the same protection as the operator PIN's verifier (iPadOS Keychain,
/// this device only, never synchronised; Android Keystore-wrapped AES-GCM).
///
/// * The booth credential, until the booth is unpaired.
/// * Each pending delivery's phone number, under its own key, only until
///   the service has it, the delivery ends or its 24-hour window closes.
///
/// Errors carry the platform's error code only, never a value.
final class SecureDeliverySecrets implements DeliverySecrets {
  SecureDeliverySecrets([FlutterSecureStorage? storage])
    : _storage = storage ?? SecurePinVerifierStore.defaultStorage;

  static const credentialKey = 'porcelain.delivery_credential.v1';
  static const phonePrefix = 'porcelain.delivery_phone.v1.';

  final FlutterSecureStorage _storage;

  static final _intentId = RegExp(r'^[0-9a-f-]{36}$');

  String _phoneKey(String intentId) {
    if (!_intentId.hasMatch(intentId)) {
      throw const DeliverySecretsException('invalid-id');
    }
    return '$phonePrefix$intentId';
  }

  @override
  Future<String?> readCredential() =>
      _guard(() => _storage.read(key: credentialKey));

  @override
  Future<void> writeCredential(String credential) =>
      _guard(() => _storage.write(key: credentialKey, value: credential));

  @override
  Future<void> deleteCredential() =>
      _guard(() => _storage.delete(key: credentialKey));

  @override
  Future<void> storePhone(String intentId, String e164) =>
      _guard(() => _storage.write(key: _phoneKey(intentId), value: e164));

  @override
  Future<String?> readPhone(String intentId) =>
      _guard(() => _storage.read(key: _phoneKey(intentId)));

  @override
  Future<void> erasePhone(String intentId) =>
      _guard(() => _storage.delete(key: _phoneKey(intentId)));

  @override
  Future<Set<String>> storedPhoneIds() => _guard(() async {
    final all = await _storage.readAll();
    return {
      for (final key in all.keys)
        if (key.startsWith(phonePrefix)) key.substring(phonePrefix.length),
    };
  });

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on PlatformException catch (error) {
      throw DeliverySecretsException(error.code);
    }
  }
}
