// EP02 (AC-EP03, AC-EP05, AC-EP14): one guest button API drawn by six
// families, every state in every family, the guest touch minimum, focus,
// semantics and reduced motion; each pack's fonts and tokens.
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/design_system/porcelain_icons.dart';
import 'package:porcelain_photo_booth/core/design_system/porcelain_theme_data.dart';
import 'package:porcelain_photo_booth/core/design_system/theme_profiles.dart';
import 'package:porcelain_photo_booth/core/experience/guest_experience.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_catalog.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_configuration.dart';
import 'package:porcelain_photo_booth/domain/experience/experience_registry.dart';
import 'package:porcelain_photo_booth/shared/guest/guest_button.dart';
import 'package:porcelain_photo_booth/shared/guest/guest_button_faces.dart';
import 'package:porcelain_photo_booth/shared/widgets/porcelain_spinner.dart';

ResolvedExperience _resolve(String packId, [String? variant]) =>
    ExperienceRegistry.bundled.resolve(
      EventExperienceConfiguration(packId: packId, variantId: variant),
    );

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  ResolvedExperience? experience,
  bool reduceMotion = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: porcelainThemeData(PorcelainThemeProfile.porcelainStudio),
      builder: (context, page) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: page!,
      ),
      home: GuestExperience(
        experience: experience ?? GuestExperience.fallback,
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final style in GuestButtonStyle.values) {
    group('${style.name} family', () {
      testWidgets('taps, presses with travel and releases', (tester) async {
        var taps = 0;
        await _pump(
          tester,
          GuestButton(
            label: 'Start',
            icon: PorcelainIcons.camera,
            style: style,
            onPressed: () => taps++,
          ),
        );
        await tester.tap(
          find.text(style == GuestButtonStyle.gala ? 'START' : 'Start'),
        );
        await tester.pumpAndSettle();
        expect(taps, 1);

        final painter = find.descendant(
          of: find.byType(GuestButton),
          matching: find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is GuestButtonPainter,
          ),
        );
        GuestButtonPainter paint() =>
            tester.widget<CustomPaint>(painter).painter! as GuestButtonPainter;
        expect(paint().look.pressed, isFalse);
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(GuestButton)),
        );
        await tester.pumpAndSettle();
        expect(paint().look.pressed, isTrue);
        expect(paint().press, 1);
        expect(GuestButtonFace.of(style).travel(1), greaterThan(0));
        await gesture.up();
        // The pressed look is held for one press animation at least.
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();
        expect(paint().press, 0);
        expect(taps, 2);
      });

      testWidgets('is at least the guest minimum, at every size', (
        tester,
      ) async {
        for (final size in GuestButtonSize.values) {
          await _pump(
            tester,
            GuestButton(
              label: 'Go',
              style: style,
              size: size,
              onPressed: () {},
            ),
          );
          final box = tester.getSize(find.byType(GuestButton));
          expect(box.height, greaterThanOrEqualTo(72), reason: size.name);
          expect(box.height, greaterThanOrEqualTo(size.height));
          expect(box.width, greaterThanOrEqualTo(72));
        }
      });

      testWidgets('disabled says why and ignores taps', (tester) async {
        const taps = 0;
        final semantics = tester.ensureSemantics();
        await _pump(
          tester,
          GuestButton(
            label: 'Keep these',
            style: style,
            onPressed: null,
            disabledReason: 'Take every photo first.',
          ),
        );
        await tester.tap(find.byType(GuestButton), warnIfMissed: false);
        await tester.pump();
        expect(taps, 0);
        expect(
          tester.getSemantics(find.byType(GuestButton)),
          matchesSemantics(
            label: 'Keep these',
            hint: 'Take every photo first.',
            isButton: true,
            hasEnabledState: true,
          ),
        );
        semantics.dispose();
      });

      testWidgets('busy keeps the label, shows progress and ignores taps', (
        tester,
      ) async {
        var taps = 0;
        await _pump(
          tester,
          GuestButton(
            label: 'Saving',
            style: style,
            busy: true,
            onPressed: () => taps++,
          ),
          reduceMotion: true,
        );
        expect(find.byType(PorcelainSpinner), findsOneWidget);
        await tester.tap(find.byType(GuestButton));
        await tester.pump();
        expect(taps, 0);
      });

      testWidgets('selected shows a mark, not colour alone', (tester) async {
        final semantics = tester.ensureSemantics();
        await _pump(
          tester,
          GuestButton(
            label: 'Classic',
            style: style,
            selected: true,
            onPressed: () {},
          ),
        );
        expect(find.byIcon(PorcelainIcons.check), findsOneWidget);
        expect(
          tester.getSemantics(find.byType(GuestButton)),
          matchesSemantics(
            label: 'Classic',
            isButton: true,
            hasEnabledState: true,
            isEnabled: true,
            hasSelectedState: true,
            isSelected: true,
            hasTapAction: true,
            hasFocusAction: true,
            isFocusable: true,
          ),
        );
        semantics.dispose();
      });

      testWidgets('keyboard focus shows a ring and Enter activates', (
        tester,
      ) async {
        var taps = 0;
        await _pump(
          tester,
          GuestButton(label: 'Retake', style: style, onPressed: () => taps++),
        );
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.alwaysTraditional;
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        final painter = tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .map((w) => w.painter)
            .whereType<GuestButtonPainter>()
            .single;
        expect(painter.look.focused, isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(taps, 1);
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic;
      });
    });
  }

  testWidgets('the family follows the pack in effect', (tester) async {
    for (final (pack, variant, style) in [
      ('porcelain-classic', null, GuestButtonStyle.porcelain),
      ('vintage-oak', null, GuestButtonStyle.wood),
      ('disco-nights', null, GuestButtonStyle.neonParty),
      ('midnight-gala', null, GuestButtonStyle.gala),
      ('kid-party-arcade', null, GuestButtonStyle.toyArcade),
      ('retro-game-quest', 'arcade', GuestButtonStyle.retroGame),
    ]) {
      final experience = _resolve(pack, variant);
      expect(experience.buttonStyle, style, reason: pack);
      await _pump(
        tester,
        GuestButton(label: 'Start', onPressed: () {}),
        experience: experience,
      );
      final painter = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((w) => w.painter)
          .whereType<GuestButtonPainter>()
          .single;
      expect(painter.face.runtimeType, GuestButtonFace.of(style).runtimeType);
    }
  });

  testWidgets('without an experience the booth falls back to Porcelain', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GuestButton(label: 'Start', onPressed: () {}),
          ),
        ),
      ),
    );
    final painter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((w) => w.painter)
        .whereType<GuestButtonPainter>()
        .single;
    expect(painter.face, isA<PorcelainFace>());
    expect(painter.tokens.experience.packId, 'porcelain-classic');
  });

  testWidgets('reduced motion presses instantly', (tester) async {
    await _pump(
      tester,
      GuestButton(label: 'Start', onPressed: () {}),
      reduceMotion: true,
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(GuestButton)),
    );
    await tester.pump();
    final painter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((w) => w.painter)
        .whereType<GuestButtonPainter>()
        .single;
    expect(painter.press, 1, reason: 'no in-between frames');
    await gesture.up();
  });

  group('tokens', () {
    test('every pack and variant maps to bundled fonts', () {
      const families = {
        'Inter',
        'Cormorant Garamond',
        'Courier Prime',
        'Monoton',
        'Fredoka',
        'Poiret One',
        'Pixelify Sans',
      };
      for (final id in ExperienceCatalog.fonts) {
        expect(families, contains(GuestFonts.family(id)), reason: id);
      }
      for (final pack in ExperienceRegistry.bundled.packs) {
        for (final variant in pack.variants) {
          final tokens = GuestTokens.of(_resolve(pack.packId, variant.id));
          expect(
            GuestFonts.displayOnly,
            isNot(contains(tokens.body(20).fontFamily)),
            reason: '${pack.packId}: running text in a display face',
          );
          expect(tokens.minTouchTarget, greaterThanOrEqualTo(72));
        }
      }
    });

    test('variable fonts get their weight axis', () {
      final style = GuestFonts.style('fredoka', weight: FontWeight.w600);
      expect(style.fontFamily, 'Fredoka');
      expect(style.fontVariations, [const FontVariation.weight(600)]);
      expect(GuestFonts.style('inter').fontVariations, isNull);
      expect(GuestFonts.family('comic-sans'), 'Inter');
    });

    test('button text is readable on every face fill (4.5:1)', () {
      for (final pack in ExperienceRegistry.bundled.packs) {
        for (final variant in pack.variants) {
          final t = GuestTokens.of(_resolve(pack.packId, variant.id));
          for (final style in GuestButtonStyle.values) {
            final face = GuestButtonFace.of(style);
            for (final primary in [true, false]) {
              for (final enabled in [true, false]) {
                final look = GuestButtonLook(
                  enabled: enabled,
                  pressed: false,
                  focused: false,
                  primary: primary,
                  selected: false,
                );
                expect(
                  contrastRatio(
                    face.ink(t, look).toARGB32(),
                    face.fill(t, look).toARGB32(),
                  ),
                  greaterThanOrEqualTo(4.5),
                  reason:
                      '${pack.packId}/${variant.id} ${style.name} '
                      'primary=$primary enabled=$enabled',
                );
              }
            }
          }
        }
      }
    });
  });

  test('render objects stay finite with tiny sizes', () {
    // Faces must not throw for a degenerate rectangle (layout in progress).
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final t = GuestTokens.of(GuestExperience.fallback);
    for (final style in GuestButtonStyle.values) {
      GuestButtonFace.of(style).paint(
        canvas,
        Rect.zero,
        t,
        const GuestButtonLook(
          enabled: true,
          pressed: false,
          focused: true,
          primary: true,
          selected: true,
        ),
        0.5,
      );
    }
    recorder.endRecording().dispose();
  });
}
