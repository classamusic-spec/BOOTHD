// AC-0209: golden screenshots of every implemented screen in portrait and
// landscape at the defined tablet sizes, in every implemented theme; M03
// adds first-run setup, the PIN screens, the event list and editor, the
// launch checks and Booth Mode; M05 the template library, the new-template
// chooser, the Template Studio and the template preview.
//
// Rendered at 1x to keep the repository small; text and blur rasterise
// differently on macOS and Windows, so goldens are compared on Linux only
// (CI). Regenerate after an intentional visual change with:
//   flutter test --update-goldens test/goldens/
@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/app/app.dart';
import 'package:porcelain_photo_booth/core/design_system/appearance.dart';
import 'package:porcelain_photo_booth/core/design_system/theme_profiles.dart';

import '../support/app_harness.dart';
import '../support/screen_catalog.dart';
import '../support/tablet_viewports.dart';

/// Screens shown in every theme, in portrait and landscape.
const themed = [
  'dashboard',
  'events',
  'event general',
  'preflight',
  'templates',
  'templates library',
  'template editor',
  'gallery',
  'settings appearance',
  'settings camera',
  'settings output',
  'settings booth',
  'settings about',
  'diagnostics',
  'guest preview',
  'not found',
  'setup welcome',
  'unlock',
];

/// Further states and steps, in the default theme at the iPad size.
const states = [
  'dashboard with events',
  'events empty',
  'event templates',
  'event capture',
  'event guest',
  'event output',
  'event privacy',
  'event draft',
  'event archived',
  'new event',
  'new event templates empty',
  'preflight draft',
  'new template',
  'template editor selected',
  'template editor layers',
  'template preview',
  'setup privacy',
  'setup pin',
  'setup recovery code',
  'setup booth',
  'unlock recovery',
];

/// Booth Mode, guest and operator screens alike, wears the event's theme
/// (the seeded event's is Darkroom Walnut) whatever the Studio's is, so it
/// is shown once per size.
const booth = ['booth welcome', 'booth operator'];

/// The default theme at both certified-size candidates; the other profiles
/// at the iPad size.
Map<PorcelainThemeProfile, List<TabletViewport>> get matrix => {
  PorcelainThemeProfile.porcelainStudio: allSizes,
  PorcelainThemeProfile.lightOak: ipadSizes,
  PorcelainThemeProfile.darkroomWalnut: ipadSizes,
};

const ipadSizes = [TabletViewport.ipadPortrait, TabletViewport.ipadLandscape];

const allSizes = [
  ...ipadSizes,
  TabletViewport.androidPortrait,
  TabletViewport.androidLandscape,
];

final skipOffLinux = !Platform.isLinux;

String fileName(String screen) => screen.replaceAll(' ', '_');

/// A golden of [name] with the Studio in [profile], kept in [directory]
/// (the profile's name by default).
void golden(
  String name,
  PorcelainThemeProfile profile,
  TabletViewport viewport, {
  String? directory,
}) {
  testWidgets('${profile.name} $name ${viewport.name}', (tester) async {
    await show(
      tester,
      name,
      viewport: viewport,
      appearance: AppearanceSettings(profile: profile),
      pixelRatio: 1,
    );
    await expectLater(
      find.byType(PorcelainApp),
      matchesGoldenFile(
        '${directory ?? profile.name}/${fileName(name)}_${viewport.name}.png',
      ),
    );
  }, skip: skipOffLinux);
}

void main() {
  for (final MapEntry(key: profile, value: viewports) in matrix.entries) {
    for (final name in themed) {
      for (final viewport in viewports) {
        golden(name, profile, viewport);
      }
    }

    // The settings list on its own (portrait shows it before a section).
    golden('settings', profile, TabletViewport.ipadPortrait);

    // Every component in every state, on one tall page.
    testWidgets('${profile.name} component gallery', (tester) async {
      useViewport(
        tester,
        TabletViewport.ipadLandscape,
        pixelRatio: 1,
        size: const Size(1180, 3400),
      );
      await pumpApp(
        tester,
        location: '/dev/components',
        appearance: AppearanceSettings(profile: profile),
        settle: false,
      );
      await tester.pump(const Duration(seconds: 1));
      await expectLater(
        find.byType(PorcelainApp),
        matchesGoldenFile('${profile.name}/component_gallery.png'),
      );
    }, skip: skipOffLinux);
  }

  for (final name in states) {
    for (final viewport in ipadSizes) {
      golden(name, PorcelainThemeProfile.porcelainStudio, viewport);
    }
  }

  for (final name in booth) {
    for (final viewport in allSizes) {
      golden(
        name,
        PorcelainThemeProfile.porcelainStudio,
        viewport,
        directory: 'boothMode',
      );
    }
  }

  testWidgets('porcelainStudio high contrast dashboard', (tester) async {
    useViewport(tester, TabletViewport.ipadLandscape, pixelRatio: 1);
    await pumpApp(
      tester,
      appearance: const AppearanceSettings(contrast: ContrastPreference.high),
    );
    await expectLater(
      find.byType(PorcelainApp),
      matchesGoldenFile('porcelainStudio/dashboard_high_contrast.png'),
    );
  }, skip: skipOffLinux);
}
