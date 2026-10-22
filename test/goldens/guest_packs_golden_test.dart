// EP06 (AC-EP05, AC-EP06): every pack on the shared guest screens, in
// portrait and landscape: the welcome, the countdown, the review and the
// finished photo, as a guest sees them on the simulated camera. Half
// resolution keeps the repository small; the full-size screens of the
// original looks are in studio_goldens_test.dart.
@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/app/app.dart';
import 'package:porcelain_photo_booth/core/experience/live_template.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_catalog.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_configuration.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_pack.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_registry.dart';
import 'package:porcelain_photo_booth/features/booth/guest_finished.dart';
import 'package:porcelain_photo_booth/features/booth/guest_review.dart';

import '../support/app_harness.dart';
import '../support/seed.dart';
import '../support/tablet_viewports.dart';

/// Each pack in its default variant, and the second Retro Game Quest
/// cabinet.
const _looks = [
  ('porcelain-classic', null),
  ('vintage-oak', null),
  ('retro-film', null),
  ('disco-nights', null),
  ('storybook-garden', null),
  ('midnight-gala', null),
  ('kid-party-arcade', null),
  ('retro-game-quest', null),
  ('retro-game-quest', 'arcade'),
];

enum _Step { welcome, countdown, review, finished }

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _settle(WidgetTester tester) async {
  await settleRendering(tester, rounds: 6);
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> _to(WidgetTester tester, _Step step, GuestCopy words) async {
  if (step == _Step.welcome) return;
  await tester.tap(find.bySemanticsLabel(words[GuestCopyKey.start]).last);
  await _frames(tester);
  if (step == _Step.countdown) {
    // Mid-way through the first second, the frame at rest.
    await tester.pump(const Duration(milliseconds: 500));
    return;
  }
  for (var photo = 0; photo < 2; photo++) {
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await _frames(tester);
    if (photo == 0) await tester.pump(const Duration(seconds: 3));
  }
  await _settle(tester);
  expect(find.byType(GuestReview), findsOneWidget);
  if (step == _Step.review) return;
  await tester.tap(find.bySemanticsLabel(words[GuestCopyKey.keepThese]).last);
  await _frames(tester);
  await _settle(tester);
  await _frames(tester);
  await _settle(tester);
  expect(find.byType(GuestFinished), findsOneWidget);
}

void main() {
  // Full Template (EP06): the session's template around the live picture,
  // the photo being taken in its own slot.
  for (final viewport in [
    TabletViewport.ipadPortrait,
    TabletViewport.ipadLandscape,
  ]) {
    testWidgets('kid-party-arcade full template ${viewport.name}', (
      tester,
    ) async {
      const config = EventExperienceConfiguration(
        packId: 'kid-party-arcade',
        cameraStage: CameraStageMode.fullTemplate,
      );
      final words = ExperienceRegistry.bundled.resolve(config).copy;
      useViewport(tester, viewport, pixelRatio: 0.5);
      await pumpApp(
        tester,
        startAs: StartAs.booth,
        boothEventId: SeedIds.active,
        seed: (db) => seedEvents(
          db,
          active: (event) => event.copyWith(experience: config),
        ),
        seedTemplates: seedTemplateDocuments,
        settle: false,
      );
      await _settle(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(words[GuestCopyKey.start]).last);
      await _frames(tester);
      await settleRendering(tester, rounds: 20);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(LiveTemplateStage), findsOneWidget);
      await expectLater(
        find.byType(PorcelainApp),
        matchesGoldenFile(
          'experience/packs/kid-party-arcade_full_template_${viewport.name}.png',
        ),
      );
    }, skip: !Platform.isLinux);
  }

  for (final (pack, variant) in _looks) {
    final config = EventExperienceConfiguration(
      packId: pack,
      variantId: variant,
    );
    final words = ExperienceRegistry.bundled.resolve(config).copy;
    final look = variant == null ? pack : '$pack-$variant';
    for (final viewport in [
      TabletViewport.ipadPortrait,
      TabletViewport.ipadLandscape,
    ]) {
      for (final step in _Step.values) {
        testWidgets('$look ${step.name} ${viewport.name}', (tester) async {
          useViewport(tester, viewport, pixelRatio: 0.5);
          await pumpApp(
            tester,
            startAs: StartAs.booth,
            boothEventId: SeedIds.active,
            seed: (db) => seedEvents(
              db,
              active: (event) => event.copyWith(experience: config),
            ),
            seedTemplates: seedTemplateDocuments,
            settle: false,
          );
          await _settle(tester);
          await tester.pumpAndSettle();
          await _to(tester, step, words);
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byType(PorcelainApp),
            matchesGoldenFile(
              'experience/packs/${look}_${step.name}_${viewport.name}.png',
            ),
          );
        }, skip: !Platform.isLinux);
      }
    }
  }
}
