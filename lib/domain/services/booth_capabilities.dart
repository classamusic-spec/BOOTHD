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
