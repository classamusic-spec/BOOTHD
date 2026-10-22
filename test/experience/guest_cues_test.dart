// EP03 (AC-EP14): sounds are opt-in, follow the frozen experience and
// its volume, play the right cue at each guest moment, and a sound that
// fails is silent and harmless.
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/experience/guest_cues.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_catalog.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_configuration.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_registry.dart';
import 'package:porcelain_photo_booth/domain/services/guest_sound_service.dart';

import '../support/sounds.dart';

ResolvedExperience _resolve({
  String pack = 'retro-game-quest',
  bool? sound = true,
  int volume = 50,
  bool celebrate = true,
}) => ExperienceRegistry.bundled.resolve(
  EventExperienceConfiguration(
    packId: pack,
    soundEnabled: sound,
    soundVolume: volume,
    celebrationEnabled: celebrate,
  ),
);

void main() {
  test('sound is off unless the event turns it on', () async {
    final sounds = RecordingSoundService();
    final player = GuestCuePlayer(sounds);
    await player.use(_resolve(sound: null));
    player.cue(SoundCue.press);
    expect(sounds.played, isEmpty);
    expect(sounds.preloaded, isEmpty, reason: 'nothing is loaded either');
  });

  test('cues play the pack sound at the event volume', () async {
    final sounds = RecordingSoundService();
    final player = GuestCuePlayer(sounds);
    final experience = _resolve(volume: 40);
    await player.use(experience);
    expect(sounds.preloaded, experience.sounds.values.toSet());
    for (final cue in SoundCue.values) {
      player.cue(cue);
    }
    expect(sounds.played.map((p) => p.$1), [
      for (final cue in SoundCue.values) experience.sounds[cue],
    ]);
    expect(sounds.played.map((p) => p.$2).toSet(), {0.4});
  });

  test('a session moment plays its cue', () {
    final sounds = RecordingSoundService();
    final player = GuestCuePlayer(sounds);
    final experience = _resolve();
    player.use(experience);
    final steps = sessionFlows(countdownSeconds: 3);
    for (var i = 1; i < steps.length; i++) {
      player.onFlow(steps[i - 1], steps[i]);
    }
    expect(sounds.played.map((p) => p.$1), [
      experience.sounds[SoundCue.start],
      experience.sounds[SoundCue.tick], // 3
      experience.sounds[SoundCue.tick], // 2
      experience.sounds[SoundCue.go], // 1
      experience.sounds[SoundCue.shutter],
      experience.sounds[SoundCue.celebrate],
    ]);
  });

  test('without a celebration the finish is a plain success', () {
    final sounds = RecordingSoundService();
    final player = GuestCuePlayer(sounds)..use(_resolve(celebrate: false));
    final steps = sessionFlows(countdownSeconds: 1);
    player.onFlow(steps[steps.length - 2], steps.last);
    expect(sounds.played.single.$1, _resolve().sounds[SoundCue.success]);
  });

  test('a failing sound service never throws into the flow', () async {
    final player = GuestCuePlayer(const ThrowingSoundService());
    await expectLater(player.use(_resolve()), completes);
    expect(() => player.cue(SoundCue.go), returnsNormally);
  });

  test('the silent service accepts everything', () async {
    const silent = SilentGuestSoundService();
    await silent.preload({'porcelain-tap'});
    silent.play('porcelain-tap');
    await silent.dispose();
  });
}
