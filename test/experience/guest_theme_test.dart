// EP06 (AC-EP05, AC-EP13): every pack becomes a Porcelain token set the
// shared guest screens can wear, with each text role at its contrast;
// original appearances stay exactly as they were.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/design_system/porcelain_theme.dart';
import 'package:porcelain_photo_booth/core/design_system/theme_profiles.dart';
import 'package:porcelain_photo_booth/core/experience/guest_experience.dart';
import 'package:porcelain_photo_booth/core/experience/guest_theme.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_configuration.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_registry.dart';

double _ratio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  test('original appearances keep their audited palettes', () {
    for (final profile in PorcelainThemeProfile.values) {
      final experience = ExperienceRegistry.bundled.resolve(
        ExperienceRegistry.forAppearance(profile),
      );
      expect(GuestTheme.originalAppearance(experience), profile);
      final theme = GuestTheme.of(experience).extension<PorcelainTheme>()!;
      expect(theme.colors, PorcelainPalettes.of(profile));
    }
  });

  test('a changed accent makes Porcelain Classic a derived theme', () {
    final experience = ExperienceRegistry.bundled.resolve(
      const EventExperienceConfiguration(accentColor: 0xFFE8C9A0),
    );
    expect(GuestTheme.originalAppearance(experience), isNull);
  });

  test('every pack and variant keeps the guest text contrasts', () {
    for (final pack in ExperienceRegistry.bundled.packs) {
      for (final variant in pack.variants) {
        final experience = ExperienceRegistry.bundled.resolve(
          EventExperienceConfiguration(
            packId: pack.packId,
            variantId: variant.id,
          ),
        );
        final c = GuestTheme.of(experience).extension<PorcelainTheme>()!.colors;
        final where = '${pack.packId}/${variant.id}';
        for (final ground in [c.canvas, c.surface]) {
          expect(_ratio(c.ink, ground), greaterThanOrEqualTo(7), reason: where);
          expect(
            _ratio(c.inkMuted, ground),
            greaterThanOrEqualTo(4.5),
            reason: where,
          );
          expect(
            _ratio(c.accentText, ground),
            greaterThanOrEqualTo(4.5),
            reason: where,
          );
          expect(
            _ratio(c.outline, ground),
            greaterThanOrEqualTo(3),
            reason: where,
          );
        }
        expect(_ratio(c.guestAccentText, c.canvas), greaterThanOrEqualTo(7));
        expect(_ratio(c.onPrimary, c.primaryBottom), greaterThanOrEqualTo(4.5));
        expect(_ratio(c.focusRing, c.canvas), greaterThanOrEqualTo(3));
      }
    }
  });

  test('guest type follows the pack faces; operator type does not', () {
    final quest = ExperienceRegistry.bundled.resolve(
      const EventExperienceConfiguration(packId: 'retro-game-quest'),
    );
    final text = GuestTheme.of(quest).extension<PorcelainTheme>()!.text;
    expect(text.guestTitle.fontFamily, GuestFonts.family('pixelify-sans'));
    expect(text.countdown.fontFamily, GuestFonts.family('pixelify-sans'));
    expect(text.titleLarge.fontFamily, 'Inter');
  });
}
