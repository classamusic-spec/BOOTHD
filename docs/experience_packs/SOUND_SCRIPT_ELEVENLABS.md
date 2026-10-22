# Guest sound script for ElevenLabs Sound Effects

The booth ships with sixteen short guest sounds. Until the owner supplies
recorded ones, `tool/audio/generate_sounds.py` synthesises original
placeholders (`assets/sounds/*.wav`) so every pack works. This sheet is the
brief for replacing them with ElevenLabs Sound Effects.

## How to generate

For each row below, in ElevenLabs **Sound Effects**:

1. Paste the **Prompt** exactly.
2. Set **Duration** to the value given (seconds). Do not use "auto".
3. Set **Prompt influence** to the value given (higher follows the prompt
   more literally).
4. Generate four takes, pick the cleanest: no voice, no music bed, no
   reverb tail longer than the duration, no click at the start.
5. Download as **MP3 44.1 kHz** (or WAV) and name the file exactly as in
   **File**.

Send the files back as they are; `tool/audio/import_sounds.sh` trims
leading silence, converts to 44.1 kHz 16-bit mono WAV, normalises peaks
to -3 dBFS and fades the last 10 ms, then records each file's SHA-256 in
`docs/ASSET_PROVENANCE.md`.

**Licence check before sending:** sound effects are only commercially
usable from a paid ElevenLabs plan. Tell me which plan generated them; I
record it with the files. Sounds from a free plan cannot ship.

## Ground rules for every sound

- Original only: no recognisable game, console, phone or brand sound, no
  melody from an existing song or jingle, no voices or words.
- Short and soft: guests hear these many times an hour next to music.
  Nothing harsh, shrill or startling; no bass drops; no sirens.
- Dry: little or no reverb, so it sounds the same in a ballroom or a
  hallway.
- One event per file: no repeats inside a file (the app repeats ticks).

## The sixteen sounds

| # | File | Used for | Duration | Influence | Prompt |
| --- | --- | --- | --- | --- | --- |
| 1 | `porcelain-tap.mp3` | Button press and countdown tick, Porcelain Classic | 0.5 | 0.7 | A single soft tap of a fingertip on a fine porcelain teacup, clean bright ceramic click, very short, dry, no ring-out |
| 2 | `porcelain-chime.mp3` | Start, go and success, Porcelain Classic | 1.5 | 0.6 | One gentle crystal glass chime, warm and elegant, a single clear high note that fades smoothly, soft attack, no melody, dry room |
| 3 | `wood-click.mp3` | Press and tick, Vintage Light Wood | 0.5 | 0.7 | A single crisp click of a small wooden toggle switch on an old oak cabinet, warm woody knock, very short, dry |
| 4 | `film-tick.mp3` | Countdown tick, Retro Film | 0.5 | 0.7 | One mechanical tick of a vintage film projector advancing a frame, small metal click with a soft whirr tail, very short |
| 5 | `disco-pulse.mp3` | Start, go and countdown, Disco Nights | 1.0 | 0.5 | A single warm synth pluck with a soft filtered pulse, glossy nightclub feel, one note only, smooth fade, no beat, no melody |
| 6 | `garden-twinkle.mp3` | Start and success, Storybook Garden | 1.5 | 0.5 | A delicate fairy-tale twinkle, three tiny soft glockenspiel sparkles rising gently, magical and calm, light and airy, short fade |
| 7 | `gala-bell.mp3` | Start, go and success, Midnight Gala | 2.0 | 0.6 | One refined small hand bell struck once, rich golden tone, luxurious and calm, slow natural fade, dry |
| 8 | `toy-press.mp3` | Button press, Kid Party Arcade | 0.5 | 0.7 | A cheerful squishy plastic toy button press, soft rubbery boop, friendly and bouncy, very short, not loud |
| 9 | `soft-pop.mp3` | Countdown tick, Kid Party Arcade | 0.5 | 0.7 | A soft round bubble pop, gentle and playful, like a small soap bubble bursting, very short and quiet |
| 10 | `cheer-confirm.mp3` | Success and celebration, Kid Party Arcade | 1.5 | 0.5 | A short happy party confirmation sound, a quick rising sparkle with a soft paper confetti rustle, joyful, no voices, no crowd |
| 11 | `party-chime.mp3` | Start and go, Kid Party Arcade | 1.0 | 0.6 | A bright playful two-note marimba chime going up, cheerful party start, soft mallets, dry, short |
| 12 | `arcade-start.mp3` | Start and go, Retro Game Quest | 1.0 | 0.6 | An original retro 8-bit start sound, a quick rising square-wave arpeggio of four notes, friendly and clean, not loud, no famous game sounds |
| 13 | `select-beep.mp3` | Button press, Retro Game Quest | 0.5 | 0.7 | A single short soft 8-bit menu select blip, mid pitch square wave, clean and quiet, very short |
| 14 | `countdown-tick.mp3` | Countdown tick, Retro Game Quest | 0.5 | 0.7 | One short low 8-bit countdown beep, soft square wave, steady pitch, very short and clean |
| 15 | `level-complete.mp3` | Success and celebration, Retro Game Quest | 2.0 | 0.5 | An original short 8-bit success fanfare, a cheerful rising chiptune flourish of five notes ending on a bright held note, not loud, no famous game melodies |
| 16 | `shutter-soft.mp3` | The moment a photo is taken, every pack | 0.5 | 0.8 | A soft quiet camera shutter click, gentle mechanical leaf shutter, short and clean, no flash whine, no motor |

## Which pack uses which

| Pack | Press | Start | Tick | Go | Shutter | Success | Celebrate |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Porcelain Classic | porcelain-tap | porcelain-chime | porcelain-tap | porcelain-chime | shutter-soft | porcelain-chime | porcelain-chime |
| Vintage Light Wood | wood-click | porcelain-chime | wood-click | porcelain-chime | shutter-soft | porcelain-chime | porcelain-chime |
| Retro Film | film-tick | porcelain-chime | film-tick | porcelain-chime | shutter-soft | porcelain-chime | porcelain-chime |
| Disco Nights | porcelain-tap | disco-pulse | disco-pulse | disco-pulse | shutter-soft | disco-pulse | disco-pulse |
| Storybook Garden | porcelain-tap | garden-twinkle | porcelain-tap | garden-twinkle | shutter-soft | garden-twinkle | garden-twinkle |
| Midnight Gala | porcelain-tap | gala-bell | porcelain-tap | gala-bell | shutter-soft | gala-bell | gala-bell |
| Kid Party Arcade | toy-press | party-chime | soft-pop | party-chime | shutter-soft | cheer-confirm | cheer-confirm |
| Retro Game Quest | select-beep | arcade-start | countdown-tick | arcade-start | shutter-soft | level-complete | level-complete |

The pack manifests in `lib/domain/experience/bundled_packs.dart` are the
source of truth; this table is checked against them by
`test/experience/sound_assets_test.dart`.

## How the booth plays them

- Sound is off by default for every event; the operator turns it on in the
  event's Experience settings and sets the volume.
- Sounds are preloaded when Booth Mode starts and played without waiting,
  so a slow or failed sound never delays the countdown or the photo.
- The countdown never depends on sound: silent and reduced-motion forms
  show exactly the same timing.
