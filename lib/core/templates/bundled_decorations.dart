/// The app's own template decorations (S08 "Decorations"): original
/// artwork generated for the Atelier collection or drawn in code, bundled as PNG
/// files. Used by the starter designs and offered in the editor; stored in
/// the asset store like any other image once a template uses one.
library;

import 'occasion_catalog.dart';

enum DecorationKind { floral, frame, accent, painting, sticker }

final class BundledDecoration {
  const BundledDecoration(
    this.id,
    this.name,
    this.kind, {
    this.collection = 'Essentials',
    this.tags = const [],
  });

  final String id;
  final String name;
  final DecorationKind kind;
  final String collection;
  final List<String> tags;
  bool get transparent => kind != DecorationKind.painting;

  String get assetPath => 'assets/decorations/$id.png';
}

const _atelierDecorations = [
  BundledDecoration(
    'atelier_rose',
    'Rosewater Romance',
    DecorationKind.painting,
    collection: 'Florals',
  ),
  BundledDecoration(
    'atelier_meadow',
    'Meadow Poetry',
    DecorationKind.painting,
    collection: 'Florals',
  ),
  BundledDecoration(
    'atelier_hydrangea',
    'Something Blue',
    DecorationKind.painting,
    collection: 'Florals',
  ),
  BundledDecoration(
    'atelier_baby_sage',
    'Little Wonder',
    DecorationKind.painting,
    collection: 'Baby shower',
  ),
  BundledDecoration(
    'atelier_baby_blush',
    'Petal & Pearl',
    DecorationKind.painting,
    collection: 'Baby shower',
  ),
  BundledDecoration(
    'atelier_baby_blue',
    'Over the Moon',
    DecorationKind.painting,
    collection: 'Baby shower',
  ),
  BundledDecoration(
    'atelier_coast',
    'Coastal Reverie',
    DecorationKind.painting,
    collection: 'Watercolor',
  ),
  BundledDecoration(
    'atelier_tropical',
    'Palm House',
    DecorationKind.painting,
    collection: 'Celebrations',
  ),
  BundledDecoration(
    'atelier_gala',
    'Champagne Nocturne',
    DecorationKind.painting,
    collection: 'Celebrations',
  ),
  BundledDecoration(
    'atelier_lavender',
    'Provence in Bloom',
    DecorationKind.painting,
    collection: 'Watercolor',
  ),
  BundledDecoration(
    'atelier_autumn',
    'Amber Gathering',
    DecorationKind.painting,
    collection: 'Seasonal',
  ),
  BundledDecoration(
    'atelier_holiday',
    'Winter Evergreen',
    DecorationKind.painting,
    collection: 'Seasonal',
  ),
  BundledDecoration(
    'atelier_deco_gold',
    'The Gilded Age',
    DecorationKind.painting,
    collection: 'Art Deco',
  ),
  BundledDecoration(
    'atelier_deco_emerald',
    'Emerald Soirée',
    DecorationKind.painting,
    collection: 'Art Deco',
  ),
  BundledDecoration(
    'atelier_arcade',
    'Neon Arcade',
    DecorationKind.painting,
    collection: 'Retro gaming',
  ),
  BundledDecoration(
    'atelier_platformer',
    'Mushroom Meadow',
    DecorationKind.painting,
    collection: 'Retro gaming',
  ),
  BundledDecoration(
    'atelier_disco_sunset',
    'Disco Daydream',
    DecorationKind.painting,
    collection: 'Disco',
  ),
  BundledDecoration(
    'atelier_disco_midnight',
    'Midnight on the Dancefloor',
    DecorationKind.painting,
    collection: 'Disco',
  ),
  BundledDecoration(
    'atelier_goose_sage',
    'Mother Goose Garden',
    DecorationKind.painting,
    collection: 'Baby shower',
  ),
  BundledDecoration(
    'atelier_goose_blue',
    'Blue Ribbon Goose',
    DecorationKind.painting,
    collection: 'Baby shower',
  ),
  BundledDecoration(
    'sticker_rose_bouquet',
    'Rose & peony bouquet',
    DecorationKind.sticker,
    collection: 'Florals',
    tags: ['watercolor', 'botanical', 'flowers'],
  ),
  BundledDecoration(
    'sticker_blue_hydrangea',
    'Blue hydrangea cluster',
    DecorationKind.sticker,
    collection: 'Florals',
    tags: ['watercolor', 'botanical', 'flowers'],
  ),
  BundledDecoration(
    'sticker_wildflower_corner',
    'Wildflower corner',
    DecorationKind.sticker,
    collection: 'Florals',
    tags: ['watercolor', 'botanical', 'flowers'],
  ),
  BundledDecoration(
    'sticker_lavender_sprigs',
    'Lavender sprigs',
    DecorationKind.sticker,
    collection: 'Florals',
    tags: ['watercolor', 'botanical', 'flowers'],
  ),
  BundledDecoration(
    'sticker_eucalyptus_crescent',
    'Eucalyptus crescent',
    DecorationKind.sticker,
    collection: 'Florals',
    tags: ['watercolor', 'botanical', 'flowers'],
  ),
  BundledDecoration(
    'sticker_sunflower_spray',
    'Sunshine flowers',
    DecorationKind.sticker,
    collection: 'Florals',
    tags: ['watercolor', 'botanical', 'flowers'],
  ),
  BundledDecoration(
    'sticker_goose_blue',
    'Goose with blue bow',
    DecorationKind.sticker,
    collection: 'Geese & baby',
    tags: ['baby shower', 'nursery', 'watercolor'],
  ),
  BundledDecoration(
    'sticker_goose_sage',
    'Goose with sage bow',
    DecorationKind.sticker,
    collection: 'Geese & baby',
    tags: ['baby shower', 'nursery', 'watercolor'],
  ),
  BundledDecoration(
    'sticker_goose_family',
    'Mother goose & goslings',
    DecorationKind.sticker,
    collection: 'Geese & baby',
    tags: ['baby shower', 'nursery', 'watercolor'],
  ),
  BundledDecoration(
    'sticker_goose_flying',
    'Goose in flight',
    DecorationKind.sticker,
    collection: 'Geese & baby',
    tags: ['baby shower', 'nursery', 'watercolor'],
  ),
  BundledDecoration(
    'sticker_teddy',
    'Heirloom teddy',
    DecorationKind.sticker,
    collection: 'Geese & baby',
    tags: ['baby shower', 'nursery', 'watercolor'],
  ),
  BundledDecoration(
    'sticker_moon_cloud',
    'Moon & little stars',
    DecorationKind.sticker,
    collection: 'Geese & baby',
    tags: ['baby shower', 'nursery', 'watercolor'],
  ),
  BundledDecoration(
    'sticker_bow_blue',
    'Blue gingham bow',
    DecorationKind.sticker,
    collection: 'Ribbons',
    tags: ['bow', 'baby shower'],
  ),
  BundledDecoration(
    'sticker_bow_blush',
    'Blush satin bow',
    DecorationKind.sticker,
    collection: 'Ribbons',
    tags: ['bow', 'baby shower'],
  ),
  BundledDecoration(
    'sticker_bow_sage',
    'Sage linen bow',
    DecorationKind.sticker,
    collection: 'Ribbons',
    tags: ['bow', 'baby shower'],
  ),
  BundledDecoration(
    'sticker_deco_fan',
    'Gilded Deco fan',
    DecorationKind.sticker,
    collection: 'Art Deco',
    tags: ['gatsby', '1920s'],
  ),
  BundledDecoration(
    'sticker_deco_feathers',
    'Champagne feathers',
    DecorationKind.sticker,
    collection: 'Art Deco',
    tags: ['gatsby', '1920s'],
  ),
  BundledDecoration(
    'sticker_deco_corner',
    'Art Deco corner',
    DecorationKind.sticker,
    collection: 'Art Deco',
    tags: ['gatsby', '1920s'],
  ),
  BundledDecoration(
    'sticker_champagne_coupes',
    'Champagne coupes',
    DecorationKind.sticker,
    collection: 'Art Deco',
    tags: ['gatsby', '1920s'],
  ),
  BundledDecoration(
    'sticker_deco_sunburst',
    'Gold sunburst',
    DecorationKind.sticker,
    collection: 'Art Deco',
    tags: ['gatsby', '1920s'],
  ),
  BundledDecoration(
    'sticker_disco_ball',
    'Silver mirrorball',
    DecorationKind.sticker,
    collection: 'Disco',
    tags: ['70s', '1970s', 'party'],
  ),
  BundledDecoration(
    'sticker_disco_daisies',
    'Flower power daisies',
    DecorationKind.sticker,
    collection: 'Disco',
    tags: ['70s', '1970s', 'party'],
  ),
  BundledDecoration(
    'sticker_roller_skate',
    'Disco roller skate',
    DecorationKind.sticker,
    collection: 'Disco',
    tags: ['70s', '1970s', 'party'],
  ),
  BundledDecoration(
    'sticker_vinyl',
    'Vinyl & stardust',
    DecorationKind.sticker,
    collection: 'Disco',
    tags: ['70s', '1970s', 'party'],
  ),
  BundledDecoration(
    'sticker_game_controller',
    'Retro game controller',
    DecorationKind.sticker,
    collection: 'Retro gaming',
    tags: ['arcade', 'game', 'mario', 'platformer'],
  ),
  BundledDecoration(
    'sticker_arcade_joystick',
    'Arcade joystick',
    DecorationKind.sticker,
    collection: 'Retro gaming',
    tags: ['arcade', 'game', 'mario', 'platformer'],
  ),
  BundledDecoration(
    'sticker_game_mushroom',
    'Adventure mushroom',
    DecorationKind.sticker,
    collection: 'Retro gaming',
    tags: ['arcade', 'game', 'mario', 'platformer'],
  ),
  BundledDecoration(
    'sticker_game_star',
    'Golden power star',
    DecorationKind.sticker,
    collection: 'Retro gaming',
    tags: ['arcade', 'game', 'mario', 'platformer'],
  ),
  BundledDecoration(
    'sticker_game_coins',
    'Golden coin trail',
    DecorationKind.sticker,
    collection: 'Retro gaming',
    tags: ['arcade', 'game', 'mario', 'platformer'],
  ),
  BundledDecoration(
    'sticker_game_cloud',
    'Cloud island',
    DecorationKind.sticker,
    collection: 'Retro gaming',
    tags: ['arcade', 'game', 'mario', 'platformer'],
  ),
  BundledDecoration(
    'sticker_game_pipe',
    'Green adventure pipe',
    DecorationKind.sticker,
    collection: 'Retro gaming',
    tags: ['arcade', 'game', 'mario', 'platformer'],
  ),
  BundledDecoration(
    'sticker_pixel_hearts',
    'Pixel heart trio',
    DecorationKind.sticker,
    collection: 'Retro gaming',
    tags: ['arcade', 'game', 'mario', 'platformer'],
  ),
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

final bundledDecorations = List<BundledDecoration>.unmodifiable([
  ..._atelierDecorations,
  for (final theme in occasionThemes)
    BundledDecoration(
      theme.stickerId,
      theme.name,
      DecorationKind.sticker,
      collection: theme.collection,
      tags: [
        ...theme.tags,
        theme.key.replaceAll('_', ' '),
        'watercolor',
        'celebration',
      ],
    ),
]);

BundledDecoration bundledDecoration(String id) =>
    bundledDecorations.firstWhere((decoration) => decoration.id == id);
