// AC-0209: golden screenshots of every implemented screen in portrait and
// landscape at the defined tablet sizes, in every implemented theme.
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
import '../support/tablet_viewports.dart';

const screens = {
  'dashboard': '/studio',
  'events': '/studio/events',
  'templates': '/studio/templates',
  'gallery': '/studio/gallery',
  'settings_appearance': '/studio/settings?section=appearance',
  'settings_camera': '/studio/settings?section=camera',
  'settings_output': '/studio/settings?section=output',
  'settings_booth': '/studio/settings?section=booth',
  'settings_about': '/studio/settings?section=about',
  'diagnostics': '/studio/diagnostics',
  'guest_welcome_preview': '/preview/guest-welcome',
  'not_found': '/no-such-page',
};

/// The default theme at both certified-size candidates; the other profiles
/// at the iPad size.
Map<PorcelainThemeProfile, List<TabletViewport>> get matrix => {
  PorcelainThemeProfile.porcelainStudio: [
    TabletViewport.ipadPortrait,
    TabletViewport.ipadLandscape,
    TabletViewport.androidPortrait,
    TabletViewport.androidLandscape,
  ],
  PorcelainThemeProfile.lightOak: [
    TabletViewport.ipadPortrait,
    TabletViewport.ipadLandscape,
  ],
  PorcelainThemeProfile.darkroomWalnut: [
    TabletViewport.ipadPortrait,
    TabletViewport.ipadLandscape,
  ],
};

final skipOffLinux = !Platform.isLinux;

void main() {
  for (final MapEntry(key: profile, value: viewports) in matrix.entries) {
    for (final MapEntry(key: name, value: location) in screens.entries) {
      for (final viewport in viewports) {
        testWidgets('${profile.name} $name ${viewport.name}', (tester) async {
          useViewport(tester, viewport, pixelRatio: 1);
          await pumpApp(
            tester,
            location: location,
            appearance: AppearanceSettings(profile: profile),
          );
          await expectLater(
            find.byType(PorcelainApp),
            matchesGoldenFile('${profile.name}/${name}_${viewport.name}.png'),
          );
        }, skip: skipOffLinux);
      }
    }

    // The settings list on its own (portrait shows it before a section).
    testWidgets('${profile.name} settings_list ipadPortrait', (tester) async {
      useViewport(tester, TabletViewport.ipadPortrait, pixelRatio: 1);
      await pumpApp(
        tester,
        location: '/studio/settings',
        appearance: AppearanceSettings(profile: profile),
      );
      await expectLater(
        find.byType(PorcelainApp),
        matchesGoldenFile('${profile.name}/settings_list_ipadPortrait.png'),
      );
    }, skip: skipOffLinux);

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
