# Originality review: Kid Party Arcade and Retro Game Quest

AC-EP17 asks that no copyrighted game UI or unlicensed asset is
incorporated. This checklist records how the two packs most at risk were
made and reviewed (EP04, EP05). It is a self-review by the implementer;
the owner's visual review (CR-001, CR-002) is still required before
release.

## Sources

| Asset | Made by | Licence |
| --- | --- | --- |
| Party art: balloons, confetti, stars, bunting | `lib/core/design_system/party_art.dart` (code, fixed seeds) | Project-owned |
| Pixel art: hearts, coins, sparkles, pixel border, marquee lights | `lib/core/design_system/party_art.dart`; pixel grids typed in the source | Project-owned |
| Template PNGs | `tool/art/decorations.dart` renders the art above | Project-owned |
| Guest buttons (toy arcade, retro game) | `lib/shared/guest/guest_button_faces.dart` (paths and gradients) | Project-owned |
| Countdowns (Party Pop, Arcade Start, Handheld Boot) | `lib/shared/guest/guest_countdown.dart` | Project-owned |
| Fonts: Fredoka, Pixelify Sans | google/fonts, SIL OFL 1.1 (`docs/ASSET_PROVENANCE.md`) | SIL OFL 1.1 |
| Sounds: toy-press, soft-pop, cheer-confirm, party-chime, arcade-start, select-beep, countdown-tick, level-complete | `tool/audio/generate_sounds.py` (sine, square and noise; plain arpeggios) | Project-owned |

No image, sound, font or code was downloaded for these packs other than
the two OFL fonts.

## Checklist

| Rule (prompt, section on originality) | Result |
| --- | --- |
| No protected logos or wordmarks | None drawn or named |
| No existing video game characters | None: no figures, mascots or creatures at all |
| No distinctive commercial handheld silhouettes | Not drawn. The Handheld Boot countdown is a plain rounded screen with a loading bar; no buttons, pad or speaker grille layout of any device |
| No recognisable copied game screens or HUDs | The scoreboard template uses generic words ("SCORE 00100", "LEVEL 1") and three hearts; no layout, palette or typeface of a specific game |
| No proprietary fonts | Pixelify Sans is an original OFL pixel face, not a game font |
| No copied jingles or sound effects | Sounds are synthesised arpeggios and blips; the ElevenLabs brief forbids famous game sounds |
| Words | Generic phrases only ("Player 1", "Bonus Round", "Level Up!", "Game On!", "High Score", "Insert smile") |

## Open items

- Owner visual review of both packs on a tablet.
- When the owner's ElevenLabs sounds arrive, listen to each for
  resemblance to a known game sound before importing (the import script
  records the plan they came from).
