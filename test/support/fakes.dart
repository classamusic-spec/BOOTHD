import 'package:porcelain_photo_booth/domain/models/booth_event.dart';
import 'package:porcelain_photo_booth/domain/models/template_revision_summary.dart';
import 'package:porcelain_photo_booth/domain/repositories/operator_access_repository.dart';
import 'package:porcelain_photo_booth/domain/services/booth_capabilities.dart';
import 'package:porcelain_photo_booth/domain/services/kiosk_lock.dart';
import 'package:porcelain_photo_booth/domain/services/operator_secrets.dart';
import 'package:porcelain_photo_booth/domain/value_objects/clock.dart';
import 'package:porcelain_photo_booth/domain/value_objects/entity_id.dart';

/// A clock that only moves when told to.
final class FakeClock implements Clock {
  FakeClock([DateTime? start])
    : _now = start ?? DateTime.utc(2026, 10, 18, 9, 30);

  DateTime _now;

  @override
  DateTime now() => _now;

  void advance(Duration by) => _now = _now.add(by);

  void set(DateTime moment) => _now = moment.toUtc();
}

/// Predictable, valid UUID v4 identifiers: ...-000000000001, -2, ...
final class SequentialIds implements IdGenerator {
  SequentialIds([this._prefix = '00000000-0000-4000-8000']);

  final String _prefix;
  var _next = 1;

  @override
  String newId() => '$_prefix-${(_next++).toRadixString(16).padLeft(12, '0')}';
}

/// Secure storage in memory, with switchable failures.
final class MemoryPinVerifierStore implements PinVerifierStore {
  String? value;
  bool failReads = false;
  int writes = 0;

  @override
  Future<String?> read() async {
    if (failReads) throw const SecretStoreException('read failed (test)');
    return value;
  }

  @override
  Future<void> write(String verifier) async {
    writes++;
    value = verifier;
  }

  @override
  Future<void> delete() async => value = null;
}

final class MemoryOperatorAccessRepository implements OperatorAccessRepository {
  OperatorAccessRecord record = const OperatorAccessRecord();

  @override
  Future<OperatorAccessRecord> read() async => record;

  @override
  Future<void> write(OperatorAccessRecord record) async => this.record = record;
}

/// A fast, deterministic stand-in for the PBKDF2 hasher in widget tests,
/// where real key stretching and isolates would only slow things down.
/// The verifier still never contains the secret.
final class FastTestHasher implements PinHasher {
  var _counter = 0;

  static int _mix(String secret, int salt) {
    var hash = 0x811c9dc5 ^ salt;
    for (final unit in secret.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
    }
    return hash;
  }

  @override
  Future<String> hash(String secret) async {
    final salt = ++_counter;
    return 'test\$$salt\$${_mix(secret, salt)}';
  }

  @override
  Future<bool> verify(String secret, String verifier) async {
    final parts = verifier.split(r'$');
    if (parts.length != 3 || parts[0] != 'test') return false;
    final salt = int.parse(parts[1]);
    return _mix(secret, salt).toString() == parts[2];
  }

  @override
  bool needsRehash(String verifier) => false;
}

/// Device checks with chosen answers; by default what the production
/// probe reports on a working tablet with camera access and intact
/// templates that is not (yet) locked to the app: everything passes except
/// the kiosk lock, which warns (M10).
final class FakeCapabilityProbe implements BoothCapabilityProbe {
  FakeCapabilityProbe({
    this.cameraStatus = const CapabilityReady(),
    this.storageStatus = const CapabilityReady(),
    this.freeSpaceStatus = const CapabilityReady(),
    this.rendererStatus = const CapabilityReady(),
    this.assetsStatus = const CapabilityReady(),
    this.kioskStatus = const CapabilityProblem('KIOSK_NOT_LOCKED'),
  });

  /// Every device check passes, the tablet locked to the app.
  FakeCapabilityProbe.allReady()
    : cameraStatus = const CapabilityReady(),
      storageStatus = const CapabilityReady(),
      freeSpaceStatus = const CapabilityReady(),
      rendererStatus = const CapabilityReady(),
      assetsStatus = const CapabilityReady(),
      kioskStatus = const CapabilityReady();

  CapabilityStatus cameraStatus;
  CapabilityStatus storageStatus;
  CapabilityStatus freeSpaceStatus;
  CapabilityStatus rendererStatus;
  CapabilityStatus assetsStatus;
  CapabilityStatus kioskStatus;

  @override
  Future<CapabilityStatus> camera(CaptureSettings capture) async =>
      cameraStatus;

  @override
  Future<CapabilityStatus> storageWrite() async => storageStatus;

  @override
  Future<CapabilityStatus> freeSpace() async => freeSpaceStatus;

  @override
  Future<CapabilityStatus> renderer(
    OutputProfile output,
    List<TemplateRevisionSummary> templates,
  ) async => rendererStatus;

  @override
  Future<CapabilityStatus> templateAssets(
    List<TemplateRevisionSummary> templates,
  ) async => assetsStatus;

  @override
  Future<CapabilityStatus> kioskLock() async => kioskStatus;
}

/// The tablet's kiosk lock, as a test sets it (M10).
final class FakeKioskLock implements KioskLockInfo {
  FakeKioskLock([this.lock = KioskLock.none]);

  KioskLock lock;

  /// How many times the lock was read.
  var reads = 0;

  @override
  Future<KioskLock> current() async {
    reads++;
    return lock;
  }
}
