# Asset provenance and licences

Every file the app ships from `assets/`, plus fonts, icons and artwork that
reach the screen by other routes (AC-0211, CR-001 item 8). The table of
bundled files is checked by `test/core/app_info_and_licences_test.dart`:
adding, removing or changing a file without updating its row fails the
build.

## Bundled files

| Path | SHA-256 | Source | Licence |
| --- | --- | --- | --- |
| `assets/decorations/arcade_marquee.png` | `8c81ba925e2259fa8cc54d98565577998c89d3b139e32776b93405b53029378d` | Original; drawn by `tool/art/decorations.dart` with `lib/core/design_system/party_art.dart` (EP05) | Project-owned |
| `assets/decorations/blossom_corner.png` | `5ad9d9ea9358b7d5a5a860f6bf22216fd697e137136d1812e373d9f256c5e968` | Original; drawn by `tool/art/decorations.dart` (M05) | Project-owned |
| `assets/decorations/blossom_corner_champagne.png` | `65718cedc19e0efc3a2864ee90465dcd077de9b5cb8c2a4113a61edb7fb4476c` | Original; drawn by `tool/art/decorations.dart` (M05) | Project-owned |
| `assets/decorations/blossom_garland.png` | `b939b075d3e91ee70df9432d201cfa1c0eab984dafad7be0ead3f0a988126248` | Original; drawn by `tool/art/decorations.dart` (M05) | Project-owned |
| `assets/decorations/blossom_sprig.png` | `cdb9a778f97e8d176e790c66628f692c6b69b33d1d8c8249c7e8c4c3a482dd03` | Original; drawn by `tool/art/decorations.dart` (M05) | Project-owned |
| `assets/decorations/film_edges.png` | `55bbd52b833a84af60d4ab29347d1054bfdb38f8691ece12c7e74c711beec890` | Original; drawn by `tool/art/decorations.dart` (M05) | Project-owned |
| `assets/decorations/gold_confetti.png` | `128c37f9fff17b7fe70ed46b7022fe8a4eb57c8eb1d758422d1737bcc1ad44a7` | Original; drawn by `tool/art/decorations.dart` (M05) | Project-owned |
| `assets/decorations/gold_frame.png` | `288d46b89ea97ce273a582fce419a2520aff6d5cb7bcf2c5b875cf929a13394e` | Original; drawn by `tool/art/decorations.dart` (M05) | Project-owned |
| `assets/decorations/gold_frame_strip.png` | `213d6a63c6267ab4e2cb0c981c31d305cbc9696c2649e5246cbaa5cc61b2d977` | Original; drawn by `tool/art/decorations.dart` (M05) | Project-owned |
| `assets/decorations/party_balloons.png` | `2097d07faae429d64dfaf0a2aa5576bbd0143b1916a5222cd280f98631b0d513` | Original; drawn by `tool/art/decorations.dart` with `lib/core/design_system/party_art.dart` (EP04) | Project-owned |
| `assets/decorations/party_bunting.png` | `57407a7e75aad7e7124a520c0fc9ccdbc961a5c18735d6debc9744af62d2a862` | Original; drawn by `tool/art/decorations.dart` with `lib/core/design_system/party_art.dart` (EP04) | Project-owned |
| `assets/decorations/party_confetti.png` | `508b66ecc3fb27d29cba1b53a58f8873628f21280a745aa8cc8676083f9ee394` | Original; drawn by `tool/art/decorations.dart` with `lib/core/design_system/party_art.dart` (EP04) | Project-owned |
| `assets/decorations/party_stars.png` | `2301665e5853df8c2e12cb9d8de12894ab4d87d402ae50c3a6d396ff9dde4f9f` | Original; drawn by `tool/art/decorations.dart` with `lib/core/design_system/party_art.dart` (EP04) | Project-owned |
| `assets/decorations/pixel_coins.png` | `26982fbd6d8d9a99343c45c8bcb8ca35449945688ad8548505b19e38548fdd8b` | Original; drawn by `tool/art/decorations.dart` with `lib/core/design_system/party_art.dart` (EP05) | Project-owned |
| `assets/decorations/pixel_frame.png` | `b6e778310d52723ee276d3e5c3c909a7d525822879064f1cd547373a84ac40d8` | Original; drawn by `tool/art/decorations.dart` with `lib/core/design_system/party_art.dart` (EP05) | Project-owned |
| `assets/decorations/pixel_frame_strip.png` | `218aee7be5391e7a7cd9152edbe8d56321b7586bc646a09cb5b172ab7e151944` | Original; drawn by `tool/art/decorations.dart` with `lib/core/design_system/party_art.dart` (EP05) | Project-owned |
| `assets/decorations/pixel_hearts.png` | `352261d6c7476dfea5e7482c7aa64bb76ee4156ad31aa34e1abeb05cba3c84a2` | Original; drawn by `tool/art/decorations.dart` with `lib/core/design_system/party_art.dart` (EP05) | Project-owned |
| `assets/decorations/pixel_stars.png` | `f6a08e88bb1d2601e282cc9ff127dfaf7e09b78f84c1a8573dfde0da6a216dce` | Original; drawn by `tool/art/decorations.dart` with `lib/core/design_system/party_art.dart` (EP05) | Project-owned |
| `assets/fonts/cormorant_garamond/CormorantGaramond-Medium.ttf` | `8eaa2a57728fe1f65647cd0e0bc2733907ac07e8d6921fe2f80b97cdca9fd0db` | CatharsisFonts/Cormorant `fonts/ttf/`, commit `6d210fd` (Version 4.001) | SIL OFL 1.1 |
| `assets/fonts/cormorant_garamond/CormorantGaramond-SemiBold.ttf` | `d0934e611e2e930614ffc3675f824bdf1960c88bc44ebcd73ff162beb31ac8e3` | CatharsisFonts/Cormorant `fonts/ttf/`, commit `6d210fd` (Version 4.001) | SIL OFL 1.1 |
| `assets/fonts/cormorant_garamond/OFL.txt` | `60700d351cac4650c51f3f9db318d2a420f8b45052dba2715eb5fec41f0f6956` | `OFL.txt` from CatharsisFonts/Cormorant, commit `6d210fd` | Licence text |
| `assets/fonts/courier_prime/CourierPrime-Bold.ttf` | `ff1f38786c849d1c41fa8e447960abdb2bd75fdfb0cfcdeb524fad65a5af3638` | google/fonts `ofl/courierprime/CourierPrime-Bold.ttf`, commit `45e3d52` | SIL OFL 1.1 |
| `assets/fonts/courier_prime/CourierPrime-Regular.ttf` | `72f793376f8e2841656bf21d77a5de010f2929bd6956a22ee848ad0c7eb978af` | google/fonts `ofl/courierprime/CourierPrime-Regular.ttf`, commit `45e3d52` | SIL OFL 1.1 |
| `assets/fonts/courier_prime/OFL.txt` | `9a755af092b494944c99f471be6fddd19b006a448fefdc4717e4ee0aa09a97b0` | `OFL.txt` from google/fonts `ofl/courierprime/`, commit `45e3d52` | Licence text |
| `assets/fonts/fredoka/Fredoka-Variable.ttf` | `2ba02e68b152868aef9ba28e24b3648c7d457fe6f25c761f2c2c53fb61a73fc8` | google/fonts `ofl/fredoka/Fredoka[wdth,wght].ttf`, commit `45e3d52` | SIL OFL 1.1 |
| `assets/fonts/fredoka/OFL.txt` | `5c9e7eee5c6b25f4b05b8d53b2e470ea4962f9ced742d044a98f7d95d1375bab` | `OFL.txt` from google/fonts `ofl/fredoka/`, commit `45e3d52` | Licence text |
| `assets/fonts/inter/Inter-Medium.ttf` | `97ad806f526e41546d46365bb3a393145f75b7b1568913db74549ad8b8dba872` | Inter 4.1 release, `Inter-4.1.zip` `extras/ttf/`, rsms/inter (Version 4.001) | SIL OFL 1.1 |
| `assets/fonts/inter/Inter-Regular.ttf` | `40d692fce188e4471e2b3cba937be967878f631ad3ebbbdcd587687c7ebe0c82` | Inter 4.1 release, `Inter-4.1.zip` `extras/ttf/`, rsms/inter (Version 4.001) | SIL OFL 1.1 |
| `assets/fonts/inter/Inter-SemiBold.ttf` | `78a843fade9d4612a5567302fb595b56976eb5fcebf4fea5a5912d638bafcde3` | Inter 4.1 release, `Inter-4.1.zip` `extras/ttf/`, rsms/inter (Version 4.001) | SIL OFL 1.1 |
| `assets/fonts/inter/OFL.txt` | `262481e844521b326f5ecd053e59b98c8b2da78c8ee1bdbb6e8174305e54935a` | `LICENSE.txt` from the same Inter 4.1 release | Licence text |
| `assets/fonts/monoton/Monoton-Regular.ttf` | `951c4cea65ffede784a7c9672feec5d329a7e1e12216c42d53ecf36c90d04dea` | google/fonts `ofl/monoton/Monoton-Regular.ttf`, commit `45e3d52` | SIL OFL 1.1 |
| `assets/fonts/monoton/OFL.txt` | `585c6d2da8bcd8ffa651e0016f2e992a6891b625143a46a1dacf00699a817d9a` | `OFL.txt` from google/fonts `ofl/monoton/`, commit `45e3d52` | Licence text |
| `assets/fonts/pixelify_sans/OFL.txt` | `b66ba46f511a851ab09998b5a5a9fdbb102545a3864cb993095e1745996873a7` | `OFL.txt` from google/fonts `ofl/pixelifysans/`, commit `45e3d52` | Licence text |
| `assets/fonts/pixelify_sans/PixelifySans-Variable.ttf` | `9ba86cd010a4de309d263ceff8e8044092c9db7efda869620cb9ff1c4389e8a5` | google/fonts `ofl/pixelifysans/PixelifySans[wght].ttf`, commit `45e3d52` | SIL OFL 1.1 |
| `assets/fonts/poiret_one/OFL.txt` | `708e33bed791c40638926a7577bcef8ff8748f84045f3825277540cbb8d483ba` | `OFL.txt` from google/fonts `ofl/poiretone/`, commit `45e3d52` | Licence text |
| `assets/fonts/poiret_one/PoiretOne-Regular.ttf` | `457f2d03263f58e5a6dbcc1b607b10dff6581e7cf9c4ebdf330ec3e6772a3558` | google/fonts `ofl/poiretone/PoiretOne-Regular.ttf`, commit `45e3d52` | SIL OFL 1.1 |
| `assets/sounds/arcade-start.wav` | `58f2168919e240578531ec6c99ca0bbd535393738d77673e58b689ea11e61dce` | Original placeholder; synthesised by `tool/audio/generate_sounds.py` (EP03) | Project-owned |
| `assets/sounds/cheer-confirm.wav` | `733e8efd53b97edcaa3e82999a75746aa9e48abf6e0789f44548de78a4734d5b` | Original placeholder; synthesised by `tool/audio/generate_sounds.py` (EP03) | Project-owned |
| `assets/sounds/countdown-tick.wav` | `c9d64830b3c3ece3b001b6f68454a96c244774ccd3b3e8401fdb9b91e48e330e` | Original placeholder; synthesised by `tool/audio/generate_sounds.py` (EP03) | Project-owned |
| `assets/sounds/disco-pulse.wav` | `7ce6b33b60dba335a7748d8db4b4623c20eb129bd11a6a7fb6aabbf0e7f32632` | Original placeholder; synthesised by `tool/audio/generate_sounds.py` (EP03) | Project-owned |
| `assets/sounds/film-tick.wav` | `e7990d57d120d9f1e5d700ef6e7a031ed88e6b57eaf7dd9078a4f7c153bf9b7c` | Original placeholder; synthesised by `tool/audio/generate_sounds.py` (EP03) | Project-owned |
| `assets/sounds/gala-bell.wav` | `c09d353affd98a2f2b57da55713b7d34d66ad9d44956c9c408bfc68f78c9f27d` | Original placeholder; synthesised by `tool/audio/generate_sounds.py` (EP03) | Project-owned |
| `assets/sounds/garden-twinkle.wav` | `2d5b7013c9ed34c5f355c83de0fe25bc9a846b456ee6083c369aa8cae7d82337` | Original placeholder; synthesised by `tool/audio/generate_sounds.py` (EP03) | Project-owned |
| `assets/sounds/level-complete.wav` | `a884db9ad4cb07c4b2ccc13b87e1caa47dbb62d2ff404d96b84dcd88090c1c12` | Original placeholder; synthesised by `tool/audio/generate_sounds.py` (EP03) | Project-owned |
| `assets/sounds/party-chime.wav` | `7dd9f8bf622d782eb855e2afb4c5fbe9f673e50d5edf6404f2fb06d77015a284` | Original placeholder; synthesised by `tool/audio/generate_sounds.py` (EP03) | Project-owned |
| `assets/sounds/porcelain-chime.wav` | `81331bf8015a235adb3407ebde3d33bbbc812ea3823b5ca6d19fadbd98f24328` | Original placeholder; synthesised by `tool/audio/generate_sounds.py` (EP03) | Project-owned |
| `assets/sounds/porcelain-tap.wav` | `03d687b7eb724b3e1b99f34fd9b348d28bdbc8460eff06f12c937f8a3c9e23be` | Original placeholder; synthesised by `tool/audio/generate_sounds.py` (EP03) | Project-owned |
| `assets/sounds/select-beep.wav` | `d77b44c9e20f3d6a0276b49b24948015e974fc2072c2b8cef4fd1a752c356761` | Original placeholder; synthesised by `tool/audio/generate_sounds.py` (EP03) | Project-owned |
| `assets/sounds/shutter-soft.wav` | `6bad9689a1944b40d3bd6742e759022b95109d34e50d53bd685b9f0ab33ba4db` | Original placeholder; synthesised by `tool/audio/generate_sounds.py` (EP03) | Project-owned |
| `assets/sounds/soft-pop.wav` | `f0dc58e804178fc35952f013a2889aa4e08036667852b38135b3a55b2dfe4ff4` | Original placeholder; synthesised by `tool/audio/generate_sounds.py` (EP03) | Project-owned |
| `assets/sounds/toy-press.wav` | `1a010dc76cdb9e02125930bf541edb0c60e05cd7a4e3242ee2a8c35030658511` | Original placeholder; synthesised by `tool/audio/generate_sounds.py` (EP03) | Project-owned |
| `assets/sounds/wood-click.wav` | `9d3bda835c7a9f7abadf26029c0fbb1326280bc929d8df59cbc3f0968a59c85f` | Original placeholder; synthesised by `tool/audio/generate_sounds.py` (EP03) | Project-owned |

Fonts are unmodified upstream files: static instances, except Fredoka
and Pixelify Sans, which ship as Google Fonts' variable files (renamed
only, from `Fredoka[wdth,wght].ttf` and `PixelifySans[wght].ttf`, since
Flutter asset paths avoid brackets). Monoton carries the Reserved Font
Name "Monoton"; it is used unmodified, which the OFL allows. No other
family has one. Licence texts are bundled and shown on the app's
licence page (Settings, About, Open licences), registered by
`lib/core/design_system/bundled_licences.dart`.

- Inter: Copyright 2016 The Inter Project Authors
  (https://github.com/rsms/inter). Downloaded from
  `https://github.com/rsms/inter/releases/download/v4.1/Inter-4.1.zip`
  (archive SHA-256
  `9883fdd4a49d4fb66bd8177ba6625ef9a64aa45899767dde3d36aa425756b11e`).
- Cormorant Garamond: Copyright 2015 The Cormorant Project Authors
  (github.com/CatharsisFonts/Cormorant), designer Christian Thalmann.
  Downloaded from
  `https://raw.githubusercontent.com/CatharsisFonts/Cormorant/6d210fd3550b7358ca62d6ba3e354ec1ec940813/fonts/ttf/`,
  the commit Google Fonts builds its release from.
- Guest experience fonts (EP02, owner decision 4.5), each with its OFL
  1.1 text checked before use, from
  `https://raw.githubusercontent.com/google/fonts/45e3d5269e4a17d823f6d84470bc084dc5ae46f6/ofl/<family>/`:
  Courier Prime (Copyright 2015 The Courier Prime Project Authors,
  designer Alan Dague-Greene), Fredoka (Copyright 2016 The Fredoka
  Project Authors, designers Milena Brandão and Hafontia), Monoton
  (Copyright 2011 Vernon Adams, Reserved Font Name "Monoton"), Pixelify
  Sans (Copyright 2021 The Pixelify Sans Project Authors, designer Stefie
  Justprince), Poiret One (Copyright 2011 The Poiret One Project Authors,
  designer Denis Masharov). None imitates a game, console or brand
  typeface; Pixelify Sans is an original pixel design.

## Icons

Material Symbols Rounded (Google, Apache License 2.0), through the
`material_symbols_icons` package 4.2960.0 (font version 2.960, pinned in
`pubspec.lock`). The package's licence is included in the app's licence
page automatically and listed in `docs/DEPENDENCY_LICENSES.md`. Only
`lib/core/design_system/porcelain_icons.dart` refers to the package; release
builds keep only the glyphs the app uses (icon tree shaking).

## Artwork

The botanical line art (sprigs, wreath, flourish), the wordmark medallion,
template thumbnails and theme swatches are original to this project and
drawn in code (`lib/shared/widgets/botanical_ornament.dart` and the widgets
that use it). Nothing from the 15-screen concept board or the owner's
reference boards (`reference/`, CR-002) is used: no artwork, photographs,
sample people, names or dates (UX-09, CR-001 fix 12).

The original procedural template decorations in `assets/decorations/` (M05) are raster
artwork that ships. They are original too: painted in code by
`tool/art/decorations.dart` with the floral painter in
`lib/core/design_system/floral_art.dart` (seeded, so the same every run)
and written out by `flutter test tool/art/generate_decorations_test.dart`.
`test/assets/decorations_current_test.dart` fails if a committed file no
longer matches its generator. The slot placeholder that stands in for a
guest photo in the editor and previews is drawn at run time
(`lib/core/templates/slot_placeholder.dart`) and never stored.

## Atelier and celebration artwork — 2026-10-23

20 background illustrations and 32 transparent stickers were generated with the built-in OpenAI image_gen tool for this project. The prompt sets and hash/dimension manifests are committed in `docs/artwork/`. These are generated assets, not downloaded stock artwork. Template captions, photo windows, mats and transforms remain editable native layers. The original 18 procedural decorations remain available.

| Asset | SHA-256 | Source | Rights record |
| --- | --- | --- | --- |
| `assets/decorations/atelier_arcade.png` | `07b7ff7cf24a5d6cb08c9653e95b52fc25737477f03ca4610fd75871d6ebf11b` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/atelier_autumn.png` | `d58f0b6566db486ed996c376e0a10d170ddb04a3e8b191296f5b10e51abe015d` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/atelier_baby_blue.png` | `25fa5b86815d19ae58a121938b6abf98134632ed45d3f39948391ab328827510` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/atelier_baby_blush.png` | `f88e8a986f13dc087262a0aedd4f189a3365bb3f4dd69b8b5dee0777149dd1e0` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/atelier_baby_sage.png` | `b2ea7400e72204d75e4f7ff2ccb549a67849db71b917207be1322ec24e4a4dd3` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/atelier_coast.png` | `e2817b7030c64e16f36864eb79eddd9175110b82f436f0e150317a3a97a65fd1` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/atelier_deco_emerald.png` | `4ad487575b83ba8a3cff22613d105d723881d580c52f4eca0fe56e0337bec0c8` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/atelier_deco_gold.png` | `fd14fdd7109007881fd18c69d53c8e10a734c1979b0795bfed9ce8caf74aaad1` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/atelier_disco_midnight.png` | `6cd4e69986219ef5afb6e62c4d0d65430dee6246c46c856fd02dfb3e353c0b63` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/atelier_disco_sunset.png` | `c07ac311c6cc0835285ab9bf35bed8e6f580b3ae09281f964a255c1f7ccad046` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/atelier_gala.png` | `cb5b9d52eb6b21cc5c807c715dc92a2105fc04e7b88ef0a95ef6ac5ad694d9ac` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/atelier_goose_blue.png` | `32dd7f27fb54187ff10ebd3844e49ddae2f766daf5af57272dd0be5fff564bd0` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/atelier_goose_sage.png` | `241891ab5482e03cb919aec9516206e9554a76d28053795065ae951785097961` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/atelier_holiday.png` | `1fb4d3541f05738c3765c79adb43672b6ed6c271b2edb80f65eabfac01264ef0` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/atelier_hydrangea.png` | `be35fac73a4a2a7808a7ef5742724453b5ddedf8ab154df9f82c88c7da71ef0b` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/atelier_lavender.png` | `cd332bd0cf6ae12e3783a896d20b1aaf2c702d6e373fe14a5bb8100fa1f43efc` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/atelier_meadow.png` | `df94058e59581c2e902e5259b429154e4aff2b3cb338554361fdee333720ccc3` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/atelier_platformer.png` | `a313230d3aacfa3b463920f6d8593f33b3567fef64ba197189868a3b3f3529c2` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/atelier_rose.png` | `96f8381b56af56acd36d62205a262b785e7f04eb304f0fec052b64bf1a7c16a3` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/atelier_tropical.png` | `9f3ff5cfbb73feed85ad54276e930a64080996804eefd19f26820c1117e41f28` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/sticker_arcade_joystick.png` | `e326a006bfc7bd04a5b68e67c945a3f293785439e232be7cf54c84ebf6ef2ac1` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/sticker_blue_hydrangea.png` | `59518932e22ccf0aae495c593cfa715573e0abead066ca02854f586c94324783` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/sticker_bow_blue.png` | `68a2ee3a898941ac189b224c2a45f0ea935751b16fc33358bf984c8b245f3821` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/sticker_bow_blush.png` | `c489c075048fdfbe98e9f457a430bb1ebf2c22bdfd0a4f05358283966c5b686b` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/sticker_bow_sage.png` | `16161bf20d1bdb910325b4fee67b2d8e381890f723203e3fae9d176364d9f0ed` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/sticker_champagne_coupes.png` | `4118a468eba46cbe89a4d011d194aaff079488dfe9183250b53d0ce9f5ed4988` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/sticker_deco_corner.png` | `610faecdb52b6aa31fea9d9387cd039af65a547061aefb3356849d72c2adf76f` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/sticker_deco_fan.png` | `a0d26be4a3304094a722807e37d88c48345f17ea1d956e3a86f0c0e3f8f447af` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/sticker_deco_feathers.png` | `2671c03614e9968221a908643c537dfe90c11486db7b96da28fdc9895d09ee7a` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/sticker_deco_sunburst.png` | `15415622ceac132695ec30d39ae626a136fd38fbbaf07eb9cedad137923aa868` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/sticker_disco_ball.png` | `40043b505cdb844448cd245aa7e08c3b8c93f4dc1b226148974a58f20ab8c4e5` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/sticker_disco_daisies.png` | `832a22f9fdb63839f1bd0dbd748607a8074b8bf36f139ed223a70a8c54e6c417` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/sticker_eucalyptus_crescent.png` | `285711c6c1faafb5a133923a41f715aae4878a96673b567a6ad7793ec4e9d9f0` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/sticker_game_cloud.png` | `6e48615a6de3f613f5f430fa73868355a5fa0cb274611da353ae979227209325` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/sticker_game_coins.png` | `cc4c80ffb6af5540c2cfaf0100436dc2f8b85cb8df5261f02eba46748dd4614e` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/sticker_game_controller.png` | `efb7c5adda6bb0acc0ab6a7b71f1b9ae60c6e6edcbe864e2e944b5254ee22c32` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/sticker_game_mushroom.png` | `c885d4e87bb674a2762dfbb8f7a1c22c52f4948454e7d2f114fe9845e35fc5bc` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/sticker_game_pipe.png` | `6e9df6f64b78dddbcc947a1ae41453d786b54453c1aa97d74d7d49955b915e79` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/sticker_game_star.png` | `8da9caefcf1ade0a1b9911679615b6ce500116a8ff16012c8551a72e712b1ceb` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/sticker_goose_blue.png` | `d73180ba550477f19456a5b107be74cbb208cb5798432998df7e4863a74b1544` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/sticker_goose_family.png` | `7fc6e2407e243427231b3007ac432eabc25a77ffa73b6a938bb2df7aa2155501` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/sticker_goose_flying.png` | `53a04469e65c0837af85c01ec4942cb412432f5a0286dd85f939dff20f4a415e` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/sticker_goose_sage.png` | `b960124537124f74399d7bd9a64b4e24b71e7e26eaa54de81433da5ea05c8653` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/sticker_lavender_sprigs.png` | `6cd2673e3c14870574ba4f8ef7028beda82dfc039917dffa2b76d565566d9a32` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/sticker_moon_cloud.png` | `b07bb3d850d6c8da4891cbc5854619b40dbe5190148782ca622187acd687f6d2` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/sticker_pixel_hearts.png` | `bbd500348e0fbbc385e6df7c3a5122f5b1886d1bb375067fb56ca5617d864e25` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/sticker_roller_skate.png` | `be1131c788d4c001a5502897a6ff995fefb103e0f185f7cd5c96f8eda5d5d99c` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/sticker_rose_bouquet.png` | `80aa4d9ece9024a76f3b5bd4c259f91ca5cfa2db9f692cdd3926cdd0224e6b37` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/sticker_sunflower_spray.png` | `62cd00af3d47c07465277510e64a421f4ba0206bb377aa06be680e1ef268ced2` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/sticker_teddy.png` | `06d7f83cb84afb06e7f773fc9e056f93c98a7e7183248f85e4839ab44650e6c2` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/sticker_vinyl.png` | `2b04597c9797a0b6ec9385c78595bc480f310719e1a249fe67956e9587c6ac67` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |
| `assets/decorations/sticker_wildflower_corner.png` | `51a23a59f2fc9142bbd1c939752514e3a0e8c52a5834371ab3303b8dcd1eb71f` | Generated with OpenAI image_gen, 2026-10-23; prompts in `docs/artwork/` | Generated for this project |

## Occasion collection — October 24, 2026

24 original transparent watercolor stickers generated with the built-in OpenAI `image_gen` tool with `transparent_background: true`. Originals were copied unchanged into the app bundle. Exact prompts: `docs/artwork/occasion-prompts.json`; dimensions, byte lengths and hashes: `docs/artwork/occasion-manifest.json`. No remote asset dependency or runtime generation service. Matching portrait and strip templates use native editable text, shapes and photo slots.

| Asset | SHA-256 | Source | Rights / licence |
| --- | --- | --- | --- |
| `assets/decorations/sticker_wedding_rings.png` | `4a4a43befeaef8e665dc170dbaf6774a3c97b99eb593c4764ba73bf1fc56266f` | Original; built-in OpenAI image_gen, October 24, 2026 | Project-generated artwork |
| `assets/decorations/sticker_birthday_cake.png` | `5d0e578c48b2b444f8efd1d2e262d763af81b5f04ee7d84ed30fffb495d5421e` | Original; built-in OpenAI image_gen, October 24, 2026 | Project-generated artwork |
| `assets/decorations/sticker_anniversary_hearts.png` | `678737aa937ecacf586d657d4fcb131a907d2ba077961c5deeb6c95572fc5646` | Original; built-in OpenAI image_gen, October 24, 2026 | Project-generated artwork |
| `assets/decorations/sticker_easter_bunny.png` | `e67e9935e85e9dcc5e61ae38835d789665be5f6130c9dd0a1a16f31eb5dba144` | Original; built-in OpenAI image_gen, October 24, 2026 | Project-generated artwork |
| `assets/decorations/sticker_christmas_bauble.png` | `1ba400d3052162b76adc3debf0025a73a9b4c9a22690510e0e2ca6822c1eaf0c` | Original; built-in OpenAI image_gen, October 24, 2026 | Project-generated artwork |
| `assets/decorations/sticker_engagement_ring.png` | `152eebbd1337deb64c74e8cca94eb21a853c05fc383f77410e508ab028fb5449` | Original; built-in OpenAI image_gen, October 24, 2026 | Project-generated artwork |
| `assets/decorations/sticker_bridal_pearls.png` | `9f1958453ebc06d890ed4ad6e7ad3ff89290c8d4a699fd83aaf0da37713c5f0a` | Original; built-in OpenAI image_gen, October 24, 2026 | Project-generated artwork |
| `assets/decorations/sticker_party_cocktails.png` | `78b555c6c29872b2e1f5d8da9eb5534e2b14df9bf7816683a42537650718554c` | Original; built-in OpenAI image_gen, October 24, 2026 | Project-generated artwork |
| `assets/decorations/sticker_graduation_cap.png` | `0f322c9800677b2e1d156bd9fa058f9b0dd7a8994a154be381f070eeebfbb678` | Original; built-in OpenAI image_gen, October 24, 2026 | Project-generated artwork |
| `assets/decorations/sticker_halloween_pumpkin.png` | `fc961852129af06ab392fcc96a1bdc673784178bbd5bf0250a0a04e9cbd24ed6` | Original; built-in OpenAI image_gen, October 24, 2026 | Project-generated artwork |
| `assets/decorations/sticker_newyear_clock.png` | `02cdae0a751c3e2e18e1f23c1f7d106e9e875bdb4c3a01db503e1eedcebf177d` | Original; built-in OpenAI image_gen, October 24, 2026 | Project-generated artwork |
| `assets/decorations/sticker_valentine_heart.png` | `261ba91fedd02bcab075b090d1a5c80368a08d6b3ebe12f39f7662c2ab4bf3f7` | Original; built-in OpenAI image_gen, October 24, 2026 | Project-generated artwork |
| `assets/decorations/sticker_thanksgiving_harvest.png` | `ff40c5b38303d4ef11e2f593a2435300ea0b086bb7ca35cb5ffa758b17707833` | Original; built-in OpenAI image_gen, October 24, 2026 | Project-generated artwork |
| `assets/decorations/sticker_retirement_suitcase.png` | `2118ba62b0f303dd88d2deeb180292ad1906b39e7f3637bc14d682dcd6ee9812` | Original; built-in OpenAI image_gen, October 24, 2026 | Project-generated artwork |
| `assets/decorations/sticker_housewarming_keys.png` | `04102caff2c3f1514dfac7a976f5f23649517cb4352a40c16939c62eace3847a` | Original; built-in OpenAI image_gen, October 24, 2026 | Project-generated artwork |
| `assets/decorations/sticker_christening_dove.png` | `99012fc4745ed274f48953afc3c73b5327b97ec165c69395ba780c1ece690cb0` | Original; built-in OpenAI image_gen, October 24, 2026 | Project-generated artwork |
| `assets/decorations/sticker_diwali_diya.png` | `46d9e7fdbef3b742f47f8c95dd7c88ed36e042ebf6a9193342d698e06745f2c9` | Original; built-in OpenAI image_gen, October 24, 2026 | Project-generated artwork |
| `assets/decorations/sticker_eid_lantern.png` | `3a9324997f8f363ba6d84eb8d81b02dc747ddbda1991b40f546075990a4ce856` | Original; built-in OpenAI image_gen, October 24, 2026 | Project-generated artwork |
| `assets/decorations/sticker_hanukkah_lights.png` | `bb03f8a8afc17437287690ff2e67785518f780b5d66860b3c72be47d46dda0f2` | Original; built-in OpenAI image_gen, October 24, 2026 | Project-generated artwork |
| `assets/decorations/sticker_summer_citrus.png` | `7e2510ede51e9ba1e28bab6919178967f49cc733aa3de77ab760c9798c89b692` | Original; built-in OpenAI image_gen, October 24, 2026 | Project-generated artwork |
| `assets/decorations/sticker_birthday_dinosaur.png` | `618a6df3a7689cdf7fab0bd03a6c16148630acd004e102641bbfba804552bcad` | Original; built-in OpenAI image_gen, October 24, 2026 | Project-generated artwork |
| `assets/decorations/sticker_birthday_unicorn.png` | `461218fd2bec3bc4d98223b920ace2bb4dd8e7dc3d742fcd5f9ea85c8ab503e6` | Original; built-in OpenAI image_gen, October 24, 2026 | Project-generated artwork |
| `assets/decorations/sticker_birthday_pirate.png` | `c4353e2b8b00aaff454313c378af763175dabd5ed44708513ef260fb1c7a21cc` | Original; built-in OpenAI image_gen, October 24, 2026 | Project-generated artwork |
| `assets/decorations/sticker_birthday_space.png` | `eb14e645387ccbef29aa67c9f64488b18747b1041eab010b9aa1b089b9edb4e1` | Original; built-in OpenAI image_gen, October 24, 2026 | Project-generated artwork |
