import 'package:flutter/material.dart';

import 'porcelain_metrics.dart';
import 'porcelain_page_transitions.dart';
import 'porcelain_theme.dart';
import 'porcelain_typography.dart';
import 'theme_profiles.dart';

/// [ThemeData] for [profile], built once per profile and contrast variant.
ThemeData porcelainThemeData(
  PorcelainThemeProfile profile, {
  bool highContrast = false,
}) => _cache.putIfAbsent(
  (profile, highContrast),
  () => buildPorcelainThemeData(
    PorcelainTheme.resolve(profile, highContrast: highContrast),
  ),
);

final _cache = <(PorcelainThemeProfile, bool), ThemeData>{};

/// Builds Flutter's [ThemeData] from Porcelain tokens, so the few stock
/// Material widgets in use (licence page, developer spikes, text selection)
/// match the design system. Porcelain widgets read [PorcelainTheme]
/// directly.
ThemeData buildPorcelainThemeData(PorcelainTheme theme) {
  final c = theme.colors;
  final t = theme.text;
  final scheme = ColorScheme(
    brightness: c.brightness,
    primary: c.accentText,
    onPrimary: c.isDark ? c.onPrimary : c.surface,
    primaryContainer: c.primaryTop,
    onPrimaryContainer: c.onPrimary,
    secondary: c.inkMuted,
    onSecondary: c.surface,
    tertiary: c.success,
    onTertiary: c.surface,
    error: c.danger,
    onError: c.isDark ? c.canvas : c.surface,
    errorContainer: c.dangerSurface,
    onErrorContainer: c.danger,
    surface: c.surface,
    onSurface: c.ink,
    onSurfaceVariant: c.inkMuted,
    surfaceContainerLowest: c.raised,
    surfaceContainerLow: c.surface,
    surfaceContainer: c.canvas,
    surfaceContainerHigh: c.rail,
    surfaceContainerHighest: c.inset,
    outline: c.outline,
    outlineVariant: c.divider,
    shadow: c.shadowKey.withValues(alpha: 1),
    scrim: c.scrim,
    inverseSurface: c.ink,
    onInverseSurface: c.canvas,
    inversePrimary: c.primaryTop,
    surfaceTint: Colors.transparent,
  );
  final textTheme = TextTheme(
    displayLarge: t.displayLarge,
    displayMedium: t.displayMedium,
    displaySmall: t.displaySmall,
    headlineLarge: t.headlineLarge,
    headlineMedium: t.headlineMedium,
    headlineSmall: t.headlineSmall,
    titleLarge: t.titleLarge,
    titleMedium: t.titleMedium,
    titleSmall: t.titleSmall,
    bodyLarge: t.bodyLarge,
    bodyMedium: t.bodyMedium,
    bodySmall: t.bodySmall,
    labelLarge: t.labelLarge,
    labelMedium: t.labelMedium,
    labelSmall: t.labelSmall,
  );
  const transitions = PorcelainPageTransitionsBuilder();
  final controlShape = RoundedRectangleBorder(
    borderRadius: PorcelainRadius.controlAll,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: c.brightness,
    colorScheme: scheme,
    fontFamily: PorcelainFonts.sans,
    textTheme: textTheme,
    scaffoldBackgroundColor: c.canvas,
    canvasColor: c.canvas,
    dividerColor: c.divider,
    focusColor: c.focusRing.withValues(alpha: 0.16),
    hoverColor: c.ink.withValues(alpha: 0.04),
    highlightColor: c.ink.withValues(alpha: 0.06),
    splashColor: c.accentIcon.withValues(alpha: 0.12),
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
    extensions: [theme],
    iconTheme: IconThemeData(
      color: c.ink,
      size: PorcelainSize.icon,
      weight: 400,
      opticalSize: 24,
      // Light glyphs on dark backgrounds read heavier; grade compensates.
      grade: c.isDark ? -25 : 0,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.canvas,
      foregroundColor: c.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: t.titleLarge,
    ),
    dividerTheme: DividerThemeData(color: c.divider, thickness: 1, space: 1),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      modalBackgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      modalBarrierColor: c.scrim,
      showDragHandle: true,
      dragHandleColor: c.outline,
      dragHandleSize: const Size(44, 5),
      elevation: 0,
      modalElevation: 0,
      constraints: const BoxConstraints(maxWidth: 720),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(PorcelainRadius.dialog),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      barrierColor: c.scrim,
      shape: const RoundedRectangleBorder(
        borderRadius: PorcelainRadius.dialogAll,
      ),
      titleTextStyle: t.headlineSmall,
      contentTextStyle: t.bodyLarge,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.ink,
      contentTextStyle: t.bodyMedium.copyWith(color: c.canvas),
      elevation: 0,
      shape: controlShape,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: c.ink,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      textStyle: t.labelMedium.copyWith(color: c.canvas),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.accentText,
      selectionColor: c.accentIcon.withValues(alpha: 0.32),
      selectionHandleColor: c.accentText,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: c.accentText,
      linearTrackColor: c.inset,
      circularTrackColor: c.inset,
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStatePropertyAll(c.outline.withValues(alpha: 0.6)),
      radius: const Radius.circular(8),
      thickness: const WidgetStatePropertyAll(6),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: c.inkMuted,
      textColor: c.ink,
      titleTextStyle: t.titleSmall,
      subtitleTextStyle: t.bodyMedium.copyWith(color: c.inkMuted),
      minVerticalPadding: 12,
      shape: controlShape,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.inset,
      labelStyle: t.labelLarge.copyWith(color: c.inkMuted),
      hintStyle: t.bodyLarge.copyWith(color: c.inkMuted),
      helperStyle: t.bodySmall,
      errorStyle: t.bodySmall.copyWith(color: c.danger),
      border: OutlineInputBorder(
        borderRadius: PorcelainRadius.controlAll,
        borderSide: BorderSide(color: c.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: PorcelainRadius.controlAll,
        borderSide: BorderSide(color: c.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: PorcelainRadius.controlAll,
        borderSide: BorderSide(color: c.focusRing, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: PorcelainRadius.controlAll,
        borderSide: BorderSide(color: c.danger),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, PorcelainSize.minTouchTarget),
        shape: const StadiumBorder(),
        textStyle: t.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(64, PorcelainSize.minTouchTarget),
        foregroundColor: c.accentText,
        textStyle: t.labelLarge,
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: transitions,
        TargetPlatform.iOS: transitions,
        TargetPlatform.linux: transitions,
        TargetPlatform.macOS: transitions,
        TargetPlatform.windows: transitions,
        TargetPlatform.fuchsia: transitions,
      },
    ),
  );
}
