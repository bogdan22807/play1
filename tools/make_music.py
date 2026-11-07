#!/usr/bin/env python3
"""Фоновая мелодия «Тихий вечер»: нежная, медленная, не надоедает за часы игры.

- 72 удара в минуту, фа мажор, тёплые септаккорды (Fmaj7, Am7, Dm7, B♭maj7…).
- Электропиано (мягкий тон с лёгким «колокольчиком» в начале ноты), пэд, тихий бас.
  Без ударных: ничего не стучит по ушам.
- 40 тактов ≈ 2 минуты 13 секунд, части разные: вступление, тема, вариация, другая
  тема, «воздух» без мелодии, возврат. Мелодия часто молчит — фон дышит.
- Стерео и мягкое эхо зала. Эхо считается по кругу, поэтому петля бесшовная.

Запуск из папки проекта: python3 tools/make_music.py
Результат: assets/music/quiet_evening.ogg (нужен ffmpeg).
"""

import subprocess
import wave
from pathlib import Path

import numpy as np

RATE = 32000
BPM = 72
BEAT = 60.0 / BPM
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "music" / "quiet_evening.ogg"

rng = np.random.default_rng(11)

# Ноты: MIDI-номера.
F2, C3, D3, E3, F3, G3, A3, Bb3 = 41, 48, 50, 52, 53, 55, 57, 58
A4, Bb4, C5, D5, E5, F5, G5, A5, C6 = 69, 70, 72, 74, 76, 77, 79, 81, 84

# Аккорды: ноты пэда/пиано и бас.
CHORDS = {
    "Fmaj7": ([53, 57, 60, 64], 41),
    "Am7": ([57, 60, 64, 67], 45),
    "Dm7": ([50, 53, 57, 60], 38),
    "Cmaj7": ([52, 55, 59, 60], 36),
    "Bbmaj7": ([50, 53, 57, 58], 46),
    "Gm7": ([50, 53, 55, 58], 43),
    "C7sus": ([53, 55, 58, 60], 36),
    "C/E": ([52, 55, 60, 64], 40),
    "Csus": ([53, 55, 60, 65], 36),
}

q, e, h, dh, w = 1.0, 0.5, 2.0, 3.0, 4.0
A_CHORDS = ["Fmaj7", "Am7", "Dm7", "Cmaj7", "Bbmaj7", "Am7", "Gm7", "C7sus"]
A_MELODY = [
    [(C5, q), (F5, q), (E5, h)],
    [(C5, q), (E5, 1.5), (D5, e), (C5, q)],
    [(D5, q), (F5, q), (A5, h)],
    [(G5, 1.5), (E5, e), (None, h)],
    [(D5, q), (F5, q), (A5, 1.5), (G5, e)],
    [(E5, h), (C5, q), (None, q)],
    [(D5, q), (F5, q), (G5, 1.5), (F5, e)],
    [(E5, h), (None, h)],
]
# Вариация: та же мысль, но с ответами и другим концом — ухо узнаёт, но не устаёт.
A2_MELODY = [
    [(None, q), (C5, q), (F5, q), (G5, q)],
    [(E5, h), (D5, e), (C5, e), (A4, q)],
    [(D5, q), (F5, q), (A5, q), (C6, q)],
    [(Bb4 + 12, 1.5), (A5, e), (G5, h)],
    [(F5, q), (D5, q), (F5, e), (G5, e), (A5, q)],
    [(G5, h), (E5, h)],
    [(D5, 1.5), (Bb4, e), (D5, q), (F5, q)],
    [(E5, h), (F5, h)],
]
B_CHORDS = ["Dm7", "Bbmaj7", "Fmaj7", "C/E", "Dm7", "Gm7", "Bbmaj7", "Csus"]
B_MELODY = [
    [(A4, q), (D5, q), (F5, h)],
    [(F5, q), (D5, q), (A4, h)],
    [(C5, q), (E5, q), (G5, q), (F5, q)],
    [(E5, dh), (None, q)],
    [(F5, q), (A5, q), (G5, q), (F5, q)],
    [(D5, h), (Bb4, q), (D5, q)],
    [(C5, q), (D5, q), (F5, h)],
    [(G5, h), (None, h)],
]
INTRO = ["Fmaj7", "Bbmaj7", "Fmaj7", "Bbmaj7"]
BREAK = ["Dm7", "Bbmaj7", "Fmaj7", "C7sus"]
# (аккорды, мелодия, как играть сопровождение)
SECTIONS = [
    (INTRO, None, "pad"),
    (A_CHORDS, A_MELODY, "roll"),
    (A_CHORDS, A2_MELODY, "arp"),
    (B_CHORDS, B_MELODY, "arp"),
    (BREAK, None, "chimes"),
    (A_CHORDS, A_MELODY, "roll"),
]
BARS = sum(len(s[0]) for s in SECTIONS)
LENGTH = int(BARS * 4 * BEAT * RATE)


def hz(midi):
    return 440.0 * 2 ** ((midi - 69) / 12.0)


def add(buffer, start, sound, pan=0.0):
    """Кладём стерео-звук в петлю; хвост, вылезший за конец, — в начало (бесшовность)."""
    left = sound * np.sqrt(0.5 * (1.0 - pan))
    right = sound * np.sqrt(0.5 * (1.0 + pan))
    i = int(start * RATE) % LENGTH
    for channel, part in ((0, left), (1, right)):
        end = i + len(part)
        if end <= LENGTH:
            buffer[channel, i:end] += part
        else:
            first = LENGTH - i
            buffer[channel, i:] += part[:first]
            buffer[channel, : end - LENGTH] += part[first:]


def epiano(midi, seconds, volume):
    """Электропиано: мягкий тон, лёгкий «колокольчик» в атаке (FM), долгое затухание."""
    length = seconds + 1.6
    t = np.arange(int(length * RATE)) / RATE
    f = hz(midi)
    index = 1.4 * np.exp(-t * 7.0)                     # «колокольчик» быстро уходит
    tone = np.sin(2 * np.pi * f * t + index * np.sin(2 * np.pi * f * t))
    tone += 0.22 * np.sin(2 * np.pi * 2 * f * t) * np.exp(-t * 2.5)
    env = np.minimum(1.0, t / 0.006) * np.exp(-t * 1.1)
    release = np.clip((length - t) / 0.4, 0, 1)        # после отпускания — мягко гаснет
    env *= np.where(t > seconds, np.exp(-(t - seconds) * 4.0), 1.0) * release
    return tone * env * volume


def pad(midis, seconds, volume=0.05):
    """Пэд: слегка расстроенные тёплые голоса, медленное нарастание и спад."""
    length = seconds + 1.5
    t = np.arange(int(length * RATE)) / RATE
    out = np.zeros_like(t)
    for midi in midis:
        for detune in (-0.12, 0.0, 0.11):
            f = hz(midi + detune)
            out += np.sin(2 * np.pi * f * t) + 0.18 * np.sin(2 * np.pi * 2 * f * t) + 0.06 * np.sin(2 * np.pi * 3 * f * t)
    env = np.minimum(1.0, t / 1.2) * np.clip((length - t) / 1.5, 0, 1)
    # Медленное «дыхание» громкости.
    env *= 0.85 + 0.15 * np.sin(2 * np.pi * 0.15 * t)
    return out * env * volume / len(midis)


def bass(midi, seconds, volume=0.16):
    length = seconds + 0.6
    t = np.arange(int(length * RATE)) / RATE
    f = hz(midi)
    tone = np.sin(2 * np.pi * f * t) + 0.25 * np.sin(2 * np.pi * 2 * f * t) * np.exp(-t * 3)
    env = np.minimum(1.0, t / 0.03) * np.exp(-t * 0.6) * np.clip((length - t) / 0.6, 0, 1)
    return tone * env * volume


def render():
    dry = np.zeros((2, LENGTH))
    bar = 0
    for chords, melody, style in SECTIONS:
        for k, name in enumerate(chords):
            start = bar * 4 * BEAT
            notes, root = CHORDS[name]
            add(dry, start, pad(notes, 4 * BEAT), 0.0)
            if style != "pad" or k % 2 == 0:
                add(dry, start, bass(root, 4 * BEAT), 0.0)
            if style == "roll":
                # Аккорд «перебором» снизу вверх на первую долю, тихо.
                for j, note in enumerate(notes):
                    add(dry, start + j * 0.045, epiano(note, 3.5 * BEAT, 0.05), -0.35 + 0.2 * j)
            elif style == "arp":
                # Ломаный аккорд восьмыми, совсем тихо.
                pattern = [notes[0], notes[2], notes[1], notes[3], notes[2], notes[1], notes[3], notes[2]]
                for j, note in enumerate(pattern):
                    add(dry, start + j * 0.5 * BEAT, epiano(note, 0.5 * BEAT, 0.032), -0.4 if j % 2 else 0.25)
            elif style == "chimes":
                for _ in range(2):
                    note = notes[rng.integers(0, len(notes))] + 24
                    add(dry, start + rng.integers(0, 8) * 0.5 * BEAT, epiano(note, 0.5 * BEAT, 0.035), rng.uniform(-0.6, 0.6))
            if melody is not None:
                at = start
                for note, length in melody[k]:
                    if note is not None:
                        # Чуть «живее»: громкость и время слегка гуляют, как у человека.
                        add(dry, at + rng.uniform(0, 0.015), epiano(note, length * BEAT, 0.13 + 0.03 * rng.random()), 0.1)
                    at += length * BEAT
            bar += 1
    return dry


def reverb(dry, seconds=2.4, wet=0.32):
    """Мягкое эхо зала: свёртка с затухающим шумом. Круговая свёртка — петля без шва."""
    out = np.zeros_like(dry)
    n = int(seconds * RATE)
    t = np.arange(n) / RATE
    for channel in range(2):
        ir = rng.normal(0, 1, n) * np.exp(-t * 3.0 / seconds * 2.3)
        # Убираем звон верхов: сглаживаем импульс.
        ir = np.convolve(ir, np.ones(6) / 6, mode="same")
        ir[: int(0.02 * RATE)] *= np.linspace(0, 1, int(0.02 * RATE))
        ir /= np.sqrt(np.sum(ir ** 2))
        padded = np.zeros(LENGTH)
        padded[:n] = ir
        out[channel] = np.real(np.fft.ifft(np.fft.fft(dry[channel]) * np.fft.fft(padded)))
    return dry + wet * out


def main():
    mix = reverb(render())
    mix = np.tanh(mix * 1.5)
    mix *= 0.6 / np.max(np.abs(mix))
    # Микрозатухание 10 мс на стыке: ogg добавляет в конце несколько отсчётов — так шов не щёлкнет.
    fade = int(0.01 * RATE)
    mix[:, :fade] *= np.linspace(0, 1, fade)
    mix[:, -fade:] *= np.linspace(1, 0, fade)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    wav = OUT.with_suffix(".wav")
    with wave.open(str(wav), "wb") as handle:
        handle.setnchannels(2)
        handle.setsampwidth(2)
        handle.setframerate(RATE)
        handle.writeframes((mix.T * 32767).astype("<i2").tobytes())
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav), "-c:a", "vorbis", "-strict", "-2",
                    "-q:a", "4", str(OUT)], check=True)
    wav.unlink()
    print("ок:", OUT, "%.1f с, %d тактов" % (LENGTH / RATE, BARS))


if __name__ == "__main__":
    main()
