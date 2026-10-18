// AC-0201 (semantic tokens, no colour scattering), AC-0206 (profiles share
// one token shape) and AC-0211 (one licensed icon family behind semantic
// names).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/design_system/porcelain_theme.dart';
import 'package:porcelain_photo_booth/core/design_system/porcelain_theme_data.dart';
import 'package:porcelain_photo_booth/core/design_system/porcelain_typography.dart';
import 'package:porcelain_photo_booth/core/design_system/theme_profiles.dart';

/// Dart sources under [dir], except the M01 developer spike, which draws
/// test fixtures with literal pixel colours and is removed in M04/M06.
List<File> _sources(String dir) =>
    Directory(dir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.replaceAll(r'\', '/').contains('/spikes/'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

/// Raw colour constructors and palette constants; `Colors.transparent` is
/// not a colour choice and is allowed.
final _rawColour = RegExp(
  r'Color\(0x|Color\.fromARGB|Color\.fromRGBO|Color\.from\(|Colors\.(?!transparent\b)',
);

void main() {
  test('features and shared widgets use tokens, never raw colours', () {
    final offenders = <String>[];
    for (final file in [
      ..._sources('lib/features'),
      ..._sources('lib/shared'),
    ]) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (_rawColour.hasMatch(lines[i])) {
          offenders.add('${file.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('the raw-colour rule catches literals (mutation guard)', () {
    expect(_rawColour.hasMatch('color: Color(0xFF123456),'), isTrue);
    expect(_rawColour.hasMatch('color: Colors.red,'), isTrue);
    expect(_rawColour.hasMatch('color: Colors.transparent,'), isFalse);
  });

  test('only PorcelainIcons imports the icon font package', () {
    final importers = [
      for (final file in _sources('lib'))
        if (file.readAsStringSync().contains('package:material_symbols_icons'))
          file.path.replaceAll(r'\', '/'),
    ];
    expect(importers, ['lib/core/design_system/porcelain_icons.dart']);
  });

  test('serif type is never set below 26 logical pixels', () {
    final type = PorcelainTheme.fallback.text;
    final styles = {
      'displayLarge': type.displayLarge,
      'displayMedium': type.displayMedium,
      'displaySmall': type.displaySmall,
      'headlineLarge': type.headlineLarge,
      'headlineMedium': type.headlineMedium,
      'headlineSmall': type.headlineSmall,
      'titleLarge': type.titleLarge,
      'titleMedium': type.titleMedium,
      'titleSmall': type.titleSmall,
      'bodyLarge': type.bodyLarge,
      'bodyMedium': type.bodyMedium,
      'bodySmall': type.bodySmall,
      'labelLarge': type.labelLarge,
      'labelMedium': type.labelMedium,
      'labelSmall': type.labelSmall,
      'eyebrow': type.eyebrow,
      'numeric': type.numeric,
      'guestDisplay': type.guestDisplay,
      'guestTitle': type.guestTitle,
      'guestBody': type.guestBody,
      'guestLabel': type.guestLabel,
      'guestAction': type.guestAction,
      'guestCaption': type.guestCaption,
      'countdown': type.countdown,
    };
    for (final MapEntry(key: name, value: style) in styles.entries) {
      expect(
        style.fontFamily,
        anyOf(PorcelainFonts.serif, PorcelainFonts.sans),
        reason: name,
      );
      if (style.fontFamily == PorcelainFonts.serif) {
        expect(style.fontSize, greaterThanOrEqualTo(26), reason: name);
      }
    }
    expect(
      type.numeric.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });

  for (final profile in PorcelainThemeProfile.values) {
    test('${profile.name} builds a complete ThemeData', () {
      for (final highContrast in [false, true]) {
        final data = porcelainThemeData(profile, highContrast: highContrast);
        final tokens = data.extension<PorcelainTheme>()!;
        expect(tokens.profile, profile);
        expect(tokens.highContrast, highContrast);
        expect(data.scaffoldBackgroundColor, tokens.colors.canvas);
        expect(data.colorScheme.brightness, tokens.colors.brightness);
        final body = data.textTheme.bodyLarge!;
        expect(body.fontFamily, tokens.text.bodyLarge.fontFamily);
        expect(body.fontSize, tokens.text.bodyLarge.fontSize);
        expect(body.color, tokens.colors.ink);
        // Built once per profile and contrast.
        expect(
          identical(
            data,
            porcelainThemeData(profile, highContrast: highContrast),
          ),
          isTrue,
        );
      }
    });
  }

  test('profiles interpolate, so theme changes can animate', () {
    final from = PorcelainTheme.resolve(PorcelainThemeProfile.porcelainStudio);
    final to = PorcelainTheme.resolve(PorcelainThemeProfile.darkroomWalnut);
    final mid = from.lerp(to, 0.5);
    expect(
      mid.colors.canvas,
      Color.lerp(from.colors.canvas, to.colors.canvas, 0.5),
    );
    expect(from.lerp(to, 0).profile, PorcelainThemeProfile.porcelainStudio);
    expect(from.lerp(to, 1).profile, PorcelainThemeProfile.darkroomWalnut);
    expect(from.lerp(to, 1).colors.canvas, to.colors.canvas);
  });

  testWidgets('widgets without a Porcelain theme fall back to Porcelain '
      'Studio', (tester) async {
    late PorcelainTheme seen;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          seen = context.porcelain;
          return const SizedBox();
        },
      ),
    );
    expect(seen.profile, PorcelainThemeProfile.porcelainStudio);
  });
}
