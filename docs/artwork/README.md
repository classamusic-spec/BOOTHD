# Atelier artwork and sticker collection

Created October 23, 2026; integrated and verified October 24, 2026.

The app bundles **20 background illustrations**, **56 transparent PNG stickers**, and **88 illustrated presets**: the original 40 Atelier designs plus 48 occasion designs. Each theme has an editable 4×6 portrait and 2×6 strip companion. The existing essential designs and 18 procedural decorations remain available. All artwork works offline after installation.

The collection covers watercolor florals, baby showers, coastal and seasonal celebrations, Gatsby-inspired Art Deco, retro arcade and platformer parties, and 1970s disco. Baby-shower palettes include sage and oatmeal, blush and pearl, and powder blue and butter yellow.

## Occasion expansion — October 24, 2026

Twenty occasion collections add 24 original stickers and 48 editable presets:

| Collection | Artwork / theme |
| --- | --- |
| Wedding | Silk & Vows — gold rings, ivory bow and eucalyptus |
| Birthday | Make a Wish — blush birthday cake; dinosaur, unicorn, pirate and space parties |
| Anniversary | Golden Together — intertwined gold hearts and roses |
| Easter | Easter Garden — rabbit, painted eggs and daisies |
| Christmas | Christmas Keepsake — heirloom baubles, evergreen and ribbon |
| Engagement | The Sweetest Yes — velvet ring box |
| Bridal shower | Pearls & Petals — silk bow, pearls and a rose |
| Hen & stag | Last Fling — cocktails and mirrorball |
| Graduation | The Next Chapter — mortarboard and diploma |
| Halloween | Moonlit Mischief — friendly pumpkin and witch hat |
| New Year | Midnight Wishes — midnight clock and streamers |
| Valentine | Love Letters — heart-sealed envelope |
| Thanksgiving | Harvest Table — pumpkins, wheat and autumn leaves |
| Retirement | The Good Life — vintage suitcase and sunhat |
| Housewarming | Home Sweet Home — cottage and new keys |
| Christening | Blessed Beginnings — dove and olive branch; also tagged for baptism and communion |
| Diwali | Festival of Light — diya and marigolds |
| Eid | Moonlit Celebration — brass lantern, crescent and stars |
| Hanukkah | Eight Bright Nights — nine-candle hanukkiah |
| Summer party | Sunshine Social — citrus and hibiscus |

Occasion presets use native editable paper, rules, photo mats, titles, captions and a **NAME • DATE** text layer. Portraits have one large photo or two landscape photos; strips have three photos. Stickers remain independent layers. Occasion aliases such as `xmas`, `bachelorette`, `dinosaur`, `chanukah` and `deepavali` work in search. Template collection filters are derived from the catalog so new collections are available automatically.

## Make a custom template

1. Open **Templates → New template**. Search by occasion or color, select a collection, or choose **Blank pages**.
2. In the studio, select **Artwork → Stickers & art**. Search by name or theme and filter the collection. **Transparent stickers** and **Backgrounds** are separate views.
3. Tap an asset to place an editable image layer. Move, resize, rotate, duplicate, or reorder it with the studio's existing controls. Stickers can overlap photo edges without being clipped by the photo slots.
4. Edit the title and caption, save, and export the template package or use it for an event. Artwork is copied into managed storage and travels with the package.

## Collection inventory

- Florals: rose and peony bouquet, blue hydrangeas, wildflower corner, lavender sprigs, eucalyptus crescent, sunflowers.
- Geese and baby: blue-bow goose, sage-bow goose, mother goose and goslings, flying goose, heirloom teddy, moon and stars.
- Ribbons: blue gingham, blush satin, sage linen.
- Art Deco: gilded fan, champagne feathers, geometric corner, champagne coupes, gold sunburst.
- Disco: mirrorball, flower-power daisies, roller skate, vinyl record.
- Retro gaming: controller, joystick, mushroom, star, coins, cloud island, green pipe, pixel hearts.

## Art direction and trend research

Research was reviewed on October 23, 2026. It informed the palette and motifs; source photographs were not downloaded or included in the app.

- [Babylist's baby-shower theme guide](https://www.babylist.com/hello-baby/baby-shower-themes), updated April 10, 2026, describes Baby in Bloom, woodland, locally grown, and western themes. This supported a floral and botanical collection with multiple palettes.
- [River Fox Events' 2026 styling guide](https://riverfoxevents.co.uk/journal/baby-shower-themes-2026/) describes sage, oatmeal and ivory palettes, bows, storybook animals, moon/cloud motifs and buttery yellow. These are styling observations, not market-share measurements.
- [Minimalist Mama's spring shower ideas](https://minimalistmama.co/baby-shower/spring-baby-shower-ideas) includes Mother Goose with goose motifs, florals, wicker, gingham and ribbons. The new goose backgrounds and separate bow stickers interpret that direction.

## Source and verification

The built-in OpenAI `image_gen` tool generated these assets. Background requests used opaque portrait canvases; sticker requests explicitly used `transparent_background: true`. PNGs were copied unchanged into `assets/decorations/`. The stickers are 1254×1254; backgrounds are 1024×1536. No runtime image-generation service is required.

Exact prompt sets are in `atelier-prompts.json`, `celebration-prompts.json`, `sticker-prompts.json`, and `occasion-prompts.json`. File hashes, dimensions and byte lengths are in `atelier-manifest.json`, `sticker-manifest.json`, and `occasion-manifest.json`; every asset is also listed in `../ASSET_PROVENANCE.md`.

Captions, photo windows and mats are native editable document layers. The export uses the shared scene renderer at the page's 300 dpi dimensions. The background source resolution is recorded explicitly; it is not described as a native 300 dpi painting.

Recreate the visual review sheets with:

```sh
flutter test --no-pub tool/art/render_atelier_test.dart tool/art/render_occasions_test.dart tool/art/render_stickers_test.dart
```

They write `build/local-verification/atelier-catalog/collection-overview.png` and `sticker-overview.png`. The sticker sheet composites each original over light and dark surfaces for edge inspection. Asset tests decode all alpha channels, check transparent space and visible content, and verify committed hashes. Starter-design tests save, reopen and render every preset without warnings. Editor parity tests compare the live canvas, preview and reduced print export without relaxing their tolerances.

The occasion review sheet and individual full-resolution prints are written to `build/local-verification/occasion-catalog/`, including `occasion-overview.png`.

## Adding stickers in the builder

Choosing a transparent decoration from **Artwork → Stickers & art** now adds a
manageable sticker inside the print-safe margin. The builder prefers space
clear of text, photos and existing stickers. On a full page it minimizes
overlap; you can still drag it wherever you want. Stickers keep their source
proportions, remain independent layers above photos, and can be moved, resized,
rotated, reordered, undone and saved like other artwork.

Occasion presets use separated title/artwork boxes and consistent artwork sizes
aligned to print pixels, verified against the canvas, preview and 300 dpi export.
Generate editor screenshots at both tablet platforms' portrait and landscape
viewport sizes with:

```sh
flutter test --no-pub tool/art/render_sticker_builder_test.dart
```

Screenshots are written to `build/local-verification/sticker-builder/`. The app
flow audit and verification limits are in `../APP_FLOW_AUDIT_2026-10-26.md`.
