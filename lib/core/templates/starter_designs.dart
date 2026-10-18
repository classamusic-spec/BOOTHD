/// What a new template can start from (S06, AC-0501): a blank page in each
/// print format, or one of the finished designs named after the owner's
/// reference board (CR-002). Designs use the bundled decorations; their
/// words are placeholders the operator replaces. No names or people.
library;

import '../../domain/repositories/template_store.dart';
import '../../domain/template/editing/layer_copy.dart';
import '../../domain/template/geometry.dart';
import '../../domain/template/page_spec.dart';
import '../../domain/template/template_assets.dart';
import '../../domain/template/template_document.dart';
import '../../domain/template/template_layers.dart';

const _ivory = ArgbColor(0xFFFBF8F3);
const _ink = ArgbColor(0xFF33291F);
const _inkMuted = ArgbColor(0xFF66574A);
const _deepGold = ArgbColor(0xFF5E4424);
const _gold = ArgbColor(0xFFB8955F);

const _serif = BundledFont(BundledFontFamily.cormorantGaramond, weight: 600);
const _sans = BundledFont(BundledFontFamily.inter);
const _sansStrong = BundledFont(BundledFontFamily.inter, weight: 600);

final class StarterDesign {
  const StarterDesign({
    required this.id,
    required this.name,
    required this.description,
    required this.page,
    required this.decorations,
    required this.build,
    this.category,
    this.blank = false,
  });

  final String id;
  final String name;
  final String description;
  final PageSpec page;
  final bool blank;

  /// The library category new templates from this design get (S06 filter).
  final String? category;

  /// Bundled decorations the design uses (ids from bundledDecorations).
  final List<String> decorations;

  /// The document, given the stored decorations by decoration id.
  final TemplateDocument Function(Map<String, StoredAsset> decorations) build;

  int get photoSlots => build(_placeholderAssets).photoSlotCount;
}

/// Stand-in assets so a design's slot count can be read without storage.
final _placeholderAssets = {
  for (final id in [
    'blossom_corner',
    'blossom_corner_champagne',
    'blossom_garland',
    'blossom_sprig',
    'gold_frame',
    'gold_frame_strip',
    'film_edges',
    'gold_confetti',
  ])
    id: StoredAsset(
      id: id.codeUnits
          .fold<int>(7, (h, c) => (h * 31 + c) & 0xFFFFFF)
          .toRadixString(16)
          .padLeft(64, '0'),
      asset: const TemplateAsset(
        mediaType: AssetMediaType.png,
        byteLength: 1,
        widthPx: 1,
        heightPx: 1,
      ),
      origin: AssetOrigin.bundled,
      createdAt: DateTime.utc(2026),
    ),
};

/// A frame from page pixels.
NormalizedRect _px(PageSpec page, double x, double y, double w, double h) =>
    NormalizedRect(
      x: x / page.widthPx,
      y: y / page.heightPx,
      width: w / page.widthPx,
      height: h / page.heightPx,
    );

BackgroundLayer _solid(ArgbColor color) => BackgroundLayer(
  id: 'background',
  zIndex: 0,
  name: 'Background',
  fill: SolidFill(color),
);

PhotoSlotLayer _slot(
  PageSpec page,
  int index,
  double x,
  double y,
  double w,
  double h, {
  SlotClip clip = const RectClip(),
  Stroke? border,
}) => PhotoSlotLayer(
  id: 'photo-${index + 1}',
  zIndex: 0,
  name: 'Photo ${index + 1}',
  slotIndex: index,
  frame: _px(page, x, y, w, h),
  clip: clip,
  border: border,
);

TextLayer _text(
  PageSpec page,
  String id,
  String name,
  String text,
  FontRef font,
  double sizePt,
  ArgbColor color,
  double x,
  double y,
  double w,
  double h, {
  double letterSpacingPt = 0,
}) => TextLayer(
  id: id,
  zIndex: 0,
  name: name,
  frame: _px(page, x, y, w, h),
  text: text,
  font: font,
  sizePt: sizePt,
  color: color,
  letterSpacingPt: letterSpacingPt,
);

ImageLayer _image(
  PageSpec page,
  String id,
  String name,
  StoredAsset asset,
  double x,
  double y,
  double w,
  double h, {
  double rotation = 0,
}) => ImageLayer(
  id: id,
  zIndex: 0,
  name: name,
  assetId: asset.id,
  frame: _px(page, x, y, w, h),
  rotationDegrees: rotation,
);

/// [layers] in the given order as a document with the assets they use.
TemplateDocument _document(
  PageSpec page,
  List<TemplateLayer> layers,
  Map<String, StoredAsset> decorations,
) {
  final ordered = [
    for (final (z, layer) in layers.indexed) copyLayer(layer, zIndex: z),
  ];
  final used = {for (final layer in ordered) ...layer.assetIds};
  return TemplateDocument(
    page: page,
    layers: ordered,
    assets: {
      for (final stored in decorations.values)
        if (used.contains(stored.id)) stored.id: stored.asset,
    },
  );
}

StarterDesign _blank(String id, String name, PageSpec page) => StarterDesign(
  id: id,
  name: name,
  description: 'An empty page to design from scratch.',
  page: page,
  decorations: const [],
  blank: true,
  build: (_) => _document(page, [_solid(_ivory)], const {}),
);

final starterDesigns = <StarterDesign>[
  _blank('blank-2x6', 'Blank 2x6 strip', PageSpec.twoBySix),
  _blank('blank-4x6', 'Blank 4x6 portrait', PageSpec.fourBySixPortrait),
  _blank('blank-6x4', 'Blank 4x6 landscape', PageSpec.fourBySixLandscape),
  _blank('blank-4x4', 'Blank 4x4 square', PageSpec.fourByFour),
  StarterDesign(
    id: 'classic-strip',
    category: 'Classic',
    name: 'Classic Strip',
    description: 'Three photos on ivory with a serif title.',
    page: PageSpec.twoBySix,
    decorations: const [],
    build: (d) {
      const page = PageSpec.twoBySix;
      return _document(page, [
        _solid(_ivory),
        for (final (i, y) in [36.0, 456.0, 876.0].indexed)
          _slot(page, i, 36, y, 528, 396),
        ShapeLayer(
          id: 'rule',
          zIndex: 0,
          name: 'Rule',
          frame: _px(page, 200, 1338, 200, 3),
          shape: ShapeKind.rect,
          fill: _gold,
        ),
        _text(
          page,
          'title',
          'Title',
          'Celebrate',
          _serif,
          26,
          _deepGold,
          36,
          1370,
          528,
          140,
        ),
        _text(
          page,
          'subtitle',
          'Subtitle',
          'WITH LOVE',
          _sans,
          9,
          _inkMuted,
          36,
          1505,
          528,
          60,
          letterSpacingPt: 3,
        ),
      ], d);
    },
  ),
  StarterDesign(
    id: 'floral-elegance',
    category: 'Floral',
    name: 'Floral Elegance',
    description: 'Rounded photos framed by cream blossoms.',
    page: PageSpec.twoBySix,
    decorations: const ['blossom_corner', 'blossom_garland', 'blossom_sprig'],
    build: (d) {
      const page = PageSpec.twoBySix;
      const ivory = ArgbColor(0xFFFFFCF6);
      return _document(page, [
        _solid(ivory),
        for (final (i, y) in [150.0, 560.0, 970.0].indexed)
          _slot(page, i, 60, y, 480, 360, clip: const RoundedRectClip(0.05)),
        // A vine down the left edge, crossing every photo's edge, under a
        // spray in the top corner and another over the last photo.
        _image(
          page,
          'vine',
          'Blossom vine',
          d['blossom_garland']!,
          -22,
          380,
          170,
          850,
        ),
        _image(
          page,
          'blossoms-top',
          'Blossoms, top',
          d['blossom_corner']!,
          -60,
          -50,
          500,
          500,
        ),
        _image(
          page,
          'blossoms-bottom',
          'Blossoms, bottom',
          d['blossom_corner']!,
          290,
          1060,
          340,
          340,
          rotation: 180,
        ),
        _text(
          page,
          'title',
          'Title',
          'With Love',
          _serif,
          30,
          _deepGold,
          36,
          1430,
          528,
          160,
        ),
        _image(
          page,
          'sprig',
          'Sprig',
          d['blossom_sprig']!,
          150,
          1600,
          300,
          150,
        ),
      ], d);
    },
  ),
  StarterDesign(
    id: 'modern-minimal',
    category: 'Modern',
    name: 'Modern Minimal',
    description: 'Two wide photos, a fine line and spaced capitals.',
    page: PageSpec.fourBySixPortrait,
    decorations: const [],
    build: (d) {
      const page = PageSpec.fourBySixPortrait;
      return _document(page, [
        _solid(const ArgbColor(0xFFFFFFFF)),
        _slot(page, 0, 60, 60, 1080, 720),
        _slot(page, 1, 60, 840, 1080, 720),
        ShapeLayer(
          id: 'line',
          zIndex: 0,
          name: 'Line',
          frame: _px(page, 60, 1620, 1080, 3),
          shape: ShapeKind.rect,
          fill: _ink,
        ),
        _text(
          page,
          'caption',
          'Caption',
          'MOMENTS',
          _sansStrong,
          16,
          _ink,
          60,
          1650,
          1080,
          110,
          letterSpacingPt: 8,
        ),
      ], d);
    },
  ),
  StarterDesign(
    id: 'retro-film',
    category: 'Retro',
    name: 'Retro Film',
    description: 'Four frames on a dark film strip.',
    page: PageSpec.twoBySix,
    decorations: const ['film_edges'],
    build: (d) {
      const page = PageSpec.twoBySix;
      return _document(page, [
        // Light shows through the sprocket holes; the film is the dark
        // band between them.
        _solid(const ArgbColor(0xFFF4EBDD)),
        ShapeLayer(
          id: 'film-base',
          zIndex: 0,
          name: 'Film',
          frame: _px(page, 60, 0, 480, 1800),
          shape: ShapeKind.rect,
          fill: const ArgbColor(0xFF1C1713),
        ),
        for (final (i, y) in [54.0, 399.0, 744.0, 1089.0].indexed)
          _slot(page, i, 86, y, 428, 321),
        _image(page, 'film', 'Film edges', d['film_edges']!, 0, 0, 600, 1800),
        _text(
          page,
          'caption',
          'Caption',
          'FILM NO. 26',
          _sansStrong,
          10,
          const ArgbColor(0xFFE9D9BF),
          86,
          1470,
          428,
          80,
          letterSpacingPt: 2,
        ),
      ], d);
    },
  ),
  StarterDesign(
    id: 'gold-celebration',
    category: 'Party',
    name: 'Gold Celebration',
    description: 'Champagne paper, a gold frame and confetti.',
    page: PageSpec.fourBySixPortrait,
    decorations: const ['gold_frame', 'gold_confetti'],
    build: (d) {
      const page = PageSpec.fourBySixPortrait;
      const border = Stroke(widthPt: 2, color: _gold);
      return _document(page, [
        const BackgroundLayer(
          id: 'background',
          zIndex: 0,
          name: 'Background',
          fill: LinearGradientFill(
            angleDegrees: 180,
            stops: [
              GradientStop(0, ArgbColor(0xFFFBF6EC)),
              GradientStop(1, ArgbColor(0xFFEFE2C8)),
            ],
          ),
        ),
        _image(page, 'frame', 'Gold frame', d['gold_frame']!, 0, 0, 1200, 1800),
        _slot(
          page,
          0,
          150,
          170,
          900,
          600,
          clip: const RoundedRectClip(0.02),
          border: border,
        ),
        _slot(
          page,
          1,
          150,
          810,
          900,
          600,
          clip: const RoundedRectClip(0.02),
          border: border,
        ),
        _image(
          page,
          'confetti',
          'Confetti',
          d['gold_confetti']!,
          0,
          0,
          1200,
          1800,
        ),
        _text(
          page,
          'title',
          'Title',
          'Celebrate!',
          _serif,
          44,
          _deepGold,
          150,
          1440,
          900,
          230,
        ),
      ], d);
    },
  ),
];
