/// Stable entity identifiers (A-05): random UUID version 4 strings,
/// generated on the device, never reused and never derived from content or
/// guest data.
library;

import 'dart:math';

/// Creates new entity identifiers. Injected so tests can use predictable
/// identifiers.
abstract interface class IdGenerator {
  /// A new identifier that [isEntityId] accepts.
  String newId();
}

/// UUID v4 identifiers from a cryptographically secure random source, so
/// identifiers cannot be guessed or collide in practice.
final class RandomIdGenerator implements IdGenerator {
  RandomIdGenerator([Random? random]) : _random = random ?? Random.secure();

  final Random _random;

  @override
  String newId() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // RFC 4122 variant
    final hex = [
      for (final byte in bytes) byte.toRadixString(16).padLeft(2, '0'),
    ].join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}

final _entityId = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

/// Whether [value] is a well-formed, lowercase UUID v4 identifier.
bool isEntityId(String value) => _entityId.hasMatch(value);
