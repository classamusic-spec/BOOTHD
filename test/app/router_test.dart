// AC-0203: Studio navigation works; every enabled control does what it says.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/design_system/appearance.dart';
import 'package:porcelain_photo_booth/core/design_system/porcelain_theme.dart';
import 'package:porcelain_photo_booth/core/design_system/theme_profiles.dart';
import 'package:porcelain_photo_booth/core/routing/route_paths.dart';
import 'package:porcelain_photo_booth/features/booth/guest_preview_screen.dart';
import 'package:porcelain_photo_booth/features/dashboard/dashboard_screen.dart';
import 'package:porcelain_photo_booth/features/diagnostics/component_gallery_screen.dart';
import 'package:porcelain_photo_booth/features/diagnostics/diagnostics_screen.dart';
import 'package:porcelain_photo_booth/features/diagnostics/spikes/render_spike_screen.dart';
import 'package:porcelain_photo_booth/features/events/events_screen.dart';
import 'package:porcelain_photo_booth/features/gallery/gallery_screen.dart';
import 'package:porcelain_photo_booth/features/settings/settings_screen.dart';
import 'package:porcelain_photo_booth/features/template_library/template_library_screen.dart';
import 'package:porcelain_photo_booth/shared/guest/guest_welcome.dart';

import '../support/app_harness.dart';
import '../support/tablet_viewports.dart';

PorcelainTheme themeOf(WidgetTester tester) =>
    PorcelainTheme.of(tester.element(find.byType(Scaffold).first));

/// Scrolls [finder] into view, then taps it.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Taps a Studio section in the sidebar or rail.
Future<void> openSection(WidgetTester tester, String label) async {
  await tester.tap(find.bySemanticsLabel(label).first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('starts on the Studio dashboard', (tester) async {
    useViewport(tester, TabletViewport.ipadLandscape);
    await pumpApp(tester);
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.text('Set up your first event'), findsOneWidget);
  });

  testWidgets('the navigation opens every Studio section', (tester) async {
    for (final viewport in [
      TabletViewport.ipadLandscape,
      TabletViewport.ipadPortrait,
    ]) {
      useViewport(tester, viewport);
      await pumpApp(tester);
      for (final (label, screen) in [
        ('Events', EventsScreen),
        ('Templates', TemplateLibraryScreen),
        ('Gallery', GalleryScreen),
        ('Settings', SettingsScreen),
        ('Diagnostics', DiagnosticsScreen),
        ('Dashboard', DashboardScreen),
      ]) {
        await openSection(tester, label);
        expect(find.byType(screen), findsOneWidget, reason: viewport.name);
      }
    }
  });

  testWidgets('sections keep their state when you switch away and back', (
    tester,
  ) async {
    useViewport(tester, TabletViewport.ipadLandscape);
    await pumpApp(tester, location: RoutePaths.events);
    await tester.tap(find.text('Drafts'));
    await tester.pumpAndSettle();
    expect(find.text('No drafts'), findsOneWidget);
    await openSection(tester, 'Templates');
    await openSection(tester, 'Events');
    expect(find.text('No drafts'), findsOneWidget);
  });

  testWidgets('dashboard cards open their sections', (tester) async {
    useViewport(tester, TabletViewport.ipadLandscape);
    await pumpApp(tester);
    await tapVisible(tester, find.text('Page formats and designs'));
    expect(find.byType(TemplateLibraryScreen), findsOneWidget);
    expect(find.text('Page formats'), findsOneWidget);
  });

  testWidgets('Start Booth stays disabled and says why when tapped', (
    tester,
  ) async {
    useViewport(tester, TabletViewport.ipadLandscape);
    await pumpApp(tester);
    await tester.tap(find.text('Start Booth'));
    await tester.pump();
    // Shown inline and, after the tap, as a toast.
    expect(find.text(DashboardScreen.startBoothReason), findsNWidgets(2));
    expect(find.byType(GuestWelcome), findsOneWidget, reason: 'miniature');
    expect(find.byType(GuestPreviewScreen), findsNothing);
  });

  testWidgets('the guest preview opens full size and closes again', (
    tester,
  ) async {
    useViewport(tester, TabletViewport.ipadPortrait);
    await pumpApp(tester);
    await tester.tap(find.text('Guest preview'));
    await tester.pumpAndSettle();
    expect(find.byType(GuestPreviewScreen), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Start').last);
    await tester.pump();
    expect(find.text(GuestPreviewScreen.startMessage), findsOneWidget);

    await tester.tap(find.text('Close preview'));
    await tester.pumpAndSettle();
    expect(find.byType(GuestPreviewScreen), findsNothing);
    expect(find.byType(DashboardScreen), findsOneWidget);
  });

  testWidgets('settings: two panes in landscape, one at a time in portrait', (
    tester,
  ) async {
    useViewport(tester, TabletViewport.ipadLandscape);
    await pumpApp(tester, location: RoutePaths.settings);
    expect(find.text('Theme'), findsOneWidget, reason: 'Appearance by default');
    await tester.tap(find.text('About').first);
    await tester.pumpAndSettle();
    expect(find.text('Open licences'), findsOneWidget);

    useViewport(tester, TabletViewport.ipadPortrait);
    await pumpApp(tester, location: RoutePaths.settings);
    expect(find.text('Theme'), findsNothing, reason: 'list only');
    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();
    expect(find.text('Theme'), findsOneWidget);
    await tester.tap(find.text('All settings'));
    await tester.pumpAndSettle();
    expect(find.text('Theme'), findsNothing);
    expect(find.text('Booth and security'), findsOneWidget);
  });

  testWidgets('rotating keeps the open settings section', (tester) async {
    useViewport(tester, TabletViewport.ipadLandscape);
    await pumpApp(tester, location: RoutePaths.settingsSection('about'));
    expect(find.text('Open licences'), findsOneWidget);
    useViewport(tester, TabletViewport.ipadPortrait);
    await tester.pumpAndSettle();
    expect(find.text('Open licences'), findsOneWidget);
    expect(find.text('All settings'), findsOneWidget);
  });

  testWidgets('the licence page opens from About', (tester) async {
    useViewport(tester, TabletViewport.ipadLandscape);
    await pumpApp(tester, location: RoutePaths.settingsSection('about'));
    await tester.tap(find.text('Open licences'));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
  });

  group('appearance', () {
    testWidgets('a theme is previewed first, applied only on request', (
      tester,
    ) async {
      useViewport(tester, TabletViewport.ipadLandscape);
      await pumpApp(tester, location: RoutePaths.settings);
      expect(themeOf(tester).profile, PorcelainThemeProfile.porcelainStudio);

      await tapVisible(tester, find.text('Darkroom Walnut'));
      expect(
        themeOf(tester).profile,
        PorcelainThemeProfile.porcelainStudio,
        reason: 'previewing changes nothing yet',
      );

      await tapVisible(tester, find.text('Cancel preview'));
      expect(find.text('Apply Porcelain Studio'), findsOneWidget);

      await tapVisible(tester, find.text('Light Oak'));
      await tapVisible(tester, find.text('Apply Light Oak'));
      expect(themeOf(tester).profile, PorcelainThemeProfile.lightOak);
      expect(find.text('Light Oak is now in use.'), findsOneWidget);
    });

    testWidgets('contrast and motion preferences apply immediately', (
      tester,
    ) async {
      useViewport(tester, TabletViewport.ipadLandscape);
      await pumpApp(tester, location: RoutePaths.settings);
      await tapVisible(tester, find.text('High'));
      expect(themeOf(tester).highContrast, isTrue);

      await tapVisible(tester, find.text('Reduce motion'));
      final context = tester.element(find.byType(Scaffold).first);
      expect(MediaQuery.disableAnimationsOf(context), isTrue);
    });

    testWidgets('the platform high-contrast setting is followed by default', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(highContrast: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      useViewport(tester, TabletViewport.ipadLandscape);
      await pumpApp(tester);
      expect(themeOf(tester).highContrast, isTrue);
    });

    testWidgets('an operator can override the platform contrast setting', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(highContrast: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      useViewport(tester, TabletViewport.ipadLandscape);
      await pumpApp(
        tester,
        appearance: const AppearanceSettings(
          contrast: ContrastPreference.standard,
        ),
      );
      expect(themeOf(tester).highContrast, isFalse);
    });
  });

  testWidgets('unknown locations get a detail-free fallback with a way back', (
    tester,
  ) async {
    useViewport(tester, TabletViewport.ipadLandscape);
    await pumpApp(tester, location: '/no-such-page');
    expect(find.text("This page isn't available"), findsOneWidget);
    expect(find.textContaining('no-such-page'), findsNothing);
    expect(find.textContaining('Exception'), findsNothing);
    await tester.tap(find.text('Return to Studio'));
    await tester.pumpAndSettle();
    expect(find.byType(DashboardScreen), findsOneWidget);
  });

  testWidgets('debug builds reach the developer tools from Diagnostics', (
    tester,
  ) async {
    useViewport(tester, TabletViewport.ipadLandscape);
    await pumpApp(tester, location: RoutePaths.diagnostics);
    await tapVisible(tester, find.text('Render spike'));
    expect(find.byType(RenderSpikeScreen), findsOneWidget);

    routerOf(tester).go(RoutePaths.componentGallery);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(ComponentGalleryScreen), findsOneWidget);
  });

  testWidgets('release builds have no developer tools or routes', (
    tester,
  ) async {
    useViewport(tester, TabletViewport.ipadLandscape);
    await pumpApp(
      tester,
      location: RoutePaths.diagnostics,
      environment: releaseIpad,
    );
    expect(find.text('Developer tools'), findsNothing);
    expect(find.text('Render spike'), findsNothing);
    for (final path in [
      RoutePaths.renderSpike,
      RoutePaths.cameraSpike,
      RoutePaths.componentGallery,
    ]) {
      routerOf(tester).go(path);
      await tester.pumpAndSettle();
      expect(find.text("This page isn't available"), findsOneWidget);
    }
  });
}
