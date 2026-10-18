import '../../domain/models/booth_event.dart';
import '../../domain/models/template_revision_summary.dart';
import '../../domain/services/booth_capabilities.dart';
import '../../domain/services/managed_storage.dart';

/// The launch checks this build can actually make (M03). Storage writes
/// are tested for real; everything else names the milestone that adds the
/// check and is never reported as ready.
final class DeviceCapabilityProbe implements BoothCapabilityProbe {
  const DeviceCapabilityProbe(this._storage);

  final ManagedStorage _storage;

  @override
  Future<CapabilityStatus> camera(CaptureSettings capture) async =>
      const CapabilityNotYetAvailable('M06');

  @override
  Future<CapabilityStatus> storageWrite() => _storage.probeWrite();

  @override
  Future<CapabilityStatus> freeSpace() async =>
      const CapabilityNotYetAvailable('M06');

  @override
  Future<CapabilityStatus> renderer(
    OutputProfile output,
    List<TemplateRevisionSummary> templates,
  ) async => const CapabilityNotYetAvailable('M04');

  @override
  Future<CapabilityStatus> templateAssets(
    List<TemplateRevisionSummary> templates,
  ) async => const CapabilityNotYetAvailable('M04');

  @override
  Future<CapabilityStatus> kioskLock() async =>
      const CapabilityNotYetAvailable('M10');
}
