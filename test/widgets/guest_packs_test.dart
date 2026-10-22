// EP06 (AC-EP05, AC-EP06, AC-EP09, AC-EP10, AC-EP11, AC-EP13) end to end
// on the simulated camera: every pack and variant runs the whole guest
// journey in both orientations through the same shared screens, wearing
// its own words and decorations, and the print each one asks for is the
// same render of the same template with the same photos: no pack, and
// no live template, reaches an export.
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/experience/guest_theme.dart';
import 'package:porcelain_photo_booth/core/experience/live_template.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_catalog.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_configuration.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_pack.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_registry.dart';
import 'package:porcelain_photo_booth/domain/template/template_json.dart';
import 'package:porcelain_photo_booth/features/booth/guest_finished.dart';
import 'package:porcelain_photo_booth/shared/guest/guest_countdown.dart';
import 'package:porcelain_photo_booth/shared/guest/guest_decorations.dart';

import '../support/app_harness.dart';
import '../support/seed.dart';
import '../support/tablet_viewports.dart';

Future<TestBooth> _booth(
  WidgetTester tester,
  EventExperienceConfiguration experience,
  TabletViewport viewport,
) {
  useViewport(tester, viewport);
  return pumpApp(
    tester,
    startAs: StartAs.booth,
    boothEventId: SeedIds.active,
    seed: (db) => seedEvents(
      db,
      active: (event) => event.copyWith(experience: experience),
    ),
    seedTemplates: seedTemplateDocuments,
  );
}

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pump(const Duration(milliseconds: 300));
}

/// Start, two photos, keep, finished, in [experience]'s own words.
/// [onCountdown] runs at the first second of each countdown.
Future<void> _session(
  WidgetTester tester,
  ResolvedExperience experience, {
  Future<void> Function()? onCountdown,
}) async {
  final words = experience.copy;
  await tester.tap(find.bySemanticsLabel(words[GuestCopyKey.start]).last);
  await _frames(tester);
  for (var photo = 0; photo < 2; photo++) {
    await onCountdown?.call();
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await _frames(tester);
    if (photo == 0) await tester.pump(const Duration(seconds: 3));
  }
  await tester.tap(find.bySemanticsLabel(words[GuestCopyKey.keepThese]).last);
  await _frames(tester);
  await _frames(tester);
  expect(find.byType(GuestFinished), findsOneWidget);
}

/// What the export was asked for: the document's canonical text and
/// which photo went in which slot, mirrored or not.
String _print(TestBooth booth) {
  final render = booth.exports.renders.single;
  final photos = [
    for (final slot in render.photos.keys.toList()..sort())
      '$slot=${render.photos[slot]!.photoId}'
          '${render.photos[slot]!.mirrored ? ' mirrored' : ''}',
  ];
  return '${TemplateJson.encode(render.document)}$photos';
}

void main() {
  final registry = ExperienceRegistry.bundled;
  final cases = [
    for (final pack in registry.packs)
      for (final variant in pack.variants)
        EventExperienceConfiguration(
          packId: pack.packId,
          variantId: variant.id,
        ),
  ];

  for (final viewport in [
    TabletViewport.ipadPortrait,
    TabletViewport.androidLandscape,
  ]) {
    testWidgets('every pack runs the whole journey at ${viewport.name}, '
        'and every print is the same', (tester) async {
      String? expected;
      for (final config in cases) {
        final where = '${config.packId}/${config.variantId}';
        final experience = registry.resolve(config);
        final booth = await _booth(tester, config, viewport);
        // Welcome: the pack's decorations, unless it is an original
        // look, which keeps its own audited screens exactly.
        final original = GuestTheme.originalAppearance(experience) != null;
        expect(
          find.byType(GuestDecorationLayer),
          original || experience.decorations.isEmpty
              ? findsNothing
              : findsWidgets,
          reason: where,
        );
        await _session(
          tester,
          experience,
          onCountdown: () async {
            expect(find.byType(GuestCountdown), findsOneWidget, reason: where);
          },
        );
        expect(tester.takeException(), isNull, reason: where);
        final print = _print(booth);
        expected ??= print;
        expect(print, expected, reason: '$where prints like every pack');
      }
    });
  }

  test('every decoration a pack names can be drawn', () {
    for (final pack in ExperienceRegistry.bundled.packs) {
      for (final variant in pack.variants) {
        final experience = ExperienceRegistry.bundled.resolve(
          EventExperienceConfiguration(
            packId: pack.packId,
            variantId: variant.id,
          ),
        );
        expect(
          guestDecorationIds,
          containsAll(experience.decorations),
          reason: '${pack.packId}/${variant.id}',
        );
      }
    }
  });

  testWidgets('Full Template: the live picture sits in the slot being taken, '
      'and the print is the same as camera-focused', (tester) async {
    const focused = EventExperienceConfiguration(
      packId: 'kid-party-arcade',
      cameraStage: CameraStageMode.cameraFocused,
    );
    final plain = await _booth(tester, focused, TabletViewport.ipadPortrait);
    await _session(tester, registry.resolve(focused));
    final expected = _print(plain);

    final full = focused.copyWith(cameraStage: CameraStageMode.fullTemplate);
    final booth = await _booth(tester, full, TabletViewport.ipadPortrait);
    var shown = 0;
    await _session(
      tester,
      registry.resolve(full),
      onCountdown: () async {
        // The template loads in real time (decoding).
        await settleRendering(tester, rounds: 20);
        await tester.pump();
        if (find.byType(LiveTemplateStage).evaluate().isNotEmpty) shown++;
      },
    );
    expect(shown, 2, reason: 'the template around both photos');
    expect(tester.takeException(), isNull);
    expect(_print(booth), expected, reason: 'the live template never prints');
  });
}
