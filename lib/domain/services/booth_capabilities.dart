import 'package:meta/meta.dart';

import '../models/booth_event.dart';
import '../models/template_revision_summary.dart';

/// What a device check found.
@immutable
sealed class CapabilityStatus {
  const CapabilityStatus();
}

final class CapabilityReady extends CapabilityStatus {
  const CapabilityReady();
}

/// The check ran and found a problem. [code] follows the diagnostic code
/// families (A-14), e.g. `STORAGE_NOT_WRITABLE`.
final class CapabilityProblem extends CapabilityStatus {
  const CapabilityProblem(this.code);

  final String code;
}

/// The app cannot check this yet; [milestone] delivers the check. Never
/// reported as ready.
final class CapabilityNotYetAvailable extends CapabilityStatus {
  const CapabilityNotYetAvailable(this.milestone);

  final String milestone;
}

/// Free space on the volume that holds the booth's files. Dart has no API
/// for it; a narrow platform channel answers (ADR-0012).
abstract interface class DeviceStorageInfo {
  /// Bytes available to the app, or null when the platform cannot say.
  Future<int?> freeBytes();
}

/// How much free space a booth needs (A-11): a conservative estimate per
/// guest session (up to four 12 MP originals and a print-size output) and
/// the least that lets an event start.
abstract final class StorageBudget {
  static const bytesPerSession = 40 * 1024 * 1024;
  static const minimumFreeBytes = 1024 * 1024 * 1024;

  /// Below this a guest session does not start (M07): room for its
  /// originals, retakes and finished photo, with a margin.
  static const minimumSessionFreeBytes = 3 * bytesPerSession;

  /// About how many sessions [freeBytes] holds.
  static int sessionsFor(int freeBytes) => freeBytes ~/ bytesPerSession;
}

/// Device checks behind the launch checklist (S19, A-14).
abstract interface class BoothCapabilityProbe {
  /// Camera permission and the event's lens.
  Future<CapabilityStatus> camera(CaptureSettings capture);

  /// Write, read back and delete a file in managed storage.
  Future<CapabilityStatus> storageWrite();

  /// Enough free space for a full event.
  Future<CapabilityStatus> freeSpace();

  /// The production renderer can produce [output] for [templates].
  Future<CapabilityStatus> renderer(
    OutputProfile output,
    List<TemplateRevisionSummary> templates,
  );

  /// Every asset [templates] reference is present and intact.
  Future<CapabilityStatus> templateAssets(
    List<TemplateRevisionSummary> templates,
  );

  /// The OS kiosk lock (Guided Access, lock task) is on.
  Future<CapabilityStatus> kioskLock();
}
