// EP03 (AC-EP11, AC-EP14): nine countdown presets that only draw the
// state the session controller publishes; still forms for reduced motion;
// no flashing; every preset in every pack; nothing here can move a photo.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/experience/guest_experience.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_catalog.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_configuration.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_registry.dart';
import 'package:porcelain_photo_booth/domain/session/countdown_state.dart';
import 'package:porcelain_photo_booth/shared/guest/guest_countdown.dart';

const _state = CountdownState(remaining: 3, total: 5, shot: 0, shotCount: 2);

ResolvedExperience _resolve(String pack, {String? countdown}) =>
    ExperienceRegistry.bundled.resolve(
      EventExperienceConfiguration(packId: pack, countdownPresetId: countdown),
    );

Widget _host(
  Widget child, {
  ResolvedExperience? experience,
  bool reduceMotion = false,
  Key? boundary,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, page) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
    child: page!,
  ),
  home: GuestExperience(
    experience: experience ?? GuestExperience.fallback,
    child: Scaffold(
      body: Center(
        child: RepaintBoundary(key: boundary, child: child),
      ),
    ),
  ),
);

/// Mean relative luminance of [key]'s pixels, 0 to 1.
Future<double> _luminance(WidgetTester tester, Key key) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  final image = await tester.runAsync(() => boundary.toImage());
  final data = await tester.runAsync(
    () => image!.toByteData(format: ui.ImageByteFormat.rawRgba),
  );
  final bytes = Uint8List.view(data!.buffer);
  var sum = 0.0;
  for (var i = 0; i < bytes.length; i += 4) {
    sum +=
        (0.2126 * bytes[i] + 0.7152 * bytes[i + 1] + 0.0722 * bytes[i + 2]) /
        255;
  }
  image!.dispose();
  return sum / (bytes.length / 4);
}

void main() {
  test('every catalog countdown has a presenter', () {
    expect(CountdownPreset.ids.toSet(), ExperienceCatalog.countdowns);
    expect(CountdownPreset.of('nope'), isA<PorcelainPressCountdown>());
  });

  test('CountdownState reads the guest flow and its progress', () {
    expect(_state.progress, 0.4);
    expect(_state.isFinal, isFalse);
    expect(
      const CountdownState(
        remaining: 1,
        total: 3,
        shot: 1,
        shotCount: 2,
      ).isFinal,
      isTrue,
    );
  });

  for (final id in ExperienceCatalog.countdowns) {
    testWidgets('$id shows the number, moving and still', (tester) async {
      for (final reduce in [false, true]) {
        await tester.pumpWidget(
          _host(
            GuestCountdown(state: _state, presetId: id),
            reduceMotion: reduce,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('3'), findsOneWidget);
        expect(tester.takeException(), isNull);
        // Still: nothing is scheduled after the first frame.
        if (reduce) expect(tester.binding.hasScheduledFrame, isFalse);
      }
    });

    testWidgets('$id never flashes (at most 3 a second, WCAG 2.3.1)', (
      tester,
    ) async {
      const key = ValueKey('countdown');
      final experience = _resolve(
        id.startsWith('arcade') || id.startsWith('handheld')
            ? 'retro-game-quest'
            : id == 'disco-pulse'
            ? 'disco-nights'
            : 'porcelain-classic',
      );
      final samples = <double>[];
      for (final remaining in [3, 2, 1]) {
        await tester.pumpWidget(
          _host(
            SizedBox.square(
              dimension: 120,
              child: GuestCountdown(
                size: 120,
                presetId: id,
                state: CountdownState(
                  remaining: remaining,
                  total: 3,
                  shot: 0,
                  shotCount: 1,
                ),
              ),
            ),
            experience: experience,
            boundary: key,
          ),
        );
        for (var frame = 0; frame < 10; frame++) {
          samples.add(await _luminance(tester, key));
          await tester.pump(const Duration(milliseconds: 100));
        }
      }
      // A flash: a rise and a fall (or a fall and a rise) each of at
      // least 10 % of the full range, as WCAG's general flash threshold
      // counts them. Count them over the three seconds sampled.
      var flashes = 0;
      var direction = 0;
      var anchor = samples.first;
      for (final value in samples.skip(1)) {
        final change = value - anchor;
        if (change.abs() >= 0.1) {
          final now = change.sign.toInt();
          if (direction != 0 && now != direction) flashes++;
          direction = now;
          anchor = value;
        } else if ((direction > 0 && value > anchor) ||
            (direction < 0 && value < anchor)) {
          anchor = value;
        }
      }
      expect(flashes / 3, lessThanOrEqualTo(3), reason: 'samples $samples');
    });
  }

  testWidgets('each pack uses its own countdown unless the event chose one', (
    tester,
  ) async {
    for (final pack in ExperienceRegistry.bundled.packs) {
      final experience = _resolve(pack.packId);
      expect(
        ExperienceCatalog.countdowns,
        contains(experience.countdownPresetId),
      );
    }
    final chosen = _resolve('kid-party-arcade', countdown: 'gala-elegant');
    expect(chosen.countdownPresetId, 'gala-elegant');
  });

  testWidgets('a pack with animation off shows the still form', (tester) async {
    final still = ExperienceRegistry.bundled.resolve(
      const EventExperienceConfiguration(animation: AnimationIntensity.off),
    );
    await tester.pumpWidget(
      _host(const GuestCountdown(state: _state), experience: still),
    );
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
