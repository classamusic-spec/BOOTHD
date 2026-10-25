part of 'starter_designs.dart';

/// Original bundled paintings. Captions and photo windows remain native,
/// editable document layers; the artwork is never a flattened template.
final class AtelierArtwork {
  const AtelierArtwork({
    required this.id,
    required this.name,
    required this.collection,
    required this.title,
    required this.subtitle,
    required this.ink,
    required this.palette,
    this.style = 'watercolor',
  });
  final String id;
  final String name;
  final String collection;
  final String title;
  final String subtitle;
  final ArgbColor ink;
  final List<String> palette;
  final String style;
}

const atelierArtworks = [
  AtelierArtwork(
    id: 'atelier_rose',
    name: 'Rosewater Romance',
    collection: 'Florals',
    title: 'With Love',
    subtitle: 'OUR FAVORITE MEMORIES',
    ink: ArgbColor(0xFF704548),
    palette: ['Blush', 'Sage', 'Ivory'],
  ),
  AtelierArtwork(
    id: 'atelier_meadow',
    name: 'Meadow Poetry',
    collection: 'Florals',
    title: 'Wild at Heart',
    subtitle: 'LET LOVE GROW',
    ink: ArgbColor(0xFF3C5743),
    palette: ['Cornflower', 'Coral', 'Butter'],
  ),
  AtelierArtwork(
    id: 'atelier_hydrangea',
    name: 'Something Blue',
    collection: 'Florals',
    title: 'Always & Forever',
    subtitle: 'SOMETHING BEAUTIFUL',
    ink: ArgbColor(0xFF314F73),
    palette: ['French blue', 'Ivory', 'Sage'],
  ),
  AtelierArtwork(
    id: 'atelier_baby_sage',
    name: 'Little Wonder',
    collection: 'Baby shower',
    title: 'Little Wonder',
    subtitle: 'A LITTLE LOVE IS ON THE WAY',
    ink: ArgbColor(0xFF3F594B),
    palette: ['Sage', 'Oatmeal', 'Cream'],
  ),
  AtelierArtwork(
    id: 'atelier_baby_blush',
    name: 'Petal & Pearl',
    collection: 'Baby shower',
    title: 'Hello, Little One',
    subtitle: 'OH, BABY',
    ink: ArgbColor(0xFF754C59),
    palette: ['Blush', 'Mauve', 'Pearl'],
  ),
  AtelierArtwork(
    id: 'atelier_baby_blue',
    name: 'Over the Moon',
    collection: 'Baby shower',
    title: 'Over the Moon',
    subtitle: 'LOVE YOU TO THE MOON',
    ink: ArgbColor(0xFF3B5372),
    palette: ['Powder blue', 'Gold', 'Cloud'],
  ),
  AtelierArtwork(
    id: 'atelier_coast',
    name: 'Coastal Reverie',
    collection: 'Watercolor',
    title: 'By the Sea',
    subtitle: 'SALT AIR & SWEET MEMORIES',
    ink: ArgbColor(0xFF315B64),
    palette: ['Sea glass', 'Sand', 'Mist'],
  ),
  AtelierArtwork(
    id: 'atelier_tropical',
    name: 'Palm House',
    collection: 'Celebrations',
    title: 'Paradise Found',
    subtitle: 'GOOD TIMES IN PARADISE',
    ink: ArgbColor(0xFF254E40),
    palette: ['Emerald', 'Blush', 'Ivory'],
  ),
  AtelierArtwork(
    id: 'atelier_gala',
    name: 'Champagne Nocturne',
    collection: 'Celebrations',
    title: 'A Night to Remember',
    subtitle: "LET'S CELEBRATE",
    ink: ArgbColor(0xFF333B54),
    palette: ['Midnight', 'Champagne', 'Gold'],
  ),
  AtelierArtwork(
    id: 'atelier_lavender',
    name: 'Provence in Bloom',
    collection: 'Watercolor',
    title: 'In Full Bloom',
    subtitle: 'BEAUTIFUL MOMENTS',
    ink: ArgbColor(0xFF59496E),
    palette: ['Lavender', 'Lilac', 'Sage'],
  ),
  AtelierArtwork(
    id: 'atelier_autumn',
    name: 'Amber Gathering',
    collection: 'Seasonal',
    title: 'Gather Together',
    subtitle: 'MADE OF GOLDEN MOMENTS',
    ink: ArgbColor(0xFF78503C),
    palette: ['Terracotta', 'Honey', 'Cream'],
  ),
  AtelierArtwork(
    id: 'atelier_holiday',
    name: 'Winter Evergreen',
    collection: 'Seasonal',
    title: 'Merry & Bright',
    subtitle: 'A SEASON OF JOY',
    ink: ArgbColor(0xFF344E40),
    palette: ['Evergreen', 'Burgundy', 'Gold'],
  ),
  AtelierArtwork(
    id: 'atelier_deco_gold',
    name: 'The Gilded Age',
    collection: 'Art Deco',
    title: 'The Golden Hour',
    subtitle: 'A NIGHT TO REMEMBER',
    style: 'Art Deco',
    ink: ArgbColor(0xFF5B461F),
    palette: ['Champagne', 'Onyx', 'Gold'],
  ),
  AtelierArtwork(
    id: 'atelier_deco_emerald',
    name: 'Emerald Soirée',
    collection: 'Art Deco',
    title: 'An Elegant Affair',
    subtitle: 'LET THE EVENING BEGIN',
    style: 'Art Deco',
    ink: ArgbColor(0xFF285346),
    palette: ['Emerald', 'Gold', 'Ivory'],
  ),
  AtelierArtwork(
    id: 'atelier_arcade',
    name: 'Neon Arcade',
    collection: 'Retro gaming',
    title: 'Level Up!',
    subtitle: 'GOOD TIMES • HIGH SCORES',
    style: '16-bit arcade',
    ink: ArgbColor(0xFF4D3475),
    palette: ['Violet', 'Cyan', 'Pink'],
  ),
  AtelierArtwork(
    id: 'atelier_platformer',
    name: 'Mushroom Meadow',
    collection: 'Retro gaming',
    title: "Let's-a Celebrate!",
    subtitle: 'AN ADVENTURE TO REMEMBER',
    style: 'retro platformer',
    ink: ArgbColor(0xFF2E694B),
    palette: ['Sky blue', 'Leaf green', 'Coral'],
  ),
  AtelierArtwork(
    id: 'atelier_disco_sunset',
    name: 'Disco Daydream',
    collection: 'Disco',
    title: 'Stay Groovy',
    subtitle: 'GOOD VIBES • GREAT MEMORIES',
    style: '70s disco',
    ink: ArgbColor(0xFF84492E),
    palette: ['Tangerine', 'Pink', 'Butter'],
  ),
  AtelierArtwork(
    id: 'atelier_disco_midnight',
    name: 'Midnight on the Dancefloor',
    collection: 'Disco',
    title: 'Dance All Night',
    subtitle: 'MEET ME UNDER THE MIRRORBALL',
    style: '70s disco',
    ink: ArgbColor(0xFF623F78),
    palette: ['Lilac', 'Silver', 'Pink'],
  ),
  AtelierArtwork(
    id: 'atelier_goose_sage',
    name: 'Mother Goose Garden',
    collection: 'Baby shower',
    title: 'A Little Goose',
    subtitle: 'A LITTLE ONE IS ON THE WAY',
    style: 'watercolor',
    ink: ArgbColor(0xFF4A6052),
    palette: ['Sage', 'Butter', 'Cream'],
  ),
  AtelierArtwork(
    id: 'atelier_goose_blue',
    name: 'Blue Ribbon Goose',
    collection: 'Baby shower',
    title: 'Hello, Little Goose',
    subtitle: 'A SWEET NEW CHAPTER',
    style: 'watercolor',
    ink: ArgbColor(0xFF405A79),
    palette: ['Powder blue', 'Butter', 'Ivory'],
  ),
];

final atelierStarterDesigns = [
  for (final art in atelierArtworks) _atelierDesign(art, strip: false),
  for (final art in atelierArtworks) _atelierDesign(art, strip: true),
];

StarterDesign _atelierDesign(AtelierArtwork art, {required bool strip}) {
  final page = strip ? PageSpec.twoBySix : PageSpec.fourBySixPortrait;
  final babyArt = art.collection == 'Baby shower';
  final baby = babyArt && !strip;
  final goose = art.id.startsWith('atelier_goose');
  return StarterDesign(
    id: '${art.id}${strip ? '-strip' : ''}',
    name: '${art.name}${strip ? ' · Strip' : ''}',
    description:
        '${art.palette.join(', ')} ${art.style}. Editable titles and photo windows.',
    page: page,
    decorations: [art.id],
    category: art.collection,
    collection: art.collection,
    tags: TemplateTags(
      categoryTags: [art.collection.toLowerCase(), art.style.toLowerCase()],
      occasionTags: switch (art.collection) {
        'Baby shower' => ['baby shower', 'family'],
        'Florals' => ['wedding', 'bridal shower', 'anniversary'],
        'Seasonal' => ['holiday', 'celebration'],
        _ => ['celebration', 'wedding', 'birthday'],
      },
      visualStyleTags: [
        art.style.toLowerCase(),
        ...art.palette.map((p) => p.toLowerCase()),
      ],
      defaultCaptureCount: strip
          ? 3
          : baby
          ? 1
          : 2,
    ),
    build: (d) {
      final painting = d[art.id]!;
      return _document(page, [
        _solid(_ivory),
        if (!strip)
          _image(
            page,
            'painting',
            'Decorative artwork',
            painting,
            0,
            0,
            1200,
            1800,
          )
        else ...[
          // Two undistorted 2:3 panels, with the seam behind a photo.
          _image(
            page,
            'painting-top',
            'Decorative artwork, upper',
            painting,
            0,
            0,
            600,
            900,
          ),
          _image(
            page,
            'painting-bottom',
            'Decorative artwork, lower',
            painting,
            0,
            900,
            600,
            900,
          ),
        ],
        for (final (i, y)
            in (strip
                    ? (babyArt ? [120.0, 450.0, 780.0] : [155.0, 565.0, 975.0])
                    : baby
                    ? [goose ? 350.0 : 380.0]
                    : [245.0, 825.0])
                .indexed)
          _slot(
            page,
            i,
            strip
                ? 68
                : baby
                ? (goose ? 280 : 220)
                : 155,
            y,
            strip
                ? 464
                : baby
                ? (goose ? 640 : 760)
                : 890,
            strip
                ? (babyArt ? 270 : 348)
                : baby
                ? (goose ? 640 : 760)
                : 530,
            border: const Stroke(color: ArgbColor(0xFFFFFCF8), widthPt: 3),
          ),
        ShapeLayer(
          id: 'caption-paper',
          zIndex: 0,
          name: 'Caption paper',
          frame: _px(
            page,
            strip
                ? 35
                : baby
                ? 200
                : 125,
            strip
                ? (babyArt ? 1080 : 1370)
                : baby
                ? 180
                : 1400,
            strip
                ? 530
                : baby
                ? 800
                : 950,
            strip
                ? 300
                : baby
                ? 170
                : 300,
          ),
          shape: ShapeKind.rect,
          fill: const ArgbColor(0xFFFFFCF6),
          opacity: 0.95,
        ),
        if (baby)
          ShapeLayer(
            id: 'caption-paper-small',
            zIndex: 0,
            name: 'Caption paper, small',
            frame: _px(page, 370, goose ? 1020 : 1190, 460, 150),
            shape: ShapeKind.rect,
            fill: const ArgbColor(0xFFFFFCF6),
            opacity: 0.9,
          ),
        _text(
          page,
          'title',
          'Event title',
          art.title,
          switch (art.collection) {
            'Art Deco' => const BundledFont(BundledFontFamily.poiretOne),
            'Retro gaming' => const BundledFont(BundledFontFamily.pixelifySans),
            'Disco' => const BundledFont(BundledFontFamily.fredoka),
            _ => _serif,
          },
          strip
              ? (art.collection == 'Retro gaming' ? 12 : 15)
              : baby && art.title.length > 15
              ? 22
              : art.id == 'atelier_gala' || art.collection == 'Retro gaming'
              ? 23
              : 28,
          art.ink,
          strip ? 42 : (baby ? 220 : 150),
          strip
              ? (babyArt ? 1110 : 1400)
              : baby
              ? 200
              : 1430,
          strip ? 516 : (baby ? 760 : 900),
          strip ? 180 : (baby ? 145 : 160),
        ),
        _text(
          page,
          'subtitle',
          'Celebration caption',
          art.subtitle,
          _sans,
          strip
              ? 5.5
              : baby
              ? 6.5
              : 8,
          art.ink,
          strip
              ? 62
              : baby
              ? 380
              : 170,
          strip
              ? (babyArt ? 1270 : 1570)
              : baby
              ? (goose ? 1040 : 1210)
              : 1590,
          strip
              ? 476
              : baby
              ? 440
              : 860,
          110,
          letterSpacingPt: strip
              ? 0.9
              : baby
              ? 0.7
              : 1.6,
        ),
      ], d);
    },
  );
}
