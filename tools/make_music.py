#!/usr/bin/env python3
"""Фоновая мелодия «Бангкокский бриз»: спокойная и весёлая, бесшовная петля.

Пентатоника до мажор, маримба поверх мягких аккордов, бас, шейкер и «деревяшка».
16 тактов, 100 ударов в минуту, около 38 секунд. Хвост эха заворачивается в начало,
поэтому петля звучит без шва.

Запуск из папки проекта: python3 tools/make_music.py
Результат: assets/music/bangkok_breeze.ogg (нужен ffmpeg).
"""

import subprocess
import wave
from pathlib import Path

import numpy as np

RATE = 32000
BPM = 100
BEAT = 60.0 / BPM
BARS = 16
LENGTH = int(BARS * 4 * BEAT * RATE)
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "music" / "bangkok_breeze.ogg"

rng = np.random.default_rng(7)


def hz(midi):
    return 440.0 * 2 ** ((midi - 69) / 12.0)


def add(buffer, start, sound):
    """Кладём звук в петлю; всё, что вылезло за конец, — в начало (бесшовность)."""
    i = int(start * RATE) % LENGTH
    end = i + len(sound)
    if end <= LENGTH:
        buffer[i:end] += sound
    else:
        first = LENGTH - i
        buffer[i:] += sound[:first]
        rest = sound[first:]
        while len(rest):
            chunk = rest[:LENGTH]
            buffer[:len(chunk)] += chunk
            rest = rest[LENGTH:]


def marimba(midi, seconds, volume=0.32):
    """Деревянная пластинка: основной тон, обертон ×4 гаснет быстро, короткий «стук» в начале."""
    n = int((seconds + 0.9) * RATE)
    t = np.arange(n) / RATE
    f = hz(midi)
    attack = np.minimum(1.0, t / 0.004)
    body = np.sin(2 * np.pi * f * t) * np.exp(-t * 4.2)
    over = 0.35 * np.sin(2 * np.pi * f * 4.0 * t) * np.exp(-t * 14.0)
    click = 0.12 * np.sin(2 * np.pi * f * 9.9 * t) * np.exp(-t * 60.0)
    return volume * attack * (body + over + click)


def pad(midis, seconds, volume=0.07):
    """Мягкие аккорды: чуть расстроенные синусы с медленным нарастанием и затуханием."""
    n = int((seconds + 0.6) * RATE)
    t = np.arange(n) / RATE
    env = np.minimum(1.0, t / 0.45) * np.minimum(1.0, np.maximum(0.0, (seconds + 0.6 - t) / 0.6))
    out = np.zeros(n)
    for m in midis:
        f = hz(m)
        out += np.sin(2 * np.pi * f * t) + 0.5 * np.sin(2 * np.pi * f * 1.003 * t + 1.0)
        out += 0.18 * np.sin(2 * np.pi * f * 2 * t)
    return volume * env * out / len(midis)


def bass(midi, seconds, volume=0.22):
    n = int((seconds + 0.2) * RATE)
    t = np.arange(n) / RATE
    env = np.minimum(1.0, t / 0.01) * np.exp(-t * 2.2)
    f = hz(midi)
    return volume * env * (np.sin(2 * np.pi * f * t) + 0.25 * np.sin(2 * np.pi * f * 2 * t))


def shaker(volume=0.035):
    n = int(0.06 * RATE)
    t = np.arange(n) / RATE
    noise = rng.standard_normal(n)
    noise = np.diff(noise, prepend=0.0)  # выше частоты — «шуршит», а не шипит
    return volume * noise * np.exp(-t * 70.0)


def woodblock(volume=0.06):
    n = int(0.08 * RATE)
    t = np.arange(n) / RATE
    return volume * np.sin(2 * np.pi * 1250 * t) * np.exp(-t * 55.0)


C3, D3, E3, F3, G3, A3, B3 = 48, 50, 52, 53, 55, 57, 59
CHORDS = {
    "C": ([C3 + 12, E3 + 12, G3 + 12], C3 - 12),
    "Am": ([A3, C3 + 12, E3 + 12], A3 - 24),
    "F": ([F3 + 12, A3 + 12, C3 + 24], F3 - 12),
    "G": ([G3, B3, D3 + 12], G3 - 12),
    "Em": ([E3 + 12, G3 + 12, B3 + 12], E3 - 12),
}
PROGRESSION = ["C", "Am", "F", "G", "C", "Em", "F", "G", "C", "Am", "F", "G", "C", "Am", "F", "G"]

C5, D5, E5, G5, A5, C6, A4, G4 = 72, 74, 76, 79, 81, 84, 69, 67
q, e, h, dh = 1.0, 0.5, 2.0, 3.0
# Мелодия по тактам: (нота, длительность в долях). None — пауза.
MELODY = [
    [(E5, q), (G5, e), (A5, e), (G5, q), (E5, q)],
    [(C5, q), (E5, e), (D5, e), (C5, h)],
    [(A4, e), (C5, e), (D5, q), (E5, q), (D5, e), (C5, e)],
    [(D5, dh), (None, q)],
    [(G5, e), (A5, e), (G5, e), (E5, e), (D5, q), (E5, q)],
    [(G5, q), (E5, q), (D5, h)],
    [(C5, e), (D5, e), (E5, q), (G5, q), (A5, q)],
    [(G5, h), (E5, q), (C5, q)],
    [(C6, q), (A5, e), (G5, e), (E5, q), (G5, q)],
    [(A5, h), (G5, e), (E5, e), (D5, q)],
    [(C5, q), (D5, q), (E5, q), (G5, q)],
    [(A5, e), (G5, e), (E5, e), (D5, e), (D5, h)],
    [(E5, e), (G5, e), (A5, q), (G5, e), (E5, e), (C5, q)],
    [(D5, q), (E5, q), (C5, h)],
    [(A4, q), (C5, q), (D5, e), (E5, e), (G5, q)],
    [(D5, h), (C5, h)],
]


def render():
    dry = np.zeros(LENGTH)
    lead = np.zeros(LENGTH)
    for bar, name in enumerate(PROGRESSION):
        start = bar * 4 * BEAT
        notes, root = CHORDS[name]
        add(dry, start, pad(notes, 4 * BEAT))
        add(dry, start, bass(root, 2 * BEAT))
        add(dry, start + 2 * BEAT, bass(root + 7 if name != "G" else root + 5, 2 * BEAT, 0.16))
        for beat in range(4):
            add(dry, start + (beat + 0.5) * BEAT, shaker())
            if beat in (1, 3):
                add(dry, start + beat * BEAT, woodblock())
        at = start
        for note, length in MELODY[bar]:
            if note is not None:
                # Чуть «живее»: громкость немного гуляет от ноты к ноте.
                add(lead, at, marimba(note, length * BEAT, 0.28 + 0.06 * rng.random()))
            at += length * BEAT
    # Эхо на маримбе: два отражения, тоже завёрнутые в петлю.
    echo = np.zeros(LENGTH)
    for delay, gain in ((0.375, 0.28), (0.75, 0.12)):
        echo += gain * np.roll(lead, int(delay * RATE))
    mix = dry + lead + echo
    # Мягкий потолок и запас по громкости: это фон, а не главный звук.
    mix = np.tanh(mix * 1.2)
    mix *= 0.7 / np.max(np.abs(mix))
    return mix


def main():
    mix = render()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    wav = OUT.with_suffix(".wav")
    with wave.open(str(wav), "wb") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(RATE)
        handle.writeframes((mix * 32767).astype("<i2").tobytes())
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav), "-c:a", "vorbis", "-strict", "-2",
                    "-q:a", "4", "-ac", "2", str(OUT)], check=True)
    wav.unlink()
    print("ок:", OUT, "%.1f с" % (LENGTH / RATE))


if __name__ == "__main__":
    main()
