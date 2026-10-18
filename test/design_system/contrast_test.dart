// AC-0207: automated token-pair contrast test, for every implemented theme
// profile in standard and high contrast. Thresholds are CR-001's.
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/design_system/color_contrast.dart';
import 'package:porcelain_photo_booth/core/design_system/porcelain_colors.dart';
import 'package:porcelain_photo_booth/core/design_system/theme_profiles.dart';
import 'package:porcelain_photo_booth/shared/widgets/tone.dart';

/// One foreground/background pairing that must meet [minimum].
typedef Pair = ({String name, Color fg, Color bg, double minimum});

List<Pair> pairsFor(PorcelainColors c) {
  final pairs = <Pair>[];
  void need(String name, Color fg, Map<String, Color> on, double minimum) {
    for (final MapEntry(key: surface, value: bg) in on.entries) {
      pairs.add((name: '$name on $surface', fg: fg, bg: bg, minimum: minimum));
    }
  }

  final text = c.textSurfaces;
  final controlBackgrounds = {
    'canvas': c.canvas,
    'rail': c.rail,
    'surface': c.surface,
    'raised': c.raised,
  };
  final guestBackgrounds = {'canvas': c.canvas, 'surface': c.surface};
  final pressedGold = Color.lerp(c.primaryBottom, c.primaryEdge, 0.1)!;
  final goldFills = {
    'primaryTop': c.primaryTop,
    'primaryBottom': c.primaryBottom,
    'pressed gold': pressedGold,
  };

  // Text.
  need(
    'ink (primary and guest text)',
    c.ink,
    text,
    ContrastTargets.guestPrimaryText,
  );
  need('inkMuted', c.inkMuted, text, ContrastTargets.text);
  need('accentText', c.accentText, text, ContrastTargets.text);
  need(
    'guestAccentText',
    c.guestAccentText,
    guestBackgrounds,
    ContrastTargets.guestPrimaryText,
  );
  need(
    'onPrimary (guest Start label)',
    c.onPrimary,
    goldFills,
    ContrastTargets.guestPrimaryText,
  );
  need('inkDisabled', c.inkDisabled, {
    'disabledFill': c.disabledFill,
    'canvas': c.canvas,
    'surface': c.surface,
  }, ContrastTargets.disabledText);
  for (final tone in PorcelainTone.values) {
    need('${tone.name} tone text', tone.foreground(c), {
      ...controlBackgrounds,
      '${tone.name} surface': tone.surfaceColor(c),
    }, ContrastTargets.text);
  }

  // Focus rings, control boundaries and meaningful icons.
  need('focusRing', c.focusRing, {
    ...controlBackgrounds,
    'selected': c.selected,
  }, ContrastTargets.nonText);
  need('outline (control boundary)', c.outline, {
    ...controlBackgrounds,
    'disabledFill': c.disabledFill,
  }, ContrastTargets.nonText);
  need('primaryEdge (gilded edge)', c.primaryEdge, {
    ...controlBackgrounds,
    'inset (segment track)': c.inset,
  }, ContrastTargets.nonText);
  need('accentIcon (icons, selection bars)', c.accentIcon, {
    ...controlBackgrounds,
    'selected': c.selected,
  }, ContrastTargets.nonText);
  need(
    'danger (error boundary)',
    c.danger,
    controlBackgrounds,
    ContrastTargets.nonText,
  );
  need(
    'inkMuted (unselected icons)',
    c.inkMuted,
    controlBackgrounds,
    ContrastTargets.nonText,
  );
  return pairs;
}

/// Every pairing of [colors] below its threshold, described.
List<String> contrastFailures(PorcelainColors colors) => [
  for (final pair in pairsFor(colors))
    if (contrastRatio(pair.fg, pair.bg) case final ratio
        when ratio < pair.minimum)
      '${pair.name}: ${ratio.toStringAsFixed(2)} < ${pair.minimum}',
];

void main() {
  test('contrast maths matches WCAG reference values', () {
    expect(
      contrastRatio(const Color(0xFF000000), const Color(0xFFFFFFFF)),
      closeTo(21, 1e-9),
    );
    expect(
      contrastRatio(const Color(0xFF777777), const Color(0xFFFFFFFF)),
      closeTo(4.48, 0.01),
    );
    expect(
      compositeOver(const Color(0x80000000), const Color(0xFFFFFFFF)).r,
      closeTo(0.5, 0.01),
    );
  });

  test('the check catches failing pairs (mutation guard)', () {
    // Halfway between a light and a dark palette, text and surfaces converge.
    final muddy = PorcelainColors.lerp(
      PorcelainPalettes.porcelainStudio,
      PorcelainPalettes.darkroomWalnut,
      0.5,
    );
    expect(contrastFailures(muddy), isNotEmpty);
  });

  for (final profile in PorcelainThemeProfile.values) {
    for (final highContrast in [false, true]) {
      final name = '${profile.name}${highContrast ? ' (high contrast)' : ''}';
      test('$name meets every CR-001 contrast threshold', () {
        final colors = PorcelainPalettes.of(
          profile,
          highContrast: highContrast,
        );
        final failures = contrastFailures(colors);
        expect(failures, isEmpty, reason: failures.join('\n'));
        final lowest = pairsFor(colors)
            .map((pair) => contrastRatio(pair.fg, pair.bg) / pair.minimum)
            .reduce((a, b) => a < b ? a : b);
        final guest = contrastRatio(colors.ink, colors.canvas);
        // Recorded in the test log for docs/ACCEPTANCE_EVIDENCE.md.
        // ignore: avoid_print
        print(
          '$name: ${pairsFor(colors).length} pairs pass; '
          'ink on canvas ${guest.toStringAsFixed(2)}:1, '
          'tightest pair at ${lowest.toStringAsFixed(2)}x its threshold',
        );
      });
    }
  }

  test('viewfinder messages are readable in every theme', () {
    expect(
      contrastRatio(PorcelainViewfinder.ink, PorcelainViewfinder.background),
      greaterThanOrEqualTo(ContrastTargets.guestPrimaryText),
    );
  });

  test('high contrast never lowers contrast', () {
    for (final profile in PorcelainThemeProfile.values) {
      final standard = PorcelainPalettes.of(profile);
      final high = PorcelainPalettes.of(profile, highContrast: true);
      for (final (role, s, h) in [
        ('ink', standard.ink, high.ink),
        ('inkMuted', standard.inkMuted, high.inkMuted),
        ('outline', standard.outline, high.outline),
        ('focusRing', standard.focusRing, high.focusRing),
      ]) {
        expect(
          contrastRatio(h, high.canvas),
          greaterThanOrEqualTo(contrastRatio(s, standard.canvas)),
          reason: '${profile.name} $role',
        );
      }
    }
  });
}
