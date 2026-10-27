// EP03 (AC-EP14): the nine countdown presets in their packs' colours,
// mid-second and still (reduced motion), for visual review.
@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/experience/guest_experience.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_configuration.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_registry.dart';
import 'package:porcelain_photo_booth/domain/session/countdown_state.dart';
import 'package:porcelain_photo_booth/shared/guest/guest_countdown.dart';

const _presets = [
  ('porcelain-press', 'porcelain-classic', null),
  ('vintage-flip', 'vintage-oak', null),
  ('film-leader', 'retro-film', null),
  ('disco-pulse', 'disco-nights', null),
  ('storybook-magic', 'storybook-garden', null),
  ('party-pop', 'kid-party-arcade', null),
  ('arcade-start', 'retro-game-quest', 'arcade'),
  ('handheld-boot', 'retro-game-quest', 'handheld'),
  ('gala-elegant', 'midnight-gala', null),
];

const _state = CountdownState(remaining: 2, total: 3, shot: 0, shotCount: 2);

Widget _cell(
  String preset,
  String pack,
  String? variant, {
  required bool still,
}) {
  final experience = ExperienceRegistry.bundled.resolve(
    EventExperienceConfiguration(packId: pack, variantId: variant),
  );
  final t = GuestTokens.of(experience);
  return MediaQuery(
    data: MediaQueryData(disableAnimations: still),
    child: GuestExperience(
      experience: experience,
      child: Container(
        width: 200,
        height: 220,
        color: t.backdrop,
        child: Column(
          children: [
            const SizedBox(height: 6),
            Text(preset, style: t.body(13)),
            const SizedBox(height: 4),
            GuestCountdown(state: _state, size: 180, presetId: preset),
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('guest countdown sheet', (tester) async {
    tester.view
      ..physicalSize = const Size(1800, 440)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Material(
          child: Column(
            children: [
              for (final still in [false, true])
                Row(
                  children: [
                    for (final (preset, pack, variant) in _presets)
                      _cell(preset, pack, variant, still: still),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
    // Mid-way through the second's beat on the top row.
    await tester.pump(const Duration(milliseconds: 250));
    await expectLater(
      find.byType(Column).first,
      matchesGoldenFile('experience/guest_countdowns.png'),
    );
  }, skip: !Platform.isLinux); // UI goldens use the Linux CI rasterizer.
}
