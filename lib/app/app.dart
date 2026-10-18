import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design_system/appearance.dart';
import '../core/design_system/porcelain_motion.dart';
import '../core/design_system/porcelain_theme_data.dart';
import '../core/platform/app_info.dart';
import 'providers.dart';

/// Root widget: Porcelain theme, accessibility preferences and router.
///
/// The operator's appearance choices (S17) select the theme profile and may
/// force high contrast or reduced motion; the platform's own accessibility
/// settings always apply too.
class PorcelainApp extends ConsumerWidget {
  const PorcelainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(appearanceProvider);
    final profile = appearance.profile;
    final standard = porcelainThemeData(profile);
    final high = porcelainThemeData(profile, highContrast: true);
    final platformReducesMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final reduceMotion = appearance.reduceMotion(
      platformReducesMotion: platformReducesMotion,
    );

    return MaterialApp.router(
      title: AppInfo.name,
      debugShowCheckedModeBanner: false,
      // Light and dark profiles both arrive through `theme`; MaterialApp
      // switches to `highContrastTheme` when the platform asks for more
      // contrast, unless the operator chose a fixed contrast.
      themeMode: ThemeMode.light,
      theme: appearance.contrast == ContrastPreference.high ? high : standard,
      highContrastTheme: appearance.contrast == ContrastPreference.standard
          ? standard
          : high,
      themeAnimationDuration: reduceMotion
          ? Duration.zero
          : PorcelainMotion.regular.emphasized,
      builder: (context, child) {
        if (appearance.motion != MotionPreference.reduced) return child!;
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        );
      },
      routerConfig: ref.watch(routerProvider),
    );
  }
}
