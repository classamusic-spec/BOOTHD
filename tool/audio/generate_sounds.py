#!/usr/bin/env python3
"""Synthesises the booth's sixteen guest sounds (EP03).

Original placeholders, made from sine, square and noise sources only, so
every Experience Pack has working sounds until the owner's ElevenLabs
recordings replace them (docs/experience_packs/SOUND_SCRIPT_ELEVENLABS.md).
Nothing is sampled or copied; the melodies are plain arpeggios.

Usage: python3 -I tool/audio/generate_sounds.py assets/sounds
Writes 44.1 kHz 16-bit mono WAV files, peaks at -3 dBFS, with a 3 ms
fade-in and a 10 ms fade-out. Deterministic (fixed noise seeds).
"""

import os
import sys
import wave

import numpy as np

RATE = 44100
PEAK = 10 ** (-3 / 20)


def t(seconds):
    return np.arange(int(RATE * seconds)) / RATE


def note(name):
    names = {'C': -9, 'D': -7, 'E': -5, 'F': -4, 'G': -2, 'A': 0, 'B': 2}
    octave = int(name[-1])
    return 440.0 * 2 ** ((names[name[0]] + 12 * (octave - 4)) / 12)


def decay(seconds, tau):
    return np.exp(-t(seconds) / tau)


def sine(freq, seconds, phase=0.0):
    return np.sin(2 * np.pi * freq * t(seconds) + phase)


def soft_square(freq, seconds, harmonics=7):
    """A square wave from its first odd harmonics: retro but not harsh."""
    out = np.zeros(len(t(seconds)))
    for k in range(1, 2 * harmonics, 2):
        if freq * k > RATE / 2.5:
            break
        out += np.sin(2 * np.pi * freq * k * t(seconds)) / k
    return out


def noise(seconds, seed):
    return np.random.default_rng(seed).uniform(-1, 1, len(t(seconds)))


def lowpass(signal, cutoff):
    """One-pole low-pass."""
    a = np.exp(-2 * np.pi * cutoff / RATE)
    out = np.empty_like(signal)
    acc = 0.0
    for i, x in enumerate(signal):
        acc = (1 - a) * x + a * acc
        out[i] = acc
    return out


def highpass(signal, cutoff):
    return signal - lowpass(signal, cutoff)


def place(total, parts):
    """Mixes (start seconds, signal) pairs into one buffer."""
    out = np.zeros(int(RATE * total))
    for start, part in parts:
        i = int(RATE * start)
        end = min(len(out), i + len(part))
        out[i:end] += part[: end - i]
    return out


def bell(freq, seconds, partials, tau):
    out = np.zeros(len(t(seconds)))
    for ratio, gain, life in partials:
        out += gain * sine(freq * ratio, seconds) * decay(seconds, tau * life)
    return out


def porcelain_tap():
    d = 0.12
    body = 0.6 * sine(3200, d) * decay(d, 0.018) + 0.35 * sine(5150, d) * decay(d, 0.010)
    click = highpass(noise(d, 1), 2500) * decay(d, 0.002) * 0.5
    return body + click


def porcelain_chime():
    return bell(note('G6'), 1.4, [(1, 1, 1), (2.76, 0.35, 0.5), (5.40, 0.15, 0.25)], 0.45)


def wood_click():
    d = 0.09
    knock = 0.7 * sine(880, d) * decay(d, 0.012) + 0.4 * sine(1420, d) * decay(d, 0.008)
    grain = lowpass(noise(d, 2), 3000) * decay(d, 0.004)
    return knock + grain


def film_tick():
    d = 0.22
    click = highpass(noise(d, 3), 3000) * decay(d, 0.003) + 0.4 * sine(2500, d) * decay(d, 0.006)
    whirr = lowpass(noise(d, 4), 1200) * (0.5 + 0.5 * sine(24, d)) * decay(d, 0.06) * 0.25
    return click + whirr


def disco_pulse():
    d = 0.8
    f = note('A3')
    saw = sum(np.sin(2 * np.pi * f * k * t(d)) / k for k in range(1, 12))
    swept = np.zeros_like(saw)
    # A filter that closes over the note, chunk by chunk.
    for i, chunk in enumerate(np.array_split(saw, 16)):
        start = sum(len(c) for c in np.array_split(saw, 16)[:i])
        swept[start:start + len(chunk)] = lowpass(chunk, 2400 * 0.82 ** i + 300)
    return swept * decay(d, 0.22) * (1 + 0.15 * sine(6, d))


def garden_twinkle():
    parts = []
    for i, name in enumerate(['E6', 'G6', 'B6']):
        parts.append((0.11 * i, 0.7 * bell(note(name), 0.9, [(1, 1, 1), (3.9, 0.2, 0.3)], 0.18)))
    return place(1.3, parts)


def gala_bell():
    return bell(note('C6'), 1.9, [(1, 1, 1), (2.0, 0.5, 0.8), (3.01, 0.3, 0.6), (4.2, 0.15, 0.4), (5.4, 0.08, 0.3)], 0.6)


def toy_press():
    d = 0.14
    freq = np.linspace(620, 340, len(t(d)))
    phase = 2 * np.pi * np.cumsum(freq) / RATE
    attack = np.minimum(1, t(d) / 0.008)
    return np.sin(phase) * attack * decay(d, 0.05)


def soft_pop():
    d = 0.08
    freq = np.geomspace(1100, 280, len(t(d)))
    phase = 2 * np.pi * np.cumsum(freq) / RATE
    return np.sin(phase) * decay(d, 0.018) + 0.15 * lowpass(noise(d, 5), 4000) * decay(d, 0.004)


def cheer_confirm():
    parts = []
    for i, name in enumerate(['C6', 'E6', 'G6', 'C7']):
        parts.append((0.06 * i, 0.5 * sine(note(name), 0.6) * decay(0.6, 0.12 + 0.05 * i)))
    rustle = highpass(noise(1.2, 6), 3500) * np.clip(sine(9, 1.2) * 0.5 + 0.5, 0, 1) * decay(1.2, 0.3) * 0.18
    return place(1.2, parts + [(0.15, rustle)])


def marimba(freq, d):
    return (sine(freq, d) + 0.25 * sine(freq * 4, d) * decay(d, 0.02)) * decay(d, 0.16)


def party_chime():
    return place(0.9, [(0, 0.8 * marimba(note('G5'), 0.5)), (0.14, marimba(note('C6'), 0.7))])


def chip_line(notes, step, hold):
    parts = []
    for i, name in enumerate(notes):
        length = hold if i == len(notes) - 1 else step
        tone = soft_square(note(name), length, 5) * np.minimum(1, t(length) / 0.004)
        tone *= decay(length, length * 0.9)
        parts.append((step * i, tone))
    return place(step * (len(notes) - 1) + hold + 0.02, parts)


def arcade_start():
    return chip_line(['C5', 'E5', 'G5', 'C6'], 0.07, 0.28)


def select_beep():
    d = 0.06
    return soft_square(880, d, 4) * decay(d, 0.04)


def countdown_tick():
    d = 0.09
    return soft_square(440, d, 5) * decay(d, 0.06)


def level_complete():
    return chip_line(['C5', 'E5', 'G5', 'C6', 'E6', 'G6'], 0.09, 0.45)


def shutter_soft():
    def click(seed):
        d = 0.05
        return (lowpass(highpass(noise(d, seed), 800), 6000) * decay(d, 0.006)
                + 0.3 * sine(1800, d) * decay(d, 0.004))
    return place(0.16, [(0, click(7)), (0.065, 0.7 * click(8))])


SOUNDS = {
    'porcelain-tap': porcelain_tap,
    'porcelain-chime': porcelain_chime,
    'wood-click': wood_click,
    'film-tick': film_tick,
    'disco-pulse': disco_pulse,
    'garden-twinkle': garden_twinkle,
    'gala-bell': gala_bell,
    'toy-press': toy_press,
    'soft-pop': soft_pop,
    'cheer-confirm': cheer_confirm,
    'party-chime': party_chime,
    'arcade-start': arcade_start,
    'select-beep': select_beep,
    'countdown-tick': countdown_tick,
    'level-complete': level_complete,
    'shutter-soft': shutter_soft,
}


def finish(signal):
    signal = np.asarray(signal, dtype=np.float64)
    fade_in = min(len(signal), int(RATE * 0.003))
    fade_out = min(len(signal), int(RATE * 0.010))
    signal[:fade_in] *= np.linspace(0, 1, fade_in)
    signal[len(signal) - fade_out:] *= np.linspace(1, 0, fade_out)
    peak = np.max(np.abs(signal))
    if peak > 0:
        signal = signal / peak * PEAK
    return np.round(signal * 32767).astype('<i2')


def write(path, samples):
    with wave.open(path, 'wb') as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes(samples.tobytes())


def main():
    if len(sys.argv) != 2:
        sys.exit('usage: generate_sounds.py <output directory>')
    folder = sys.argv[1]
    os.makedirs(folder, exist_ok=True)
    for name, make in SOUNDS.items():
        write(os.path.join(folder, name + '.wav'), finish(make()))
        print(name)


if __name__ == '__main__':
    main()
