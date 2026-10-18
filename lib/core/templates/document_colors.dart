/// Colours that belong to template documents rather than to the app's
/// theme: the paper a page prints on, and the swatches the inspector
/// offers (S10). Changing the app theme never changes these (UX-02).
library;

import 'dart:ui' show Color;

import '../../domain/template/template_assets.dart';

/// Exports flatten onto white paper (JPEG has no transparency), so the
/// editor shows the page on white too.
const paperColor = Color(0xFFFFFFFF);

/// Document colours new layers and fills start with.
abstract final class DocumentPalette {
  static const white = ArgbColor(0xFFFFFFFF);
  static const ivory = ArgbColor(0xFFFBF8F3);
  static const gold = ArgbColor(0xFFB8955F);
  static const champagnePaper = ArgbColor(0xFFFBF6EC);
  static const champagneDeep = ArgbColor(0xFFEFE2C8);
}

/// A named colour for template layers.
final class TemplateSwatch {
  const TemplateSwatch(this.name, this.color);

  final String name;
  final ArgbColor color;
}

/// The Porcelain palette for templates: paper tones, champagne golds,
/// botanical greens and inks.
const templateSwatches = [
  TemplateSwatch('White', ArgbColor(0xFFFFFFFF)),
  TemplateSwatch('Ivory', ArgbColor(0xFFFBF8F3)),
  TemplateSwatch('Cream', ArgbColor(0xFFF4EBDD)),
  TemplateSwatch('Champagne', ArgbColor(0xFFE6CD9B)),
  TemplateSwatch('Gold', ArgbColor(0xFFB8955F)),
  TemplateSwatch('Deep gold', ArgbColor(0xFF5E4424)),
  TemplateSwatch('Blush', ArgbColor(0xFFE9C9C1)),
  TemplateSwatch('Sage', ArgbColor(0xFF9DAF8F)),
  TemplateSwatch('Dusty blue', ArgbColor(0xFF8FA3B3)),
  TemplateSwatch('Terracotta', ArgbColor(0xFFB86F52)),
  TemplateSwatch('Charcoal', ArgbColor(0xFF33291F)),
  TemplateSwatch('Black', ArgbColor(0xFF000000)),
];
