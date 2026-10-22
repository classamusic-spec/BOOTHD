// EP09 (AC-EP05, AC-EP14): every pack's guest screens meet the same
// accessibility guidelines as the original looks (tap targets, labels,
// text contrast) in portrait and landscape, and every pack's session runs
// to the finished photo with reduced motion on.
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_configuration.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_pack.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_registry.dart';
import 'package:porcelain_photo_booth/features/booth/guest_finished.dart';
import 'package:porcelain_photo_booth/features/booth/guest_review.dart';
import 'package:porcelain_photo_booth/shared/guest/guest_countdown.dart';

import '../support/app_harness.dart';
import '../support/seed.dart';
import '../support/tablet_viewports.dart';

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

enum _Step { welcome, review, finished }

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _booth(
  WidgetTester tester,
  EventExperienceConfiguration config,
  TabletViewport viewport,
) async {
  useViewport(tester, viewport);
  await pumpApp(
    tester,
    startAs: StartAs.booth,
    boothEventId: SeedIds.active,
    seed: (db) =>
        seedEvents(db, active: (event) => event.copyWith(experience: config)),
    seedTemplates: seedTemplateDocuments,
    settle: false,
  );
  await settleRendering(tester, rounds: 6);
  await tester.pumpAndSettle();
}

/// From the welcome to [step], in [words].
Future<void> _to(WidgetTester tester, _Step step, GuestCopy words) async {
  if (step == _Step.welcome) return;
  await tester.tap(find.bySemanticsLabel(words[GuestCopyKey.start]).last);
  await _frames(tester);
  for (var photo = 0; photo < 2; photo++) {
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await _frames(tester);
    if (photo == 0) await tester.pump(const Duration(seconds: 3));
  }
  await settleRendering(tester, rounds: 4);
  expect(find.byType(GuestReview), findsOneWidget);
  if (step == _Step.review) return;
  await tester.tap(find.bySemanticsLabel(words[GuestCopyKey.keepThese]).last);
  for (var i = 0; i < 2; i++) {
    await _frames(tester);
    await settleRendering(tester, rounds: 6);
  }
  expect(find.byType(GuestFinished), findsOneWidget);
}

void main() {
  for (final (pack, variant) in _looks) {
    final config = EventExperienceConfiguration(
      packId: pack,
      variantId: variant,
    );
    final words = ExperienceRegistry.bundled.resolve(config).copy;
    final look = variant == null ? pack : '$pack/$variant';

    for (final viewport in [
      TabletViewport.ipadPortrait,
      TabletViewport.androidLandscape,
    ]) {
      for (final step in _Step.values) {
        testWidgets('$look ${step.name} meets the accessibility guidelines '
            'at ${viewport.name}', (tester) async {
          final semantics = tester.ensureSemantics();
          await _booth(tester, config, viewport);
          await _to(tester, step, words);
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          semantics.dispose();
        });
      }
    }

    testWidgets('$look runs a whole session with reduced motion', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await _booth(tester, config, TabletViewport.ipadPortrait);
      await tester.tap(find.bySemanticsLabel(words[GuestCopyKey.start]).last);
      await _frames(tester);
      expect(find.byType(GuestCountdown), findsOneWidget);
      // The still form: nothing left to animate while the second lasts.
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.hasRunningAnimations, isFalse);
      for (var photo = 0; photo < 2; photo++) {
        for (var i = 0; i < 3; i++) {
          await tester.pump(const Duration(seconds: 1));
        }
        await _frames(tester);
        if (photo == 0) await tester.pump(const Duration(seconds: 3));
      }
      await settleRendering(tester, rounds: 4);
      await tester.tap(
        find.bySemanticsLabel(words[GuestCopyKey.keepThese]).last,
      );
      for (var i = 0; i < 2; i++) {
        await _frames(tester);
        await settleRendering(tester, rounds: 6);
      }
      expect(find.byType(GuestFinished), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
