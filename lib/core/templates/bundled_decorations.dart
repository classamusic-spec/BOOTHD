/// The app's own template decorations (S08 "Decorations"): original
/// artwork drawn in code (tool/art/decorations.dart) and bundled as PNG
/// files. Used by the starter designs and offered in the editor; stored in
/// the asset store like any other image once a template uses one.
library;

enum DecorationKind { floral, frame, accent }

final class BundledDecoration {
  const BundledDecoration(this.id, this.name, this.kind);

  final String id;
  final String name;
  final DecorationKind kind;

  String get assetPath => 'assets/decorations/$id.png';
}

const bundledDecorations = [
  BundledDecoration('blossom_corner', 'Blossom corner', DecorationKind.floral),
  BundledDecoration(
    'blossom_corner_champagne',
    'Champagne blossom corner',
    DecorationKind.floral,
  ),
  BundledDecoration(
    'blossom_garland',
    'Blossom garland',
    DecorationKind.floral,
  ),
  BundledDecoration('blossom_sprig', 'Blossom sprig', DecorationKind.floral),
  BundledDecoration('gold_frame', 'Gold frame, 4x6', DecorationKind.frame),
  BundledDecoration(
    'gold_frame_strip',
    'Gold frame, strip',
    DecorationKind.frame,
  ),
  BundledDecoration('film_edges', 'Film edges, strip', DecorationKind.frame),
  BundledDecoration('gold_confetti', 'Gold confetti', DecorationKind.accent),
  // EP04: Kid Party Arcade.
  BundledDecoration('party_balloons', 'Balloon bunch', DecorationKind.accent),
  BundledDecoration('party_confetti', 'Party confetti', DecorationKind.accent),
  BundledDecoration('party_stars', 'Party stars', DecorationKind.accent),
  BundledDecoration('party_bunting', 'Bunting', DecorationKind.accent),
  // EP05: Retro Game Quest.
  BundledDecoration('pixel_hearts', 'Pixel hearts', DecorationKind.accent),
  BundledDecoration('pixel_coins', 'Pixel coins', DecorationKind.accent),
  BundledDecoration('pixel_stars', 'Pixel sparkles', DecorationKind.accent),
  BundledDecoration('pixel_frame', 'Pixel frame, 4x6', DecorationKind.frame),
  BundledDecoration(
    'pixel_frame_strip',
    'Pixel frame, strip',
    DecorationKind.frame,
  ),
  BundledDecoration('arcade_marquee', 'Lit marquee', DecorationKind.accent),
];

BundledDecoration bundledDecoration(String id) =>
    bundledDecorations.firstWhere((decoration) => decoration.id == id);
