# Asset provenance and licences

Every file the app ships from `assets/`, plus fonts, icons and artwork that
reach the screen by other routes (AC-0211, CR-001 item 8). The table of
bundled files is checked by `test/core/app_info_and_licences_test.dart`:
adding, removing or changing a file without updating its row fails the
build.

## Bundled files

| Path | SHA-256 | Source | Licence |
| --- | --- | --- | --- |
| `assets/fonts/cormorant_garamond/CormorantGaramond-Medium.ttf` | `8eaa2a57728fe1f65647cd0e0bc2733907ac07e8d6921fe2f80b97cdca9fd0db` | CatharsisFonts/Cormorant `fonts/ttf/`, commit `6d210fd` (Version 4.001) | SIL OFL 1.1 |
| `assets/fonts/cormorant_garamond/CormorantGaramond-SemiBold.ttf` | `d0934e611e2e930614ffc3675f824bdf1960c88bc44ebcd73ff162beb31ac8e3` | CatharsisFonts/Cormorant `fonts/ttf/`, commit `6d210fd` (Version 4.001) | SIL OFL 1.1 |
| `assets/fonts/cormorant_garamond/OFL.txt` | `60700d351cac4650c51f3f9db318d2a420f8b45052dba2715eb5fec41f0f6956` | `OFL.txt` from CatharsisFonts/Cormorant, commit `6d210fd` | Licence text |
| `assets/fonts/inter/Inter-Medium.ttf` | `97ad806f526e41546d46365bb3a393145f75b7b1568913db74549ad8b8dba872` | Inter 4.1 release, `Inter-4.1.zip` `extras/ttf/`, rsms/inter (Version 4.001) | SIL OFL 1.1 |
| `assets/fonts/inter/Inter-Regular.ttf` | `40d692fce188e4471e2b3cba937be967878f631ad3ebbbdcd587687c7ebe0c82` | Inter 4.1 release, `Inter-4.1.zip` `extras/ttf/`, rsms/inter (Version 4.001) | SIL OFL 1.1 |
| `assets/fonts/inter/Inter-SemiBold.ttf` | `78a843fade9d4612a5567302fb595b56976eb5fcebf4fea5a5912d638bafcde3` | Inter 4.1 release, `Inter-4.1.zip` `extras/ttf/`, rsms/inter (Version 4.001) | SIL OFL 1.1 |
| `assets/fonts/inter/OFL.txt` | `262481e844521b326f5ecd053e59b98c8b2da78c8ee1bdbb6e8174305e54935a` | `LICENSE.txt` from the same Inter 4.1 release | Licence text |

Fonts are unmodified upstream static instances; no Reserved Font Name
applies to either family. Licence texts are bundled and shown on the app's
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
that use it). No raster artwork ships. Nothing from the 15-screen concept
board is used: no artwork, photographs, sample people, names or dates
(UX-09, CR-001 fix 12).
