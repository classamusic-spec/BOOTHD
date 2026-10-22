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
import '../../domain/template/template_tags.dart';

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
    this.tags = const TemplateTags(),
  });

  final String id;
  final String name;
  final String description;
  final PageSpec page;
  final bool blank;

  /// The library category new templates from this design get (S06 filter).
  final String? category;

  /// What the design suits (EP08 recommendations); never a restriction.
  final TemplateTags tags;

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
    'party_balloons',
    'party_confetti',
    'party_stars',
    'party_bunting',
    'pixel_hearts',
    'pixel_coins',
    'pixel_stars',
    'pixel_frame',
    'pixel_frame_strip',
    'arcade_marquee',
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
  ...kidPartyDesigns,
  ...retroGameDesigns,
];

const _party = BundledFont(BundledFontFamily.fredoka);
const _pixel = BundledFont(BundledFontFamily.pixelifySans);

const _partyCoral = ArgbColor(0xFFE8474B);
const _partyGrape = ArgbColor(0xFF6A3FD1);
const _partyInk = ArgbColor(0xFF2B2440);
const _white = ArgbColor(0xFFFFFFFF);
const _nightSky = ArgbColor(0xFF1D1B3A);
const _pixelGold = ArgbColor(0xFFFFD23F);
const _pixelBlue = ArgbColor(0xFF4D7CFE);
const _pixelRed = ArgbColor(0xFFFF4D6D);

/// White photo borders, like stickers.
const _sticker = Stroke(widthPt: 6, color: _white);

/// The same border 24 page pixels wide, so its edges fall on whole pixels
/// at half and quarter size and the editor canvas matches its preview
/// (AC-0510) on designs whose slots are aligned the same way.
const _stickerAligned = Stroke(widthPt: 5.76, color: _white);

/// Kid Party Arcade starter designs (EP04): bright, rounded and playful;
/// every word is a placeholder.
final kidPartyDesigns = <StarterDesign>[
  StarterDesign(
    id: 'kid-balloon-bash',
    category: 'Kid Party',
    name: 'Balloon Bash',
    description: 'Two rounded photos with a balloon bunch in each corner.',
    page: PageSpec.fourBySixPortrait,
    decorations: const ['party_balloons', 'party_confetti'],
    tags: const TemplateTags(
      categoryTags: ['kids', 'party'],
      recommendedExperienceIds: ['kid-party-arcade'],
      occasionTags: ['birthday'],
      visualStyleTags: ['balloons', 'bright'],
      ageSuitabilityNotes: 'Made for young children',
      defaultCaptureCount: 2,
    ),
    build: (d) {
      const page = PageSpec.fourBySixPortrait;
      return _document(page, [
        _solid(const ArgbColor(0xFFFFF6DC)),
        _slot(
          page,
          0,
          120,
          260,
          960,
          640,
          clip: const RoundedRectClip(0.06),
          border: _sticker,
        ),
        _slot(
          page,
          1,
          120,
          960,
          960,
          640,
          clip: const RoundedRectClip(0.06),
          border: _sticker,
        ),
        _image(
          page,
          'confetti',
          'Confetti',
          d['party_confetti']!,
          0,
          0,
          1200,
          1800,
        ),
        _image(
          page,
          'balloons-top',
          'Balloons, top',
          d['party_balloons']!,
          -80,
          -60,
          520,
          520,
        ),
        _image(
          page,
          'balloons-bottom',
          'Balloons, bottom',
          d['party_balloons']!,
          760,
          1260,
          480,
          480,
          rotation: 12,
        ),
        _text(
          page,
          'title',
          'Title',
          'Party Time!',
          _party,
          30,
          _partyCoral,
          440,
          70,
          700,
          170,
        ),
        _text(
          page,
          'subtitle',
          'Subtitle',
          'SATURDAY FUN',
          _party,
          12,
          _partyInk,
          120,
          1650,
          960,
          80,
          letterSpacingPt: 2,
        ),
      ], d);
    },
  ),
  StarterDesign(
    id: 'kid-confetti-strip',
    category: 'Kid Party',
    name: 'Confetti Strip',
    description: 'Three photos on white with confetti spilling over them.',
    page: PageSpec.twoBySix,
    decorations: const ['party_confetti'],
    tags: const TemplateTags(
      categoryTags: ['kids', 'party'],
      recommendedExperienceIds: ['kid-party-arcade'],
      occasionTags: ['birthday', 'school'],
      visualStyleTags: ['confetti', 'bright'],
      defaultCaptureCount: 3,
    ),
    build: (d) {
      const page = PageSpec.twoBySix;
      return _document(page, [
        _solid(_white),
        for (final (i, y) in [40.0, 448.0, 856.0].indexed)
          _slot(page, i, 40, y, 520, 400, clip: const RoundedRectClip(0.08)),
        // Over the photos on purpose: confetti crosses every photo's edge.
        _image(
          page,
          'confetti',
          'Confetti',
          d['party_confetti']!,
          // At its own proportions, centred: the dense art is never
          // squeezed, so previews keep its detail (ADR-0011).
          -300,
          0,
          1200,
          1800,
        ),
        _text(
          page,
          'title',
          'Title',
          'Yay!',
          _party,
          40,
          _partyGrape,
          40,
          1290,
          520,
          220,
        ),
        _text(
          page,
          'subtitle',
          'Subtitle',
          'BEST DAY EVER',
          _party,
          11,
          _partyInk,
          40,
          1520,
          520,
          70,
          letterSpacingPt: 2,
        ),
      ], d);
    },
  ),
  StarterDesign(
    id: 'kid-superstar',
    category: 'Kid Party',
    name: 'Superstar',
    description: 'One round photo in a burst of stars.',
    page: PageSpec.fourByFour,
    decorations: const ['party_stars'],
    tags: const TemplateTags(
      categoryTags: ['kids'],
      recommendedExperienceIds: ['kid-party-arcade'],
      occasionTags: ['birthday', 'award'],
      visualStyleTags: ['stars', 'bright'],
      defaultCaptureCount: 1,
    ),
    build: (d) {
      const page = PageSpec.fourByFour;
      return _document(page, [
        _solid(const ArgbColor(0xFFDDF0FF)),
        // Above the title only, so no star crosses the words.
        _image(page, 'stars', 'Stars', d['party_stars']!, 0, 0, 1200, 900),
        _slot(
          page,
          0,
          252,
          180,
          704,
          704,
          clip: const EllipseClip(),
          border: const Stroke(widthPt: 7.68, color: _white),
        ),
        _text(
          page,
          'title',
          'Title',
          'Superstar',
          _party,
          30,
          _partyGrape,
          100,
          930,
          1000,
          170,
        ),
      ], d);
    },
  ),
  StarterDesign(
    id: 'kid-bunting-landscape',
    category: 'Kid Party',
    name: 'Bunting Party',
    description: 'Three photos under a string of bright flags.',
    page: PageSpec.fourBySixLandscape,
    decorations: const ['party_bunting', 'party_confetti'],
    tags: const TemplateTags(
      categoryTags: ['kids', 'party'],
      recommendedExperienceIds: ['kid-party-arcade'],
      occasionTags: ['birthday', 'fair'],
      visualStyleTags: ['bunting', 'bright'],
      defaultCaptureCount: 3,
    ),
    build: (d) {
      const page = PageSpec.fourBySixLandscape;
      return _document(page, [
        _solid(const ArgbColor(0xFFE4F8F1)),
        _image(
          page,
          'bunting',
          'Bunting',
          d['party_bunting']!,
          0,
          0,
          1800,
          540,
        ),
        for (final (i, x) in [96.0, 656.0, 1216.0].indexed)
          _slot(
            page,
            i,
            x,
            384,
            504,
            624,
            clip: const RoundedRectClip(0.06),
            border: _stickerAligned,
          ),
        _text(
          page,
          'title',
          'Title',
          "Let's Celebrate",
          _party,
          26,
          _partyCoral,
          90,
          1030,
          1620,
          140,
        ),
      ], d);
    },
  ),
  StarterDesign(
    id: 'kid-sticker-grid',
    category: 'Kid Party',
    name: 'Sticker Grid',
    description: 'Four photos like stickers, scattered with stars.',
    page: PageSpec.fourBySixPortrait,
    decorations: const ['party_stars'],
    tags: const TemplateTags(
      categoryTags: ['kids'],
      recommendedExperienceIds: ['kid-party-arcade'],
      occasionTags: ['birthday', 'sleepover'],
      visualStyleTags: ['stickers', 'stars'],
      defaultCaptureCount: 4,
    ),
    build: (d) {
      const page = PageSpec.fourBySixPortrait;
      return _document(page, [
        _solid(const ArgbColor(0xFFEDE4FF)),
        _image(page, 'stars', 'Stars', d['party_stars']!, 0, 300, 1200, 1200),
        for (final (i, (x, y)) in [
          (90.0, 240.0),
          (630.0, 240.0),
          (90.0, 900.0),
          (630.0, 900.0),
        ].indexed)
          _slot(
            page,
            i,
            x,
            y,
            480,
            600,
            clip: const RoundedRectClip(0.08),
            border: _sticker,
          ),
        _text(
          page,
          'title',
          'Title',
          'Best Day Ever',
          _party,
          30,
          _partyGrape,
          90,
          60,
          1020,
          160,
        ),
        _text(
          page,
          'subtitle',
          'Subtitle',
          'PARTY PALS',
          _party,
          12,
          _partyInk,
          90,
          1570,
          1020,
          80,
          letterSpacingPt: 2,
        ),
      ], d);
    },
  ),
  StarterDesign(
    id: 'kid-birthday-square',
    category: 'Kid Party',
    name: 'Birthday Square',
    description: 'Two photos side by side under a balloon bunch.',
    page: PageSpec.fourByFour,
    decorations: const ['party_balloons', 'party_confetti'],
    tags: const TemplateTags(
      categoryTags: ['kids', 'party'],
      recommendedExperienceIds: ['kid-party-arcade'],
      occasionTags: ['birthday'],
      visualStyleTags: ['balloons', 'bright'],
      defaultCaptureCount: 2,
    ),
    build: (d) {
      const page = PageSpec.fourByFour;
      return _document(page, [
        _solid(const ArgbColor(0xFFFFE3E3)),
        _image(
          page,
          'confetti',
          'Confetti',
          d['party_confetti']!,
          0,
          0,
          1200,
          1200,
        ),
        _slot(
          page,
          0,
          70,
          380,
          510,
          640,
          clip: const RoundedRectClip(0.06),
          border: _sticker,
        ),
        _slot(
          page,
          1,
          620,
          380,
          510,
          640,
          clip: const RoundedRectClip(0.06),
          border: _sticker,
        ),
        _image(
          page,
          'balloons',
          'Balloons',
          d['party_balloons']!,
          -40,
          -40,
          380,
          380,
        ),
        _text(
          page,
          'title',
          'Title',
          'Happy Birthday!',
          _party,
          26,
          _partyCoral,
          300,
          110,
          860,
          160,
        ),
        _text(
          page,
          'subtitle',
          'Subtitle',
          'MAKE A WISH',
          _party,
          10,
          _partyInk,
          70,
          1070,
          1060,
          70,
          letterSpacingPt: 2,
        ),
      ], d);
    },
  ),
];

/// Retro Game Quest starter designs (EP05): pixel borders, hearts, coins
/// and a lit marquee, all original; no game, character or console is
/// imitated. Every word is a placeholder.
final retroGameDesigns = <StarterDesign>[
  StarterDesign(
    id: 'retro-player-one-strip',
    category: 'Retro Game',
    name: 'Player One Strip',
    description: 'Three photos in a pixel border with three hearts.',
    page: PageSpec.twoBySix,
    decorations: const ['pixel_frame_strip', 'pixel_hearts'],
    tags: const TemplateTags(
      categoryTags: ['gaming', 'retro'],
      recommendedExperienceIds: ['retro-game-quest'],
      occasionTags: ['birthday', 'party'],
      visualStyleTags: ['pixel', 'dark'],
      defaultCaptureCount: 3,
      optionalPackVariant: 'arcade',
    ),
    build: (d) {
      const page = PageSpec.twoBySix;
      return _document(page, [
        _solid(_nightSky),
        for (final (i, y) in [110.0, 500.0, 890.0].indexed)
          _slot(page, i, 70, y, 460, 350),
        _image(
          page,
          'frame',
          'Pixel frame',
          d['pixel_frame_strip']!,
          0,
          0,
          600,
          1800,
        ),
        _image(
          page,
          'hearts',
          'Hearts',
          d['pixel_hearts']!,
          150,
          1300,
          300,
          100,
        ),
        _text(
          page,
          'title',
          'Title',
          'PLAYER 1',
          _pixel,
          26,
          _pixelGold,
          50,
          1420,
          500,
          140,
        ),
        _text(
          page,
          'subtitle',
          'Subtitle',
          'READY',
          _pixel,
          12,
          _white,
          50,
          1570,
          500,
          80,
          letterSpacingPt: 3,
        ),
      ], d);
    },
  ),
  StarterDesign(
    id: 'retro-bonus-round',
    category: 'Retro Game',
    name: 'Bonus Round',
    description: 'Two photos on blue with pixel coins round the edge.',
    page: PageSpec.fourBySixPortrait,
    decorations: const ['pixel_coins'],
    tags: const TemplateTags(
      categoryTags: ['gaming', 'retro'],
      recommendedExperienceIds: ['retro-game-quest'],
      occasionTags: ['party'],
      visualStyleTags: ['pixel', 'bright'],
      defaultCaptureCount: 2,
      optionalPackVariant: 'handheld',
    ),
    build: (d) {
      const page = PageSpec.fourBySixPortrait;
      return _document(page, [
        _solid(_pixelBlue),
        _image(page, 'coins', 'Coins', d['pixel_coins']!, 0, 0, 1200, 1800),
        _slot(
          page,
          0,
          140,
          300,
          920,
          620,
          border: const Stroke(widthPt: 6, color: _nightSky),
        ),
        _slot(
          page,
          1,
          140,
          960,
          920,
          620,
          border: const Stroke(widthPt: 6, color: _nightSky),
        ),
        _text(
          page,
          'title',
          'Title',
          'BONUS ROUND',
          _pixel,
          30,
          _pixelGold,
          100,
          90,
          1000,
          170,
        ),
        _text(
          page,
          'subtitle',
          'Subtitle',
          'COLLECT THEM ALL',
          _pixel,
          11,
          _white,
          100,
          1630,
          1000,
          80,
          letterSpacingPt: 2,
        ),
      ], d);
    },
  ),
  StarterDesign(
    id: 'retro-hud-landscape',
    category: 'Retro Game',
    name: 'Scoreboard',
    description: 'Two wide photos under a scoreboard with hearts and a score.',
    page: PageSpec.fourBySixLandscape,
    decorations: const ['pixel_hearts', 'pixel_stars'],
    tags: const TemplateTags(
      categoryTags: ['gaming', 'retro'],
      recommendedExperienceIds: ['retro-game-quest'],
      occasionTags: ['tournament', 'party'],
      visualStyleTags: ['pixel', 'dark'],
      defaultCaptureCount: 2,
    ),
    build: (d) {
      const page = PageSpec.fourBySixLandscape;
      return _document(page, [
        _solid(_nightSky),
        _image(
          page,
          'sparkles',
          'Sparkles',
          d['pixel_stars']!,
          0,
          0,
          1800,
          1200,
        ),
        _image(page, 'hearts', 'Hearts', d['pixel_hearts']!, 80, 60, 360, 120),
        _text(
          page,
          'score',
          'Score',
          'SCORE 00100',
          _pixel,
          18,
          _white,
          1060,
          70,
          660,
          110,
        ),
        for (final (i, x) in [80.0, 930.0].indexed)
          _slot(
            page,
            i,
            x,
            230,
            790,
            790,
            border: const Stroke(widthPt: 6, color: _pixelGold),
          ),
        _text(
          page,
          'title',
          'Title',
          'LEVEL 1',
          _pixel,
          22,
          _pixelGold,
          80,
          1050,
          1640,
          120,
        ),
      ], d);
    },
  ),
  StarterDesign(
    id: 'retro-level-up',
    category: 'Retro Game',
    name: 'Level Up',
    description: 'One photo on gold with pixel sparkles.',
    page: PageSpec.fourByFour,
    decorations: const ['pixel_stars'],
    tags: const TemplateTags(
      categoryTags: ['gaming', 'retro'],
      recommendedExperienceIds: ['retro-game-quest'],
      occasionTags: ['birthday', 'graduation'],
      visualStyleTags: ['pixel', 'bright'],
      defaultCaptureCount: 1,
    ),
    build: (d) {
      const page = PageSpec.fourByFour;
      return _document(page, [
        _solid(_pixelGold),
        _image(
          page,
          'sparkles',
          'Sparkles',
          d['pixel_stars']!,
          0,
          0,
          1200,
          1200,
        ),
        _slot(
          page,
          0,
          200,
          140,
          800,
          800,
          border: const Stroke(widthPt: 8, color: _nightSky),
        ),
        _text(
          page,
          'title',
          'Title',
          'LEVEL UP!',
          _pixel,
          30,
          _nightSky,
          100,
          980,
          1000,
          170,
        ),
      ], d);
    },
  ),
  StarterDesign(
    id: 'retro-marquee',
    category: 'Retro Game',
    name: 'Marquee',
    description: 'Two photos under a marquee ringed with lights.',
    page: PageSpec.fourBySixPortrait,
    decorations: const ['arcade_marquee', 'pixel_stars'],
    tags: const TemplateTags(
      categoryTags: ['gaming', 'retro'],
      recommendedExperienceIds: ['retro-game-quest'],
      occasionTags: ['party', 'corporate'],
      visualStyleTags: ['marquee', 'dark'],
      defaultCaptureCount: 2,
      optionalPackVariant: 'arcade',
    ),
    build: (d) {
      const page = PageSpec.fourBySixPortrait;
      return _document(page, [
        _solid(_nightSky),
        _image(
          page,
          'sparkles',
          'Sparkles',
          d['pixel_stars']!,
          0,
          600,
          1200,
          1200,
        ),
        _image(
          page,
          'marquee',
          'Marquee',
          d['arcade_marquee']!,
          40,
          30,
          1120,
          336,
        ),
        _text(
          page,
          'title',
          'Title',
          'HIGH SCORE',
          _pixel,
          28,
          _pixelGold,
          140,
          120,
          920,
          150,
        ),
        _slot(
          page,
          0,
          120,
          420,
          960,
          640,
          border: const Stroke(widthPt: 6, color: _pixelRed),
        ),
        _slot(
          page,
          1,
          120,
          1100,
          960,
          640,
          border: const Stroke(widthPt: 6, color: _pixelRed),
        ),
      ], d);
    },
  ),
  StarterDesign(
    id: 'retro-high-score-strip',
    category: 'Retro Game',
    name: 'High Score Strip',
    description: 'Three photos with scores beside a marquee title.',
    page: PageSpec.twoBySix,
    decorations: const ['arcade_marquee', 'pixel_coins'],
    tags: const TemplateTags(
      categoryTags: ['gaming', 'retro'],
      recommendedExperienceIds: ['retro-game-quest'],
      occasionTags: ['party'],
      visualStyleTags: ['marquee', 'dark'],
      defaultCaptureCount: 3,
      optionalPackVariant: 'arcade',
    ),
    build: (d) {
      const page = PageSpec.twoBySix;
      return _document(page, [
        _solid(_nightSky),
        _image(page, 'coins', 'Coins', d['pixel_coins']!, 0, 0, 600, 1800),
        _image(
          page,
          'marquee',
          'Marquee',
          d['arcade_marquee']!,
          20,
          20,
          560,
          168,
        ),
        _text(
          page,
          'title',
          'Title',
          'TOP 3',
          _pixel,
          18,
          _pixelGold,
          60,
          60,
          480,
          90,
        ),
        for (final (i, y) in [230.0, 640.0, 1050.0].indexed)
          _slot(
            page,
            i,
            60,
            y,
            480,
            360,
            border: const Stroke(widthPt: 5, color: _pixelGold),
          ),
        _text(
          page,
          'subtitle',
          'Subtitle',
          'INSERT SMILE',
          _pixel,
          14,
          _white,
          40,
          1480,
          520,
          120,
          letterSpacingPt: 2,
        ),
      ], d);
    },
  ),
  StarterDesign(
    id: 'retro-co-op',
    category: 'Retro Game',
    name: 'Co-op Mode',
    description: 'Four photos inside a chunky pixel border.',
    page: PageSpec.fourBySixPortrait,
    decorations: const ['pixel_frame', 'pixel_hearts'],
    tags: const TemplateTags(
      categoryTags: ['gaming', 'retro'],
      recommendedExperienceIds: ['retro-game-quest'],
      occasionTags: ['party', 'family'],
      visualStyleTags: ['pixel', 'light'],
      defaultCaptureCount: 4,
      optionalPackVariant: 'handheld',
    ),
    build: (d) {
      const page = PageSpec.fourBySixPortrait;
      return _document(page, [
        _solid(const ArgbColor(0xFFE8EDD5)),
        for (final (i, (x, y)) in [
          (160.0, 300.0),
          (620.0, 300.0),
          (160.0, 900.0),
          (620.0, 900.0),
        ].indexed)
          _slot(
            page,
            i,
            x,
            y,
            420,
            560,
            border: const Stroke(widthPt: 5, color: _nightSky),
          ),
        _image(
          page,
          'frame',
          'Pixel frame',
          d['pixel_frame']!,
          0,
          0,
          1200,
          1800,
        ),
        _image(
          page,
          'hearts',
          'Hearts',
          d['pixel_hearts']!,
          420,
          1520,
          360,
          120,
        ),
        _text(
          page,
          'title',
          'Title',
          'CO-OP MODE',
          _pixel,
          28,
          _nightSky,
          140,
          120,
          920,
          150,
        ),
      ], d);
    },
  ),
  StarterDesign(
    id: 'retro-game-on',
    category: 'Retro Game',
    name: 'Game On',
    description: 'Three photos in a row on a starry night.',
    page: PageSpec.fourBySixLandscape,
    decorations: const ['pixel_stars', 'pixel_hearts'],
    tags: const TemplateTags(
      categoryTags: ['gaming', 'retro'],
      recommendedExperienceIds: ['retro-game-quest'],
      occasionTags: ['tournament', 'party'],
      visualStyleTags: ['pixel', 'dark'],
      defaultCaptureCount: 3,
    ),
    build: (d) {
      const page = PageSpec.fourBySixLandscape;
      return _document(page, [
        _solid(_nightSky),
        _image(
          page,
          'sparkles',
          'Sparkles',
          d['pixel_stars']!,
          0,
          0,
          1800,
          1200,
        ),
        _text(
          page,
          'title',
          'Title',
          'GAME ON!',
          _pixel,
          30,
          _pixelRed,
          90,
          70,
          1620,
          170,
        ),
        for (final (i, x) in [90.0, 650.0, 1210.0].indexed)
          _slot(
            page,
            i,
            x,
            290,
            500,
            660,
            border: const Stroke(widthPt: 6, color: _white),
          ),
        _image(
          page,
          'hearts',
          'Hearts',
          d['pixel_hearts']!,
          720,
          1010,
          360,
          120,
        ),
      ], d);
    },
  ),
];
