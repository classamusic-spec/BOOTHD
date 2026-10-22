# Asset provenance and licences

Every file the app ships from `assets/`, plus fonts, icons and artwork that
reach the screen by other routes (AC-0211, CR-001 item 8). The table of
bundled files is checked by `test/core/app_info_and_licences_test.dart`:
adding, removing or changing a file without updating its row fails the
build.

## Bundled files

| Path | SHA-256 | Source | Licence |
| --- | --- | --- | --- |
| `assets/decorations/blossom_corner.png` | `5ad9d9ea9358b7d5a5a860f6bf22216fd697e137136d1812e373d9f256c5e968` | Original; drawn by `tool/art/decorations.dart` (M05) | Project-owned |
| `assets/decorations/blossom_corner_champagne.png` | `65718cedc19e0efc3a2864ee90465dcd077de9b5cb8c2a4113a61edb7fb4476c` | Original; drawn by `tool/art/decorations.dart` (M05) | Project-owned |
| `assets/decorations/blossom_garland.png` | `b939b075d3e91ee70df9432d201cfa1c0eab984dafad7be0ead3f0a988126248` | Original; drawn by `tool/art/decorations.dart` (M05) | Project-owned |
| `assets/decorations/blossom_sprig.png` | `cdb9a778f97e8d176e790c66628f692c6b69b33d1d8c8249c7e8c4c3a482dd03` | Original; drawn by `tool/art/decorations.dart` (M05) | Project-owned |
| `assets/decorations/film_edges.png` | `55bbd52b833a84af60d4ab29347d1054bfdb38f8691ece12c7e74c711beec890` | Original; drawn by `tool/art/decorations.dart` (M05) | Project-owned |
| `assets/decorations/gold_confetti.png` | `128c37f9fff17b7fe70ed46b7022fe8a4eb57c8eb1d758422d1737bcc1ad44a7` | Original; drawn by `tool/art/decorations.dart` (M05) | Project-owned |
| `assets/decorations/gold_frame.png` | `288d46b89ea97ce273a582fce419a2520aff6d5cb7bcf2c5b875cf929a13394e` | Original; drawn by `tool/art/decorations.dart` (M05) | Project-owned |
| `assets/decorations/gold_frame_strip.png` | `213d6a63c6267ab4e2cb0c981c31d305cbc9696c2649e5246cbaa5cc61b2d977` | Original; drawn by `tool/art/decorations.dart` (M05) | Project-owned |
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

The template decorations in `assets/decorations/` (M05) are the only raster
artwork that ships. They are original too: painted in code by
`tool/art/decorations.dart` with the floral painter in
`lib/core/design_system/floral_art.dart` (seeded, so the same every run)
and written out by `flutter test tool/art/generate_decorations_test.dart`.
`test/assets/decorations_current_test.dart` fails if a committed file no
longer matches its generator. The slot placeholder that stands in for a
guest photo in the editor and previews is drawn at run time
(`lib/core/templates/slot_placeholder.dart`) and never stored.
