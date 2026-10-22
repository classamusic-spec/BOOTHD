import 'package:flutter/widgets.dart';

import '../../domain/experience/experience_catalog.dart';
import '../../domain/experience/experience_configuration.dart';
import '../../domain/experience/experience_pack.dart';
import '../../domain/experience/experience_registry.dart';

/// The bundled guest font families (licences: `docs/ASSET_PROVENANCE.md`),
/// by the font ids packs use (`ExperienceCatalog.fonts`).
abstract final class GuestFonts {
  static const _families = {
    'inter': 'Inter',
    'cormorant': 'Cormorant Garamond',
    'courier-prime': 'Courier Prime',
    'monoton': 'Monoton',
    'fredoka': 'Fredoka',
    'poiret-one': 'Poiret One',
    'pixelify-sans': 'Pixelify Sans',
  };

  /// Families shipped as variable fonts: weight is set through the `wght`
  /// axis, not by picking a file.
  static const _variable = {'fredoka', 'pixelify-sans'};

  /// Display-only faces: decorative, never used for running text or
  /// small labels.
  static const displayOnly = {'monoton', 'poiret-one'};

  /// The Flutter family for [id]; Inter for anything unknown.
  static String family(String id) => _families[id] ?? 'Inter';

  /// A style in font [id] at [weight], with the variable axis set where
  /// the font needs it.
  static TextStyle style(String id, {FontWeight weight = FontWeight.w500}) =>
      TextStyle(
        fontFamily: family(id),
        fontWeight: weight,
        fontVariations: _variable.contains(id)
            ? [FontVariation.weight(weight.value.toDouble())]
            : null,
      );
}

/// Everything a guest screen needs to look like its pack (EP02): colours
/// from the resolved palette, the pack's type, button family and touch
/// size. Built from the session's frozen [ResolvedExperience], so it never
/// changes during a session.
@immutable
final class GuestTokens {
  GuestTokens._(this.experience)
    : backdrop = _color(experience, PaletteRole.backdrop),
      backdropAccent = _color(experience, PaletteRole.backdropAccent),
      panel = _color(experience, PaletteRole.panel),
      panelEdge = _color(experience, PaletteRole.panelEdge),
      ink = _color(experience, PaletteRole.ink),
      inkMuted = _color(experience, PaletteRole.inkMuted),
      accent = _color(experience, PaletteRole.accent),
      onAccent = _color(experience, PaletteRole.onAccent),
      accentEdge = _color(experience, PaletteRole.accentEdge),
      highlight = _color(experience, PaletteRole.highlight),
      decorationA = _color(experience, PaletteRole.decorationA),
      decorationB = _color(experience, PaletteRole.decorationB);

  factory GuestTokens.of(ResolvedExperience experience) =>
      _cache[experience] ??= GuestTokens._(experience);

  static final _cache = Expando<GuestTokens>('guest tokens');

  static Color _color(ResolvedExperience e, PaletteRole role) =>
      Color(e.palette[role]);

  final ResolvedExperience experience;

  /// The guest canvas and its second tone (gradients, vignettes).
  final Color backdrop;
  final Color backdropAccent;

  /// Cards, secondary buttons and panels, and their edge.
  final Color panel;
  final Color panelEdge;

  /// Text: [ink] on [backdrop] and [panel], [inkMuted] on [panel] (pack
  /// validation keeps both at 4.5:1 or more).
  final Color ink;
  final Color inkMuted;

  /// Primary actions; [onAccent] is readable on [accent] (4.5:1 or more).
  final Color accent;
  final Color onAccent;
  final Color accentEdge;

  /// Glints and rim light.
  final Color highlight;

  /// Decorative art only; carries no information.
  final Color decorationA;
  final Color decorationB;

  GuestButtonStyle get buttonStyle => experience.buttonStyle;

  /// Guest controls are never smaller than this (72 or more).
  double get minTouchTarget => experience.minTouchTarget;

  String get displayFont => experience.typography.display;
  String get bodyFont => experience.typography.body;

  /// Headings and the big words: the pack's display face.
  TextStyle display(double size, {FontWeight weight = FontWeight.w600}) =>
      GuestFonts.style(
        displayFont,
        weight: weight,
      ).copyWith(fontSize: size, height: 1.12, color: ink);

  /// Running text and labels: the pack's body face, never a display-only
  /// one.
  TextStyle body(double size, {FontWeight weight = FontWeight.w500}) =>
      GuestFonts.style(
        GuestFonts.displayOnly.contains(bodyFont) ? 'inter' : bodyFont,
        weight: weight,
      ).copyWith(fontSize: size, height: 1.3, color: ink);

  /// Button labels: the body face, or the display face when a pack's
  /// buttons are part of its look (pixel and party buttons).
  TextStyle buttonLabel(double size) {
    final font = switch (buttonStyle) {
      GuestButtonStyle.retroGame || GuestButtonStyle.toyArcade
          when !GuestFonts.displayOnly.contains(displayFont) =>
        displayFont,
      _ => GuestFonts.displayOnly.contains(bodyFont) ? 'inter' : bodyFont,
    };
    return GuestFonts.style(
      font,
      weight: FontWeight.w600,
    ).copyWith(fontSize: size, height: 1.1);
  }
}

/// Provides the guest experience to the guest screens below it (EP02):
/// the session's frozen snapshot, or the event's while no session runs.
/// Screens without one get Porcelain Classic, so nothing ever breaks for
/// want of an experience.
class GuestExperience extends InheritedWidget {
  GuestExperience({super.key, required this.experience, required super.child})
    : tokens = GuestTokens.of(experience);

  final ResolvedExperience experience;
  final GuestTokens tokens;

  /// Porcelain Classic, as an event with no choices gets it.
  static final fallback = ExperienceRegistry.bundled.resolve(
    const EventExperienceConfiguration(),
  );

  static GuestExperience? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GuestExperience>();

  /// The experience in effect here.
  static ResolvedExperience experienceOf(BuildContext context) =>
      maybeOf(context)?.experience ?? fallback;

  /// The tokens in effect here.
  static GuestTokens tokensOf(BuildContext context) =>
      maybeOf(context)?.tokens ?? GuestTokens.of(fallback);

  /// How much may move here: the pack's (or operator's) intensity, off
  /// whenever the tablet or the operator asks for reduced motion.
  static AnimationIntensity motionOf(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      return AnimationIntensity.off;
    }
    return experienceOf(context).animation;
  }

  @override
  bool updateShouldNotify(GuestExperience old) => old.experience != experience;
}
