import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:porcelain_photo_booth/app/app.dart';
import 'package:porcelain_photo_booth/app/providers.dart';
import 'package:porcelain_photo_booth/app/router.dart';
import 'package:porcelain_photo_booth/core/design_system/appearance.dart';
import 'package:porcelain_photo_booth/core/platform/app_environment.dart';
import 'package:porcelain_photo_booth/core/routing/route_paths.dart';

const debugAndroid = AppEnvironment(
  platform: TargetPlatform.android,
  buildMode: BuildMode.debug,
);

const releaseIpad = AppEnvironment(
  platform: TargetPlatform.iOS,
  buildMode: BuildMode.release,
);

/// The whole app at [location], with a fixed environment and appearance.
Future<void> pumpApp(
  WidgetTester tester, {
  String location = RoutePaths.home,
  AppEnvironment environment = debugAndroid,
  AppearanceSettings appearance = const AppearanceSettings(),
  bool settle = true,
}) async {
  final router = buildRouter(
    initialLocation: location,
    devTools: environment.buildMode != BuildMode.release,
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appEnvironmentProvider.overrideWithValue(environment),
        routerProvider.overrideWithValue(router),
        appearanceProvider.overrideWith(() => AppearanceController(appearance)),
      ],
      child: const PorcelainApp(),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

/// The router in use by the app under test.
GoRouter routerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(PorcelainApp)))
        .read(routerProvider);
