#!/usr/bin/env bash
# Imports the owner's ElevenLabs sound effects (EP03) over the generated
# placeholders: docs/experience_packs/SOUND_SCRIPT_ELEVENLABS.md.
#
# Usage: tool/audio/import_sounds.sh <folder with the downloaded files>
#
# Each <id>.mp3 or <id>.wav whose id the booth uses is trimmed of leading
# silence, converted to 44.1 kHz 16-bit mono WAV, peak-normalised to
# -3 dBFS and given a 10 ms fade-out, then written to assets/sounds/<id>.wav.
# Unknown names are refused. Prints each file's SHA-256 for
# docs/ASSET_PROVENANCE.md.
set -euo pipefail

if [[ $# -ne 1 || ! -d "$1" ]]; then
  echo "usage: $0 <folder with the downloaded files>" >&2
  exit 2
fi
command -v ffmpeg >/dev/null || { echo "ffmpeg is required" >&2; exit 2; }

root="$(cd "$(dirname "$0")/../.." && pwd)"
out="$root/assets/sounds"
ids=(porcelain-tap porcelain-chime wood-click film-tick disco-pulse
  garden-twinkle gala-bell toy-press soft-pop cheer-confirm party-chime
  arcade-start select-beep countdown-tick level-complete shutter-soft)

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
status=0
imported=0

for source in "$1"/*; do
  [[ -f "$source" ]] || continue
  name="$(basename "$source")"
  id="${name%.*}"
  ext="${name##*.}"
  if [[ "$ext" != "mp3" && "$ext" != "wav" ]] ||
    [[ ! " ${ids[*]} " == *" $id "* ]]; then
    echo "refused: $name (not one of the sixteen sound files)" >&2
    status=1
    continue
  fi
  trimmed="$work/$id.trim.wav"
  ffmpeg -nostdin -loglevel error -y -i "$source" \
    -af "silenceremove=start_periods=1:start_threshold=-50dB" \
    -ac 1 -ar 44100 -sample_fmt s16 "$trimmed"
  peak="$(ffmpeg -nostdin -i "$trimmed" -af volumedetect -f null - 2>&1 |
    sed -n 's/.*max_volume: \(-\{0,1\}[0-9.]*\) dB.*/\1/p')"
  gain="$(awk -v p="$peak" 'BEGIN { printf "%.2f", -3 - p }')"
  duration="$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$trimmed")"
  fade_start="$(awk -v d="$duration" 'BEGIN { s = d - 0.01; if (s < 0) s = 0; printf "%.3f", s }')"
  ffmpeg -nostdin -loglevel error -y -i "$trimmed" \
    -af "volume=${gain}dB,afade=t=out:st=${fade_start}:d=0.01" \
    -ac 1 -ar 44100 -sample_fmt s16 "$out/$id.wav"
  echo "$id.wav $(sha256sum "$out/$id.wav" | cut -d' ' -f1) (${duration}s, gain ${gain} dB)"
  imported=$((imported + 1))
done

echo "imported $imported file(s)"
exit "$status"
