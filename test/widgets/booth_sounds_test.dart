// EP03 (AC-EP14) end to end on the simulated camera: Booth Mode plays the
// frozen experience's sounds at the event's volume only when the event
// turned sound on, and a sound system that fails at everything changes
// nothing a guest sees: the same photos, at the same moments.
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_catalog.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_configuration.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_registry.dart';
import 'package:porcelain_photo_booth/domain/services/guest_sound_service.dart';
import 'package:porcelain_photo_booth/features/booth/booth_copy.dart';
import 'package:porcelain_photo_booth/features/booth/guest_finished.dart';

import '../support/app_harness.dart';
import '../support/seed.dart';
import '../support/sounds.dart';
import '../support/tablet_viewports.dart';

const _quest = EventExperienceConfiguration(
  packId: 'retro-game-quest',
  soundEnabled: true,
  soundVolume: 60,
);

Future<TestBooth> _booth(
  WidgetTester tester, {
  required EventExperienceConfiguration experience,
  required GuestSoundService sounds,
}) {
  useViewport(tester, TabletViewport.ipadPortrait);
  return pumpApp(
    tester,
    startAs: StartAs.booth,
    boothEventId: SeedIds.active,
    seed: (db) => seedEvents(
      db,
      active: (event) => event.copyWith(experience: experience),
    ),
    seedTemplates: seedTemplateDocuments,
    sounds: sounds,
  );
}

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pump(const Duration(milliseconds: 300));
}

/// Start, two photos with three-second countdowns, keep, finished.
/// Returns how many photos were saved after each second of each
/// countdown: when the photos were taken.
Future<List<int>> _session(WidgetTester tester, TestBooth booth) async {
  final saved = <int>[];
  await tester.tap(find.bySemanticsLabel('Start').last);
  await _frames(tester);
  for (var photo = 0; photo < 2; photo++) {
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(seconds: 1));
      saved.add(booth.stills.stills.length);
    }
    await _frames(tester);
    saved.add(booth.stills.stills.length);
    if (photo == 0) await tester.pump(const Duration(seconds: 3));
  }
  await tester.tap(find.bySemanticsLabel(BoothCopy.keepThese).last);
  await _frames(tester);
  await _frames(tester);
  expect(find.byType(GuestFinished), findsOneWidget);
  return saved;
}

void main() {
  testWidgets('sound on: the session sounds each moment at the event volume', (
    tester,
  ) async {
    final sounds = RecordingSoundService();
    final booth = await _booth(tester, experience: _quest, sounds: sounds);
    await _session(tester, booth);
    final pack = ExperienceRegistry.bundled.resolve(_quest).sounds;
    final heard = [for (final (id, _) in sounds.played) id];
    expect(sounds.played.map((p) => p.$2).toSet(), {0.6});
    expect(heard.first, pack[SoundCue.start]);
    expect(
      heard.where((id) => id == pack[SoundCue.tick]),
      hasLength(4),
      reason: 'two countdowns of 3, 2 and 1, the last second says go',
    );
    expect(
      heard.where((id) => id == pack[SoundCue.shutter]),
      hasLength(2),
      reason: 'one shutter per photo',
    );
    expect(heard.last, pack[SoundCue.celebrate]);
    expect(sounds.preloaded, pack.values.toSet());
  });

  testWidgets('sound off (the default): nothing is loaded or heard', (
    tester,
  ) async {
    final sounds = RecordingSoundService();
    final booth = await _booth(
      tester,
      experience: const EventExperienceConfiguration(
        packId: 'retro-game-quest',
      ),
      sounds: sounds,
    );
    await _session(tester, booth);
    expect(sounds.played, isEmpty);
    expect(sounds.preloaded, isEmpty);
  });

  testWidgets('a failing sound system changes nothing for the guest', (
    tester,
  ) async {
    final quiet = await _booth(
      tester,
      experience: _quest.copyWith(soundEnabled: false),
      sounds: RecordingSoundService(),
    );
    final expected = await _session(tester, quiet);

    final broken = await _booth(
      tester,
      experience: _quest,
      sounds: const ThrowingSoundService(),
    );
    final taken = await _session(tester, broken);
    expect(tester.takeException(), isNull);
    expect(taken, expected, reason: 'photos at the same moments');
    expect(taken.last, 2);
  });
}
