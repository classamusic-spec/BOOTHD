import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Logical tablet viewports for layout tests. Replace or extend them with
/// the certified devices' sizes once hardware is chosen (UX-08, T-04).
enum TabletViewport {
  ipadPortrait(Size(820, 1180)),
  ipadLandscape(Size(1180, 820)),
  androidPortrait(Size(800, 1280)),
  androidLandscape(Size(1280, 800)),
  compactTabletPortrait(Size(600, 960)),
  compactTabletLandscape(Size(960, 600));

  const TabletViewport(this.logicalSize);

  final Size logicalSize;
}

/// Sizes the test view to [viewport] at 2x density until the test ends.
void useViewport(WidgetTester tester, TabletViewport viewport) {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = viewport.logicalSize * 2;
  addTearDown(tester.view.reset);
}
