part of 'starter_designs.dart';

/// Occasion stationery uses original transparent artwork over native paper,
/// rules, photo mats and text. There are no flattened captions or photo holes.
final occasionStarterDesigns = [
  for (final theme in occasionThemes) _occasionDesign(theme, strip: false),
  for (final theme in occasionThemes) _occasionDesign(theme, strip: true),
];

StarterDesign _occasionDesign(OccasionTheme theme, {required bool strip}) {
  final page = strip ? PageSpec.twoBySix : PageSpec.fourBySixPortrait;
  final count = strip ? 3 : (theme.hero ? 1 : 2);
  return StarterDesign(
    id: '${theme.designId}${strip ? '-strip' : ''}',
    name: '${theme.name}${strip ? ' · Strip' : ''}',
    description:
        '${theme.collection} stationery with watercolor stickers, '
        'coordinated paper and editable names, date and captions.',
    page: page,
    decorations: [theme.stickerId],
    category: theme.collection,
    collection: theme.collection,
    tags: TemplateTags(
      categoryTags: [theme.collection.toLowerCase()],
      occasionTags: theme.tags,
      visualStyleTags: ['watercolor', 'stationery'],
      defaultCaptureCount: count,
    ),
    build: (assets) {
      final ink = ArgbColor(theme.ink);
      final accent = ArgbColor(theme.accent);
      final width = page.widthPx.toDouble();
      final artwork = assets[theme.stickerId]!;
      ShapeLayer paper(
        String id,
        String name,
        double x,
        double y,
        double w,
        double h,
        ArgbColor color,
      ) => ShapeLayer(
        id: id,
        name: name,
        zIndex: 0,
        frame: _px(page, x, y, w, h),
        shape: ShapeKind.rect,
        fill: color,
      );

      return _document(page, [
        _solid(ArgbColor(theme.paper)),
        paper(
          'outer-rule',
          'Stationery border',
          20,
          20,
          width - 40,
          1760,
          accent,
        ),
        paper(
          'inner-paper',
          'Inset paper',
          24,
          24,
          width - 48,
          1752,
          ArgbColor(theme.paper),
        ),
        if (!strip) ...[
          // Reuse one print-size decode for both stickers. Four-pixel alignment
          // keeps half/quarter-size previews in phase with the print pixels.
          _image(
            page,
            'header-art',
            'Occasion illustration',
            artwork,
            60,
            104,
            272,
            272,
          ),
          _text(
            page,
            'occasion',
            'Occasion',
            theme.collection.toUpperCase(),
            _sans,
            7,
            ink,
            350,
            70,
            720,
            60,
            letterSpacingPt: 1.4,
          ),
          _text(
            page,
            'title',
            'Event title',
            theme.title,
            _serif,
            22,
            ink,
            360,
            135,
            710,
            220,
          ),
          paper('title-rule', 'Title underline', 370, 375, 660, 3, accent),
        ] else ...[
          _text(
            page,
            'occasion',
            'Occasion',
            theme.collection.toUpperCase(),
            _sans,
            5.5,
            ink,
            50,
            45,
            500,
            45,
            letterSpacingPt: 1,
          ),
          _text(
            page,
            'title',
            'Event title',
            theme.title,
            _serif,
            14,
            ink,
            50,
            102,
            500,
            145,
          ),
        ],
        for (var i = 0; i < count; i++) ...[
          paper(
            'photo-mat-${i + 1}',
            'Photo ${i + 1} mat',
            strip ? 53 : 93,
            (strip ? 278 : 443) + i * (strip ? 365 : 515),
            strip ? 494 : 1014,
            strip ? 344 : (theme.hero ? 1014 : 489),
            accent,
          ),
          _slot(
            page,
            i,
            strip ? 60 : 100,
            (strip ? 285 : 450) + i * (strip ? 365 : 515),
            strip ? 480 : 1000,
            strip ? 330 : (theme.hero ? 1000 : 475),
            border: const Stroke(color: ArgbColor(0xFFFFFDFA), widthPt: 2),
          ),
        ],
        _image(
          page,
          'footer-art',
          'Occasion keepsake',
          artwork,
          strip ? 180 : 48,
          strip ? 1376 : 1472,
          strip ? 240 : 272,
          strip ? 240 : 272,
        ),
        _text(
          page,
          'subtitle',
          'Celebration caption',
          theme.subtitle,
          _sans,
          strip ? 5.3 : 7.5,
          ink,
          strip ? 50 : 340,
          strip ? 1620 : 1505,
          strip ? 500 : 730,
          strip ? 85 : 115,
          letterSpacingPt: strip ? 0.4 : 0.7,
        ),
        _text(
          page,
          'personalization',
          'Names and date',
          'NAME • DATE',
          _sansStrong,
          strip ? 6.5 : 9,
          ink,
          strip ? 50 : 340,
          strip ? 1710 : 1650,
          strip ? 500 : 730,
          60,
          letterSpacingPt: 1,
        ),
      ], assets);
    },
  );
}
