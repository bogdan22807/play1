#!/usr/bin/env python3
"""Звуки денег для «Такси Кликер»: монетка на тап (3 варианта) и касса «ка-чинг».

Синтез: у металла обертоны негармоничные (1 : 2,76 : 5,40 : 8,93 — как у пластины/колокольчика)
и быстро гаснут, поэтому звук «дзынькает», а не «пищит». Касса — щелчок механизма (шум),
звонок и россыпь монеток.

Запуск: python3 tools/make_sfx.py  → assets/sfx/*.wav
"""

import wave
from pathlib import Path

import numpy as np

RATE = 44100
OUT = Path(__file__).resolve().parents[1] / "assets" / "sfx"
METAL = [(1.0, 1.0, 1.0), (2.76, 0.55, 1.8), (5.40, 0.30, 3.0), (8.93, 0.16, 4.5)]


def clink(freq, seconds, volume=1.0, decay=9.0):
    """Один удар по металлу: основной тон и негармоничные обертоны, каждый гаснет быстрее."""
    t = np.arange(int(RATE * seconds)) / RATE
    out = np.zeros_like(t)
    for ratio, amp, speed in METAL:
        out += amp * np.sin(2 * np.pi * freq * ratio * t) * np.exp(-decay * speed * t)
    attack = np.minimum(1.0, t * RATE / 40.0)          # без щелчка в начале
    return out * attack * volume


def place(buffer, start, sound):
    i = int(start * RATE)
    end = min(len(buffer), i + len(sound))
    buffer[i:end] += sound[: end - i]


def noise_click(seconds, volume):
    t = np.arange(int(RATE * seconds)) / RATE
    rng = np.random.default_rng(7)
    raw = rng.uniform(-1, 1, len(t))
    # Простой высокочастотный фильтр: разность соседних отсчётов — «щёлк», а не «шшш».
    hp = np.concatenate([[0], np.diff(raw)])
    return hp * np.exp(-60 * t) * volume


def coin(base):
    """Монетка: короткий удар и второй, выше — узнаваемое «дзынь-дынь»."""
    buf = np.zeros(int(RATE * 0.42))
    place(buf, 0.0, clink(base, 0.12, 0.7, decay=22))
    place(buf, 0.055, clink(base * 1.335, 0.36, 1.0, decay=9))
    return buf


def cash():
    """Касса: щелчок ящика, звонок и россыпь монет."""
    buf = np.zeros(int(RATE * 0.9))
    place(buf, 0.0, noise_click(0.08, 0.9))
    place(buf, 0.03, noise_click(0.06, 0.6))
    place(buf, 0.09, clink(2093.0, 0.7, 1.0, decay=5))       # C7 — звонок
    place(buf, 0.09, clink(2637.0, 0.7, 0.6, decay=5))       # E7
    rng = np.random.default_rng(3)
    for k in range(6):
        place(buf, 0.18 + k * 0.045 + rng.uniform(0, 0.02), clink(rng.uniform(2800, 4200), 0.12, 0.25, decay=28))
    return buf


def save(name, samples, gain=0.6):
    peak = np.max(np.abs(samples)) or 1.0
    data = (samples / peak * gain * 32767).astype(np.int16)
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / name), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(data.tobytes())


def main():
    for i, base in enumerate((1568.0, 1760.0, 1975.5), 1):   # G6, A6, B6
        save("coin_%d.wav" % i, coin(base), 0.55)
    save("cash.wav", cash(), 0.6)
    print("готово:", sorted(p.name for p in OUT.glob("*.wav")))


if __name__ == "__main__":
    main()
