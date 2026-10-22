// EP02 (AC-EP03, AC-EP05): the guest button sheet, every family on its
// pack's backdrop in every state, for visual review.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/design_system/porcelain_icons.dart';
import 'package:porcelain_photo_booth/core/experience/guest_experience.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_configuration.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_registry.dart';
import 'package:porcelain_photo_booth/shared/guest/guest_button.dart';
import 'package:porcelain_photo_booth/shared/widgets/pressable.dart';

const _packs = [
  ('porcelain-classic', null),
  ('porcelain-classic', 'darkroom'),
  ('vintage-oak', null),
  ('retro-film', null),
  ('disco-nights', null),
  ('storybook-garden', null),
  ('midnight-gala', null),
  ('kid-party-arcade', null),
  ('retro-game-quest', 'handheld'),
  ('retro-game-quest', 'arcade'),
];

class _Row extends StatelessWidget {
  const _Row({required this.experience});

  final ResolvedExperience experience;

  @override
  Widget build(BuildContext context) {
    final t = GuestTokens.of(experience);
    Widget cell(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: child,
    );
    return GuestExperience(
      experience: experience,
      child: Container(
        height: 150,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [t.backdrop, t.backdropAccent]),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 170,
              child: Text(
                experience.displayName,
                style: t.body(15, weight: FontWeight.w600),
              ),
            ),
            cell(
              GuestButton(
                label: 'Start',
                icon: PorcelainIcons.camera,
                onPressed: () {},
              ),
            ),
            cell(
              GuestButton(
                label: 'Retake',
                emphasis: GuestButtonEmphasis.secondary,
                onPressed: () {},
              ),
            ),
            cell(
              PressStatePreview(
                pressed: true,
                child: GuestButton(label: 'Pressed', onPressed: () {}),
              ),
            ),
            cell(
              PressStatePreview(
                focused: true,
                child: GuestButton(label: 'Focus', onPressed: () {}),
              ),
            ),
            cell(
              const GuestButton(
                label: 'Off',
                onPressed: null,
                disabledReason: 'Not yet',
              ),
            ),
            cell(GuestButton(label: 'Busy', busy: true, onPressed: () {})),
            cell(
              GuestButton(
                label: 'Chosen',
                selected: true,
                emphasis: GuestButtonEmphasis.secondary,
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  testWidgets('guest button sheet', (tester) async {
    tester.view
      ..physicalSize = Size(1500, 150.0 * _packs.length)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (context, page) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: page!,
        ),
        home: Material(
          child: Column(
            children: [
              for (final (pack, variant) in _packs)
                _Row(
                  experience: ExperienceRegistry.bundled.resolve(
                    EventExperienceConfiguration(
                      packId: pack,
                      variantId: variant,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Column).first,
      matchesGoldenFile('experience/guest_buttons.png'),
    );
  });
}
