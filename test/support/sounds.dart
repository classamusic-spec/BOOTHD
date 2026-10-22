import 'package:porcelain_photo_booth/domain/models/booth_event.dart';
import 'package:porcelain_photo_booth/domain/services/camera_service.dart';
import 'package:porcelain_photo_booth/domain/services/guest_sound_service.dart';
import 'package:porcelain_photo_booth/domain/session/guest_flow.dart';
import 'package:porcelain_photo_booth/domain/session/session_plan.dart';
import 'package:porcelain_photo_booth/domain/session/session_shots.dart';
import 'package:porcelain_photo_booth/domain/value_objects/orientation.dart';

/// Records what would have been heard.
final class RecordingSoundService implements GuestSoundService {
  final preloaded = <String>{};

  /// (sound id, volume) in the order played.
  final played = <(String, double)>[];
  var disposed = false;

  @override
  Future<void> preload(Set<String> soundIds) async =>
      preloaded.addAll(soundIds);

  @override
  void play(String soundId, {double volume = 1}) =>
      played.add((soundId, volume));

  @override
  Future<void> dispose() async => disposed = true;
}

/// A sound system that fails at everything.
final class ThrowingSoundService implements GuestSoundService {
  const ThrowingSoundService();

  @override
  Future<void> preload(Set<String> soundIds) =>
      Future.error(StateError('no audio'));

  @override
  void play(String soundId, {double volume = 1}) =>
      throw StateError('no audio');

  @override
  Future<void> dispose() => Future.error(StateError('no audio'));
}

/// Every flow of a one-photo session, from the welcome to the finished
/// photo, with a [countdownSeconds] countdown.
List<GuestFlow> sessionFlows({int countdownSeconds = 3}) {
  final plan = SessionPlan(
    eventId: 'event-1',
    templateRevisionId: 'rev-a',
    slotIndexes: const [0],
    capture: CaptureSettings(
      lens: CameraLens.front,
      mirrorPreview: true,
      mirrorOutput: false,
      orientation: GuestOrientationPreference.portrait,
      shotCount: 1,
      countdownSeconds: countdownSeconds,
    ),
    output: const OutputProfile(),
    finishTimeoutSeconds: 30,
  );
  final flows = <GuestFlow>[GuestFlow.idle];
  void add(GuestFlow next) => flows.add(next);
  add(
    GuestFlow.idle.start(
      templates: const ['rev-a'],
      defaultTemplate: 'rev-a',
      guestChooses: false,
    ),
  );
  add(flows.last.sessionStarted(SessionShots.empty(plan)));
  add(flows.last.cameraReady());
  while (flows.last.stage == GuestStage.countdown) {
    add(flows.last.tick());
  }
  add(
    flows.last.photoSaved(
      ShotPhoto(
        shot: 0,
        attempt: 1,
        round: 0,
        originalId: 'original-1',
        capturedAtUtc: DateTime.utc(2026, 11, 14, 18),
      ),
    ),
  );
  add(flows.last.keep());
  add(flows.last.rendered('output-1'));
  return flows;
}
