#!/usr/bin/env python3
"""Synthesizes Flaszki's sound effects (PRD §6) into assets/audio/*.ogg.

Own work, CC BY 4.0 (ADR 0003). Deterministic: fixed seeds; re-run after
changing a recipe and commit the OGGs.

Needs numpy and ffmpeg (Vorbis encoder). Usage: python3 tool/gen_sounds.py
"""

import os
import subprocess
import sys
import tempfile
import wave

import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "audio")


def t_axis(dur):
    return np.arange(int(SR * dur)) / SR


def band(x, lo, hi):
    """Zero-phase FFT band-pass."""
    spec = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / SR)
    spec[(f < lo) | (f > hi)] = 0
    return np.fft.irfft(spec, len(x))


def fade(x, ms=4):
    """Short fade-in/out so files start and end at zero."""
    n = min(len(x) // 2, int(SR * ms / 1000))
    ramp = np.linspace(0, 1, n)
    x = x.copy()
    x[:n] *= ramp
    x[-n:] *= ramp[::-1]
    return x


def norm(x, peak):
    return fade(x / np.max(np.abs(x)) * peak)


def bell(f0, dur, ratios, amps, decay, t0=0.0, total=None):
    t = t_axis(total or dur)
    x = np.zeros_like(t)
    tt = t - t0
    on = tt >= 0
    for r, a in zip(ratios, amps):
        x[on] += a * np.sin(2 * np.pi * f0 * r * tt[on]) * np.exp(-decay * r**0.5 * tt[on])
    return x


def clink(v):
    f0 = [2650, 2950, 3250][v]
    x = bell(f0, 0.35, [1, 2.76, 5.40], [1, 0.45, 0.2], 16)
    click = np.random.default_rng(10 + v).standard_normal(len(x)) * np.exp(-t_axis(0.35) * 900)
    return norm(x + 0.3 * band(click, 3000, 12000), 0.45)


def bubble(f0, dur, rise):
    t = t_axis(dur)
    phase = 2 * np.pi * np.cumsum(f0 * (1 + rise * t / dur)) / SR
    return np.sin(phase) * np.exp(-t * 22) * (1 - np.exp(-t * 600))


def glug(v):
    dur = 0.24
    f0 = [190, 225, 260][v]
    rng = np.random.default_rng(20 + v)
    x = bubble(f0, dur, 1.6)
    late = bubble(f0 * 1.35, dur - 0.06, 1.2)
    x[int(0.06 * SR) : int(0.06 * SR) + len(late)] += 0.6 * late
    splash = band(rng.standard_normal(len(x)), 900, 5000) * np.exp(-t_axis(dur) * 30)
    return norm(x + 0.12 * splash / np.max(np.abs(splash)), 0.6)


def invalid():
    t = t_axis(0.13)
    x = np.sin(2 * np.pi * 120 * t) * np.exp(-t * 45)
    noise = band(np.random.default_rng(30).standard_normal(len(t)), 80, 900) * np.exp(-t * 80)
    return norm(x + 0.4 * noise / np.max(np.abs(noise)), 0.5)


def cork_pop(v):
    dur = 0.16
    t = t_axis(dur)
    f0 = [560, 640, 720][v]
    f = f0 * (1 + 0.6 * np.exp(-t * 60))
    tone = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 55)
    burst = band(np.random.default_rng(40 + v).standard_normal(len(t)), 1500, 9000) * np.exp(-t * 400)
    return norm(tone + 0.5 * burst / np.max(np.abs(burst)), 0.6)


def orb_chime():
    x = bell(1046.5, 0.8, [1, 2.0, 3.01, 4.17], [1, 0.35, 0.18, 0.08], 4.5)
    return norm(x, 0.4)


def cork_squeak():
    dur = 0.2
    t = t_axis(dur)
    f = 1350 + 250 * t / dur + 120 * np.sin(2 * np.pi * 38 * t)
    env = np.minimum(1, t / 0.03) * np.minimum(1, (dur - t) / 0.06)
    x = np.sin(2 * np.pi * np.cumsum(f) / SR) * env
    x += 0.3 * np.sin(2 * np.pi * 2 * np.cumsum(f) / SR) * env
    return norm(x, 0.3)


def solved_arpeggio():
    total = 1.5
    notes = [523.25, 659.25, 783.99, 1046.5]  # C5 E5 G5 C6
    x = sum(
        bell(f, total, [1, 2.0, 3.01], [1, 0.3, 0.12], 3.2, t0=0.14 * i, total=total)
        for i, f in enumerate(notes)
    )
    return norm(x, 0.45)


def undo_swish():
    dur = 0.32
    t = t_axis(dur)
    rng = np.random.default_rng(60)
    noise = rng.standard_normal(len(t))
    # Sweep the band down over time: mix of high→low bands with moving weights.
    hi = band(noise, 2500, 7000)
    lo = band(noise, 500, 2500)
    w = t / dur
    x = (hi * (1 - w) + lo * w)
    env = (t / dur) ** 2.2  # reverse swell
    env[-int(0.03 * SR) :] *= np.linspace(1, 0, int(0.03 * SR))
    return norm(x * env, 0.35)


SOUNDS = {
    "select_1": lambda: clink(0),
    "select_2": lambda: clink(1),
    "select_3": lambda: clink(2),
    "pour_1": lambda: glug(0),
    "pour_2": lambda: glug(1),
    "pour_3": lambda: glug(2),
    "invalid_1": invalid,
    "seal_1": lambda: cork_pop(0),
    "seal_2": lambda: cork_pop(1),
    "seal_3": lambda: cork_pop(2),
    "queueAdvance_1": orb_chime,
    "waitingCork_1": cork_squeak,
    "solved_1": solved_arpeggio,
    "undo_1": undo_swish,
}


def write_ogg(name, x):
    pcm = (np.clip(x, -1, 1) * 32767).astype("<i2")
    stereo = np.repeat(pcm[:, None], 2, axis=1)  # ffmpeg's vorbis encoder wants stereo
    with tempfile.TemporaryDirectory() as tmp:
        wav = os.path.join(tmp, "x.wav")
        with wave.open(wav, "wb") as w:
            w.setnchannels(2)
            w.setsampwidth(2)
            w.setframerate(SR)
            w.writeframes(stereo.tobytes())
        out = os.path.join(OUT, name + ".ogg")
        subprocess.run(
            ["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-map_metadata", "-1",
             "-fflags", "+bitexact", "-flags:a", "+bitexact",
             "-c:a", "vorbis", "-strict", "-2", "-q:a", "6", out],
            check=True,
        )


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, make in SOUNDS.items():
        write_ogg(name, make())
        print(name)
    return 0


if __name__ == "__main__":
    sys.exit(main())
