// AC-0306: drafts, missing templates and invalid settings block or warn at
// preflight; checks the app cannot make yet never pass.
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/models/booth_event.dart';
import 'package:porcelain_photo_booth/domain/models/event_rules.dart';
import 'package:porcelain_photo_booth/domain/models/template_revision_summary.dart';
import 'package:porcelain_photo_booth/domain/services/booth_capabilities.dart';
import 'package:porcelain_photo_booth/domain/services/camera_service.dart';
import 'package:porcelain_photo_booth/domain/services/preflight.dart';
import 'package:porcelain_photo_booth/domain/value_objects/orientation.dart';

final _now = DateTime.utc(2026, 10, 18);

const _template = TemplateRevisionSummary(
  revisionId: 'r1',
  templateId: 't1',
  templateName: 'Two-up',
  revisionNumber: 1,
  pageWidthPx: 1200,
  pageHeightPx: 1800,
  photoSlotCount: 2,
);

BoothEvent _event({
  EventStatus status = EventStatus.active,
  TemplateSelection templates = const TemplateSelection(
    revisionIds: ['r1'],
    defaultRevisionId: 'r1',
  ),
  int shots = 2,
  GuestOrientationPreference orientation = GuestOrientationPreference.portrait,
}) => BoothEvent(
  id: '00000000-0000-4000-8000-000000000001',
  title: 'Gala',
  status: status,
  boothProfileId: '00000000-0000-4000-8000-0000000000b0',
  createdAt: _now,
  updatedAt: _now,
  archivedAt: status == EventStatus.archived ? _now : null,
  capture: CaptureSettings(
    lens: CameraLens.front,
    mirrorPreview: true,
    mirrorOutput: false,
    orientation: orientation,
    shotCount: shots,
  ),
  templates: templates,
);

/// What the M03 build reports: only storage can really be checked.
const _m03Device = DeviceFacts(
  camera: CapabilityNotYetAvailable('M06'),
  storageWrite: CapabilityReady(),
  freeSpace: CapabilityNotYetAvailable('M06'),
  renderer: CapabilityNotYetAvailable('M04'),
  templateAssets: CapabilityNotYetAvailable('M04'),
  kioskLock: CapabilityNotYetAvailable('M10'),
  viewport: ViewportOrientation.portrait,
  operatorPinAvailable: true,
);

const _readyDevice = DeviceFacts(
  camera: CapabilityReady(),
  storageWrite: CapabilityReady(),
  freeSpace: CapabilityReady(),
  renderer: CapabilityReady(),
  templateAssets: CapabilityReady(),
  kioskLock: CapabilityReady(),
  viewport: ViewportOrientation.portrait,
  operatorPinAvailable: true,
);

PreflightReport _evaluate(
  BoothEvent event, {
  DeviceFacts device = _readyDevice,
  Map<String, TemplateRevisionSummary> library = const {'r1': _template},
}) => Preflight.evaluate(event: event, library: library, device: device);

void main() {
  test('every check appears once, in display order', () {
    final report = _evaluate(_event());
    expect(report.checks.map((c) => c.id), PreflightCheckId.values);
  });

  test('with every capability ready, a valid active event can launch', () {
    final report = _evaluate(_event());
    expect(report.canLaunch, isTrue);
    expect(report.blockerCount, 0);
    expect(report[PreflightCheckId.printer].status, PreflightStatus.info);
  });

  test('in this build, unchecked capabilities are "not yet available" and '
      'block launch; none is reported as passed', () {
    final report = _evaluate(_event(), device: _m03Device);
    expect(report.canLaunch, isFalse);
    for (final (id, milestone) in [
      (PreflightCheckId.camera, 'M06'),
      (PreflightCheckId.freeSpace, 'M06'),
      (PreflightCheckId.renderer, 'M04'),
      (PreflightCheckId.templateAssets, 'M04'),
    ]) {
      expect(report[id].status, PreflightStatus.notYetAvailable, reason: '$id');
      expect(report[id].milestone, milestone);
      expect(report[id].blocksLaunch, isTrue);
    }
    expect(report[PreflightCheckId.storageWrite].status, PreflightStatus.pass);
    expect(
      report[PreflightCheckId.kioskLock].status,
      PreflightStatus.warning,
      reason: 'an unverifiable kiosk lock reminds, never blocks',
    );
  });

  test('a draft or archived event is blocked', () {
    for (final status in [EventStatus.draft, EventStatus.archived]) {
      final check = _evaluate(
        _event(status: status),
      )[PreflightCheckId.eventStatus];
      expect(check.status, PreflightStatus.blocked);
      expect(check.issues, [EventNotActive(status)]);
    }
  });

  test('no template, a missing one or a slot mismatch blocks', () {
    expect(
      _evaluate(
        _event(templates: const TemplateSelection()),
      )[PreflightCheckId.templates].issues,
      [const NoTemplates()],
    );
    final missing = _evaluate(_event(), library: const {});
    expect(missing[PreflightCheckId.templates].status, PreflightStatus.blocked);
    expect(missing[PreflightCheckId.templates].issues, [
      const TemplateNotFound('r1'),
    ]);
    final mismatch = _evaluate(_event(shots: 3));
    expect(mismatch[PreflightCheckId.templates].issues, [
      const TemplateSlotsMismatch(_template, 3),
    ]);
    expect(mismatch.canLaunch, isFalse);
  });

  test('invalid stored settings block', () {
    final broken = _event().copyWith(
      capture: _event().capture.copyWith(countdownSeconds: 30),
    );
    final check = _evaluate(broken)[PreflightCheckId.eventSettings];
    expect(check.status, PreflightStatus.blocked);
    expect(check.issues.single, isA<SettingOutOfRange>());
  });

  test('an archived template warns without blocking', () {
    const archived = TemplateRevisionSummary(
      revisionId: 'r1',
      templateId: 't1',
      templateName: 'Two-up',
      revisionNumber: 1,
      pageWidthPx: 1200,
      pageHeightPx: 1800,
      photoSlotCount: 2,
      templateArchived: true,
    );
    final report = _evaluate(_event(), library: const {'r1': archived});
    expect(report[PreflightCheckId.templates].status, PreflightStatus.warning);
    expect(report.canLaunch, isTrue);
    expect(report.warningCount, 1);
  });

  test(
    'a window that disagrees with the orientation preference warns only',
    () {
      final report = _evaluate(
        _event(orientation: GuestOrientationPreference.landscape),
      );
      expect(
        report[PreflightCheckId.orientation].status,
        PreflightStatus.warning,
      );
      expect(report.canLaunch, isTrue);
    },
  );

  test('a failed storage write or a missing PIN blocks', () {
    const device = DeviceFacts(
      camera: CapabilityReady(),
      storageWrite: CapabilityProblem('STORAGE_NOT_WRITABLE'),
      freeSpace: CapabilityReady(),
      renderer: CapabilityReady(),
      templateAssets: CapabilityReady(),
      kioskLock: CapabilityReady(),
      viewport: ViewportOrientation.portrait,
      operatorPinAvailable: false,
    );
    final report = _evaluate(_event(), device: device);
    expect(
      report[PreflightCheckId.storageWrite].status,
      PreflightStatus.blocked,
    );
    expect(
      report[PreflightCheckId.storageWrite].problemCode,
      'STORAGE_NOT_WRITABLE',
    );
    expect(
      report[PreflightCheckId.operatorPin].status,
      PreflightStatus.blocked,
    );
    expect(report.blockerCount, 2);
  });
}
