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

/// A build that cannot check the camera or free space yet (as before M06):
/// storage, the renderer and template assets are checked for real.
const _uncheckedDevice = DeviceFacts(
  camera: CapabilityNotYetAvailable('M06'),
  storageWrite: CapabilityReady(),
  freeSpace: CapabilityNotYetAvailable('M06'),
  renderer: CapabilityReady(),
  templateAssets: CapabilityReady(),
  kioskLock: CapabilityProblem('KIOSK_NOT_LOCKED'),
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

  test('capabilities a build cannot check are "not yet available" and '
      'block launch; none is reported as passed', () {
    final report = _evaluate(_event(), device: _uncheckedDevice);
    expect(report.canLaunch, isFalse);
    for (final (id, milestone) in [
      (PreflightCheckId.camera, 'M06'),
      (PreflightCheckId.freeSpace, 'M06'),
    ]) {
      expect(report[id].status, PreflightStatus.notYetAvailable, reason: '$id');
      expect(report[id].milestone, milestone);
      expect(report[id].blocksLaunch, isTrue);
    }
    for (final id in [
      PreflightCheckId.storageWrite,
      PreflightCheckId.renderer,
      PreflightCheckId.templateAssets,
    ]) {
      expect(report[id].status, PreflightStatus.pass, reason: '$id');
    }
    expect(
      report[PreflightCheckId.kioskLock].status,
      PreflightStatus.warning,
      reason: 'an unlocked tablet reminds, never blocks',
    );
  });

  DeviceFacts withDevice({
    CapabilityStatus freeSpace = const CapabilityReady(),
    CapabilityStatus kioskLock = const CapabilityReady(),
  }) => DeviceFacts(
    camera: const CapabilityReady(),
    storageWrite: const CapabilityReady(),
    freeSpace: freeSpace,
    renderer: const CapabilityReady(),
    templateAssets: const CapabilityReady(),
    kioskLock: kioskLock,
    viewport: ViewportOrientation.portrait,
    operatorPinAvailable: true,
  );

  test('the kiosk lock passes only when the tablet reports one, and '
      'otherwise warns without blocking (AC-1002, AC-1003)', () {
    final locked = _evaluate(_event(), device: withDevice());
    expect(locked[PreflightCheckId.kioskLock].status, PreflightStatus.pass);
    for (final code in ['KIOSK_NOT_LOCKED', 'KIOSK_UNKNOWN']) {
      final report = _evaluate(
        _event(),
        device: withDevice(kioskLock: CapabilityProblem(code)),
      );
      final check = report[PreflightCheckId.kioskLock];
      expect(check.status, PreflightStatus.warning, reason: code);
      expect(check.problemCode, code);
      expect(report.canLaunch, isTrue, reason: code);
    }
  });

  test('free space blocks only when not even one session fits (AC-1003, '
      'AC-1005)', () {
    for (final (code, status) in [
      ('STORAGE_LOW', PreflightStatus.warning),
      ('STORAGE_FREE_UNKNOWN', PreflightStatus.warning),
      ('STORAGE_FULL', PreflightStatus.blocked),
    ]) {
      final report = _evaluate(
        _event(),
        device: withDevice(freeSpace: CapabilityProblem(code)),
      );
      final check = report[PreflightCheckId.freeSpace];
      expect(check.status, status, reason: code);
      expect(check.problemCode, code);
      expect(report.canLaunch, status != PreflightStatus.blocked);
    }
  });

  test('only critical problems block the launch (AC-1003)', () {
    // Each device problem on its own, and whether guests could still be
    // served with it: no camera, nowhere to save, no room for a session,
    // no finished photo or no way out of Booth Mode block; the rest warn.
    final cases = <(String, DeviceFacts, bool)>[
      (
        'camera refused',
        DeviceFacts(
          camera: const CapabilityProblem('CAMERA_PERMISSION_DENIED'),
          storageWrite: const CapabilityReady(),
          freeSpace: const CapabilityReady(),
          renderer: const CapabilityReady(),
          templateAssets: const CapabilityReady(),
          kioskLock: const CapabilityReady(),
          viewport: ViewportOrientation.portrait,
          operatorPinAvailable: true,
        ),
        true,
      ),
      (
        'storage not writable',
        DeviceFacts(
          camera: const CapabilityReady(),
          storageWrite: const CapabilityProblem('STORAGE_NOT_WRITABLE'),
          freeSpace: const CapabilityReady(),
          renderer: const CapabilityReady(),
          templateAssets: const CapabilityReady(),
          kioskLock: const CapabilityReady(),
          viewport: ViewportOrientation.portrait,
          operatorPinAvailable: true,
        ),
        true,
      ),
      (
        'no room for a session',
        withDevice(freeSpace: const CapabilityProblem('STORAGE_FULL')),
        true,
      ),
      (
        'template cannot render',
        DeviceFacts(
          camera: const CapabilityReady(),
          storageWrite: const CapabilityReady(),
          freeSpace: const CapabilityReady(),
          renderer: const CapabilityProblem('RENDER_MISSING_ASSET'),
          templateAssets: const CapabilityReady(),
          kioskLock: const CapabilityReady(),
          viewport: ViewportOrientation.portrait,
          operatorPinAvailable: true,
        ),
        true,
      ),
      (
        'PIN unreadable',
        DeviceFacts(
          camera: const CapabilityReady(),
          storageWrite: const CapabilityReady(),
          freeSpace: const CapabilityReady(),
          renderer: const CapabilityReady(),
          templateAssets: const CapabilityReady(),
          kioskLock: const CapabilityReady(),
          viewport: ViewportOrientation.portrait,
          operatorPinAvailable: false,
        ),
        true,
      ),
      (
        'space low',
        withDevice(freeSpace: const CapabilityProblem('STORAGE_LOW')),
        false,
      ),
      (
        'space unknown',
        withDevice(freeSpace: const CapabilityProblem('STORAGE_FREE_UNKNOWN')),
        false,
      ),
      (
        'not locked',
        withDevice(kioskLock: const CapabilityProblem('KIOSK_NOT_LOCKED')),
        false,
      ),
      (
        'tablet the other way round',
        DeviceFacts(
          camera: const CapabilityReady(),
          storageWrite: const CapabilityReady(),
          freeSpace: const CapabilityReady(),
          renderer: const CapabilityReady(),
          templateAssets: const CapabilityReady(),
          kioskLock: const CapabilityReady(),
          viewport: ViewportOrientation.landscape,
          operatorPinAvailable: true,
        ),
        false,
      ),
    ];
    for (final (name, device, blocks) in cases) {
      final report = _evaluate(_event(), device: device);
      expect(report.canLaunch, !blocks, reason: name);
      expect(report.blockerCount, blocks ? 1 : 0, reason: name);
      if (!blocks) expect(report.warningCount, 1, reason: name);
    }
  });

  test('a template that cannot be rendered or has damaged files blocks, '
      'with its code', () {
    final report = _evaluate(
      _event(),
      device: const DeviceFacts(
        camera: CapabilityReady(),
        storageWrite: CapabilityReady(),
        freeSpace: CapabilityReady(),
        renderer: CapabilityProblem('RENDER_MISSING_ASSET'),
        templateAssets: CapabilityProblem('TEMPLATE_ASSET_MISSING'),
        kioskLock: CapabilityReady(),
        viewport: ViewportOrientation.portrait,
        operatorPinAvailable: true,
      ),
    );
    expect(report.canLaunch, isFalse);
    expect(report[PreflightCheckId.renderer].status, PreflightStatus.blocked);
    expect(
      report[PreflightCheckId.renderer].problemCode,
      'RENDER_MISSING_ASSET',
    );
    expect(
      report[PreflightCheckId.templateAssets].problemCode,
      'TEMPLATE_ASSET_MISSING',
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
