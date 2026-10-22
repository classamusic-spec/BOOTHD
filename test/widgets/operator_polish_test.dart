// EP02 operator polish: the dashboard reports what the tablet says about
// its camera and free space (no stale "arrives in M06" text), and the
// Studio material is decoration only: never hit-tested or read out.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porcelain_photo_booth/core/design_system/porcelain_theme_data.dart';
import 'package:porcelain_photo_booth/core/design_system/theme_profiles.dart';
import 'package:porcelain_photo_booth/domain/services/booth_capabilities.dart';
import 'package:porcelain_photo_booth/shared/widgets/studio_material.dart';

import '../support/app_harness.dart';
import '../support/fakes.dart';
import '../support/simulated_camera.dart';
import '../support/tablet_viewports.dart';

void main() {
  for (final (status, label, detail) in [
    (
      const CapabilityReady(),
      'Ready',
      "Camera allowed, and the booth's default lens is on this tablet.",
    ),
    (
      const CapabilityProblem('CAMERA_PERMISSION_NOT_ASKED'),
      'Not asked yet',
      'The tablet asks for the camera the first time the launch checks or '
          'the camera test run.',
    ),
    (
      const CapabilityProblem('CAMERA_PERMISSION_DENIED'),
      'Not allowed',
      "Allow the camera for this app in the tablet's Settings "
          '(CAMERA_PERMISSION_DENIED).',
    ),
    (
      const CapabilityProblem('CAMERA_NONE'),
      'No camera',
      'The tablet reports no built-in camera.',
    ),
  ]) {
    testWidgets('the dashboard camera tile says "$label"', (tester) async {
      useViewport(tester, TabletViewport.ipadLandscape);
      await pumpApp(tester, probe: FakeCapabilityProbe(cameraStatus: status));
      await tester.ensureVisible(find.text(detail));
      expect(find.text(label), findsOneWidget);
      expect(find.textContaining('M06'), findsNothing);
    });
  }

  testWidgets('the dashboard storage tile reports free space', (tester) async {
    useViewport(tester, TabletViewport.ipadLandscape);
    await pumpApp(
      tester,
      space: FakeDeviceStorage(free: 2 * 1024 * 1024 * 1024),
    );
    expect(
      find.textContaining('2.0 GB free, room for about 51 guest sessions.'),
      findsOneWidget,
    );
  });

  for (final profile in PorcelainThemeProfile.values) {
    testWidgets('the ${profile.name} material is decoration only', (
      tester,
    ) async {
      var taps = 0;
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          theme: porcelainThemeData(profile),
          home: Scaffold(
            body: StudioMaterial(
              area: StudioMaterialArea.canvas,
              child: Center(
                child: TextButton(
                  onPressed: () => taps++,
                  child: const Text('Under the grain'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Under the grain'));
      expect(taps, 1);
      expect(
        find.descendant(
          of: find.byType(StudioMaterial),
          matching: find.byType(ExcludeSemantics),
        ),
        findsWidgets,
      );
      expect(find.bySemanticsLabel('Under the grain'), findsOneWidget);
      semantics.dispose();
    });
  }
}
