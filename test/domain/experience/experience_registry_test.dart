// EP01: the Experience Pack model, the bundled packs, the registry's
// validation and fallbacks, an event's configuration and the snapshot a
// session freezes.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/design_system/theme_profiles.dart';
import 'package:porcelain_photo_booth/domain/experience/bundled_packs.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_catalog.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_configuration.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_pack.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_registry.dart';
import 'package:porcelain_photo_booth/infrastructure/database/booth_database.dart';

const _packIds = [
  'porcelain-classic',
  'vintage-oak',
  'retro-film',
  'disco-nights',
  'storybook-garden',
  'midnight-gala',
  'kid-party-arcade',
  'retro-game-quest',
];

/// [pack] with [change] applied to its stored form.
ExperiencePack _edited(
  ExperiencePack pack,
  void Function(Map<String, Object?> json) change,
) {
  final json = jsonDecode(jsonEncode(pack.toJson())) as Map<String, Object?>;
  change(json);
  return ExperiencePack.fromJson(json);
}

Set<ExperienceProblemCode> _codes(Iterable<ExperienceProblem> problems) => {
  for (final problem in problems) problem.code,
};

void main() {
  final registry = ExperienceRegistry.bundled;

  group('bundled packs', () {
    test('all eight are present, valid and none is rejected', () {
      expect(registry.packs.map((pack) => pack.packId), _packIds);
      expect(registry.rejected, isEmpty);
      for (final pack in bundledPacks) {
        expect(
          ExperienceRegistry.validatePack(pack),
          isEmpty,
          reason: pack.packId,
        );
      }
    });

    test('every pack supports both guest orientations', () {
      for (final pack in registry.packs) {
        expect(
          pack.orientations,
          ExperienceOrientation.values.toSet(),
          reason: pack.packId,
        );
      }
    });

    test('every variant keeps guest text readable (WCAG 4.5:1)', () {
      for (final pack in registry.packs) {
        for (final variant in pack.variants) {
          final palette = pack.palette.withOverrides(variant.palette);
          for (final (text, ground) in [
            (PaletteRole.ink, PaletteRole.backdrop),
            (PaletteRole.ink, PaletteRole.panel),
            (PaletteRole.inkMuted, PaletteRole.panel),
            (PaletteRole.onAccent, PaletteRole.accent),
          ]) {
            expect(
              contrastRatio(palette[text], palette[ground]),
              greaterThanOrEqualTo(minimumTextContrast),
              reason:
                  '${pack.packId}/${variant.id} ${text.name}/${ground.name}',
            );
          }
        }
      }
    });

    test('Retro Game Quest offers Handheld Retro and Arcade Cabinet', () {
      final quest = registry.pack('retro-game-quest')!;
      expect(quest.variants.map((v) => v.name), [
        'Handheld Retro',
        'Arcade Cabinet',
      ]);
      expect(quest.defaultVariantId, 'handheld');
    });

    test('Porcelain Classic speaks the words guests saw before packs', () {
      final copy = registry.fallback.copy;
      expect(copy[GuestCopyKey.start], 'Start');
      expect(copy[GuestCopyKey.getReady], 'Get ready!');
      expect(copy[GuestCopyKey.readyTitle], 'Your photos are ready!');
      expect(copy.shotProgress(1, 2), 'Photo 1 of 2');
    });

    test('packs survive their JSON form unchanged', () {
      for (final pack in registry.packs) {
        final json = jsonEncode(pack.toJson());
        final again = ExperiencePack.fromJson(
          jsonDecode(json) as Map<String, Object?>,
        );
        expect(jsonEncode(again.toJson()), json, reason: pack.packId);
      }
    });

    test('a pack schema this app does not read is refused', () {
      expect(
        () => _edited(registry.fallback, (json) => json['schemaVersion'] = 99),
        throwsFormatException,
      );
      expect(
        () => _edited(registry.fallback, (json) => json['palette'] = 'gold'),
        throwsFormatException,
      );
    });
  });

  group('validation', () {
    final base = registry.pack('disco-nights')!;

    test('unreadable colours are refused', () {
      final grey = _edited(base, (json) {
        final palette = json['palette']! as Map<String, Object?>;
        palette['ink'] = palette['backdrop'];
      });
      expect(
        _codes(ExperienceRegistry.validatePack(grey)),
        contains(ExperienceProblemCode.unreadableColors),
      );
      final seeThrough = _edited(base, (json) {
        (json['palette']! as Map<String, Object?>)['panel'] = '#80FFFFFF';
      });
      expect(
        _codes(ExperienceRegistry.validatePack(seeThrough)),
        contains(ExperienceProblemCode.unreadableColors),
      );
    });

    test('unknown presets, sounds, fonts and decorations are refused', () {
      final odd = _edited(base, (json) {
        json['countdownPresetId'] = 'fireworks-9000';
        (json['sounds']! as Map<String, Object?>)['go'] = 'https://x/y.mp3';
        (json['typography']! as Map<String, Object?>)['display'] = 'comic';
        json['decorations'] = ['famous-plumber'];
      });
      final problems = ExperienceRegistry.validatePack(odd);
      expect(
        problems,
        containsAll([
          const ExperienceProblem(
            ExperienceProblemCode.unknownPreset,
            'fireworks-9000',
          ),
          const ExperienceProblem(
            ExperienceProblemCode.unknownAsset,
            'https://x/y.mp3',
          ),
          const ExperienceProblem(ExperienceProblemCode.unknownFont, 'comic'),
          const ExperienceProblem(
            ExperienceProblemCode.unknownAsset,
            'famous-plumber',
          ),
        ]),
      );
    });

    test('guest text must fit and keep its placeholders', () {
      final wordy = _edited(base, (json) {
        final copy = json['copy']! as Map<String, Object?>;
        copy['start'] = 'Start ' * 20;
        copy['shotProgress'] = 'Photo {n}';
      });
      expect(
        ExperienceRegistry.validatePack(wordy),
        containsAll([
          const ExperienceProblem(ExperienceProblemCode.invalidText, 'start'),
          const ExperienceProblem(
            ExperienceProblemCode.invalidText,
            'shotProgress',
          ),
        ]),
      );
    });

    test('a pack missing an orientation or small buttons is refused', () {
      final portraitOnly = _edited(
        base,
        (json) => json['orientations'] = ['portrait'],
      );
      expect(
        _codes(ExperienceRegistry.validatePack(portraitOnly)),
        contains(ExperienceProblemCode.missingOrientation),
      );
      final tiny = _edited(base, (json) {
        (json['accessibility']! as Map<String, Object?>)['minTouchTarget'] = 44;
      });
      expect(
        _codes(ExperienceRegistry.validatePack(tiny)),
        contains(ExperienceProblemCode.invalidPack),
      );
    });

    test('a registry leaves out a broken pack and keeps the rest', () {
      final broken = _edited(base, (json) {
        json['packId'] = 'broken-pack';
        json['countdownPresetId'] = 'nope';
      });
      final mixed = ExperienceRegistry([...bundledPacks, broken]);
      expect(mixed.pack('broken-pack'), isNull);
      expect(mixed.rejected.keys, ['broken-pack']);
      expect(mixed.packs, hasLength(8));
    });
  });

  group('resolve', () {
    test('the default configuration is Porcelain Classic, untouched', () {
      final resolved = registry.resolve(const EventExperienceConfiguration());
      expect(resolved.problems, isEmpty);
      expect(resolved.packId, 'porcelain-classic');
      expect(resolved.variantId, 'ivory');
      expect(resolved.buttonStyle, GuestButtonStyle.porcelain);
      expect(resolved.soundEnabled, isFalse, reason: 'sound is opt-in');
      expect(resolved.minTouchTarget, greaterThanOrEqualTo(72));
    });

    test('an unknown pack falls back to Porcelain Classic and says so', () {
      final resolved = registry.resolve(
        const EventExperienceConfiguration(
          packId: 'deleted-pack',
          variantId: 'blue',
          getReadyText: 'Here we go',
        ),
      );
      expect(resolved.packId, 'porcelain-classic');
      expect(resolved.variantId, 'ivory', reason: 'the old variant is gone');
      expect(resolved.copy[GuestCopyKey.getReady], 'Here we go');
      expect(resolved.problems, [
        const ExperienceProblem(
          ExperienceProblemCode.unknownPack,
          'deleted-pack',
        ),
      ]);
    });

    test('a pack version newer than this app falls back', () {
      final resolved = registry.resolve(
        const EventExperienceConfiguration(
          packId: 'disco-nights',
          packVersion: 7,
        ),
      );
      expect(resolved.packId, 'porcelain-classic');
      expect(_codes(resolved.problems), {
        ExperienceProblemCode.unsupportedPackVersion,
      });
    });

    test('variants, presets and colours fall back to the pack own', () {
      final quest = registry.pack('retro-game-quest')!;
      final handheld = quest.palette.withOverrides(
        quest.defaultVariant.palette,
      );
      // The colour of the text on the accent: no contrast at all.
      final unreadable = handheld[PaletteRole.onAccent];
      final resolved = registry.resolve(
        EventExperienceConfiguration(
          packId: 'retro-game-quest',
          variantId: 'pocket',
          countdownPresetId: 'laser-show',
          accentColor: unreadable,
        ),
      );
      expect(resolved.variantId, 'handheld');
      expect(
        resolved.countdownPresetId,
        quest.defaultVariant.countdownPresetId ?? quest.countdownPresetId,
      );
      expect(
        resolved.palette[PaletteRole.accent],
        handheld[PaletteRole.accent],
        reason: 'text on the accent must stay readable',
      );
      expect(_codes(resolved.problems), {
        ExperienceProblemCode.unknownVariant,
        ExperienceProblemCode.unknownPreset,
        ExperienceProblemCode.unreadableColors,
      });
      final seeThrough = registry.resolve(
        const EventExperienceConfiguration(accentColor: 0x80DCBE88),
      );
      expect(
        seeThrough.palette[PaletteRole.accent],
        registry.fallback.palette[PaletteRole.accent],
      );
    });

    test('operator choices replace the pack defaults when readable', () {
      final resolved = registry.resolve(
        const EventExperienceConfiguration(
          packId: 'retro-game-quest',
          variantId: 'arcade',
          countdownPresetId: 'gala-elegant',
          getReadyText: '  Player one, ready?  ',
          finishText: 'High score!',
          soundEnabled: true,
          soundVolume: 35,
          animation: AnimationIntensity.off,
          celebrationEnabled: false,
          cameraStage: CameraStageMode.cameraFocused,
          childrenMayBeGuests: true,
        ),
      );
      expect(resolved.problems, isEmpty);
      expect(resolved.variantId, 'arcade');
      expect(resolved.displayName, 'Retro Game Quest · Arcade Cabinet');
      expect(resolved.countdownPresetId, 'gala-elegant');
      expect(resolved.copy[GuestCopyKey.getReady], 'Player one, ready?');
      expect(resolved.copy[GuestCopyKey.readyTitle], 'High score!');
      expect(resolved.soundEnabled, isTrue);
      expect(resolved.soundVolume, 35);
      expect(resolved.animation, AnimationIntensity.off);
      expect(resolved.celebrationPresetId, 'none');
      expect(resolved.cameraStage, CameraStageMode.cameraFocused);
      expect(resolved.childrenMayBeGuests, isTrue);
    });

    test('text that is too long or broken over lines is not shown', () {
      final resolved = registry.resolve(
        EventExperienceConfiguration(
          getReadyText: 'x' * 41,
          finishText: 'Thanks\nfor coming',
        ),
      );
      expect(resolved.copy[GuestCopyKey.getReady], 'Get ready!');
      expect(resolved.copy[GuestCopyKey.readyTitle], 'Your photos are ready!');
      expect(resolved.problems, [
        const ExperienceProblem(
          ExperienceProblemCode.invalidText,
          'getReadyText',
        ),
        const ExperienceProblem(
          ExperienceProblemCode.invalidText,
          'finishText',
        ),
      ]);
    });

    test('a volume out of range is clamped and reported', () {
      final resolved = registry.resolve(
        const EventExperienceConfiguration(soundVolume: 250),
      );
      expect(resolved.soundVolume, 100);
      expect(_codes(resolved.problems), {ExperienceProblemCode.invalidSetting});
    });

    test('a setting the pack locks is ignored and reported', () {
      final locked = _edited(
        registry.pack('midnight-gala')!,
        (json) => json['customizable'] = ['variant'],
      );
      final resolved =
          ExperienceRegistry([
            ...bundledPacks.where((pack) => pack.packId != 'midnight-gala'),
            locked,
          ]).resolve(
            const EventExperienceConfiguration(
              packId: 'midnight-gala',
              accentColor: 0xFFFFFFFF,
            ),
          );
      expect(resolved.problems, [
        const ExperienceProblem(
          ExperienceProblemCode.notCustomizable,
          'accentColor',
        ),
      ]);
    });

    test('the snapshot survives its JSON form', () {
      for (final pack in registry.packs) {
        for (final variant in pack.variants) {
          final resolved = registry.resolve(
            EventExperienceConfiguration(
              packId: pack.packId,
              variantId: variant.id,
            ),
          );
          final again = ResolvedExperience.fromJson(
            jsonDecode(jsonEncode(resolved.toJson())) as Map<String, Object?>,
          );
          expect(again, resolved, reason: '${pack.packId}/${variant.id}');
        }
      }
      expect(
        () => ResolvedExperience.fromJson(const {'schemaVersion': 2}),
        throwsFormatException,
      );
    });
  });

  group('event configuration', () {
    test('survives its JSON form; revision is bookkeeping', () {
      const config = EventExperienceConfiguration(
        packId: 'kid-party-arcade',
        variantId: 'sunny',
        accentColor: 0xFFFFC94D,
        getReadyText: 'Get set!',
        finishText: 'Party on!',
        countdownPresetId: 'party-pop',
        soundEnabled: true,
        soundVolume: 55,
        animation: AnimationIntensity.full,
        celebrationEnabled: false,
        cameraStage: CameraStageMode.cameraFocused,
        recommendedTemplateIds: ['t1', 't2'],
        childrenMayBeGuests: true,
        revision: 4,
      );
      final again = EventExperienceConfiguration.fromJson(
        jsonDecode(jsonEncode(config.toJson())) as Map<String, Object?>,
      );
      expect(again, config);
      expect(again.revision, 4);
      expect(config.copyWith(revision: 9), config);
      expect(
        () => EventExperienceConfiguration.fromJson(const {'schemaVersion': 2}),
        throwsFormatException,
      );
      expect(
        () => EventExperienceConfiguration.fromJson(const {
          'schemaVersion': 1,
          'packId': 3,
        }),
        throwsFormatException,
      );
    });

    test('reset keeps the pack, template links and children setting', () {
      const config = EventExperienceConfiguration(
        packId: 'storybook-garden',
        accentColor: 0xFF123456,
        getReadyText: 'Hello',
        soundEnabled: true,
        recommendedTemplateIds: ['t1'],
        childrenMayBeGuests: true,
      );
      expect(
        config.resetToPackDefaults(),
        const EventExperienceConfiguration(
          packId: 'storybook-garden',
          recommendedTemplateIds: ['t1'],
          childrenMayBeGuests: true,
        ),
      );
    });

    test('switching pack drops the old look and keeps event choices', () {
      const config = EventExperienceConfiguration(
        variantId: 'darkroom',
        accentColor: 0xFF123456,
        countdownPresetId: 'gala-elegant',
        getReadyText: 'Ready?',
        cameraStage: CameraStageMode.cameraFocused,
        childrenMayBeGuests: true,
      );
      final switched = config.switchPack('retro-film', 1);
      expect(switched.packId, 'retro-film');
      expect(switched.variantId, isNull);
      expect(switched.accentColor, isNull);
      expect(switched.countdownPresetId, isNull);
      expect(switched.getReadyText, 'Ready?');
      expect(switched.cameraStage, CameraStageMode.cameraFocused);
      expect(switched.childrenMayBeGuests, isTrue);
    });

    test('each appearance maps to a pack and back', () {
      for (final profile in PorcelainThemeProfile.values) {
        final config = ExperienceRegistry.forAppearance(profile);
        expect(registry.resolve(config).problems, isEmpty);
        expect(ExperienceRegistry.legacyAppearance(config), profile);
      }
      expect(
        ExperienceRegistry.legacyAppearance(
          const EventExperienceConfiguration(packId: 'disco-nights'),
        ),
        isNull,
      );
    });

    test('the schema v8 migration writes what forAppearance gives', () {
      EventExperienceConfiguration read(String json) =>
          EventExperienceConfiguration.fromJson(
            jsonDecode(json) as Map<String, Object?>,
          );
      expect(
        read(v8PorcelainExperience),
        ExperienceRegistry.forAppearance(PorcelainThemeProfile.porcelainStudio),
      );
      expect(
        read(v8VintageOakExperience),
        ExperienceRegistry.forAppearance(PorcelainThemeProfile.lightOak),
      );
      expect(
        read(v8DarkroomExperience),
        ExperienceRegistry.forAppearance(PorcelainThemeProfile.darkroomWalnut),
      );
    });

    test('each mapped pack keeps its appearance canvas and ink', () {
      for (final profile in PorcelainThemeProfile.values) {
        final palette = registry
            .resolve(ExperienceRegistry.forAppearance(profile))
            .palette;
        final colors = PorcelainPalettes.of(profile);
        expect(
          palette[PaletteRole.backdrop],
          colors.canvas.toARGB32(),
          reason: profile.name,
        );
        expect(
          palette[PaletteRole.ink],
          colors.ink.toARGB32(),
          reason: profile.name,
        );
      }
    });
  });

  test('every bundled id is in the catalog', () {
    for (final pack in registry.packs) {
      expect(ExperienceCatalog.layouts, contains(pack.layoutPresetId));
      expect(ExperienceCatalog.countdowns, contains(pack.countdownPresetId));
      expect(ExperienceCatalog.fonts, contains(pack.typography.display));
    }
    expect(ExperienceCatalog.countdowns, hasLength(9));
  });
}
