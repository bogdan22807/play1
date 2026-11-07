#!/usr/bin/env python3
"""Звуки денег для «Такси Кликер»: шелест купюры на тап (4 варианта) и пересчёт пачки.

Настоящая купюра звучит из трёх частей:
- «вжух» — трение бумаги: шум в полосе 1,5–7 кГц с быстрым нарастанием и спадом;
- хруст — россыпь мелких щелчков (волокна бумаги), высокие частоты;
- щелчок — бумагу дёрнули: очень короткий резкий импульс.
Пересчёт пачки — 10 быстрых шелестов подряд, как у счётчика купюр («фррррт»).

Запуск: python3 tools/make_sfx.py  → assets/sfx/bill_*.wav, count.wav
"""

import wave
from pathlib import Path

import numpy as np
from scipy.signal import butter, sosfilt

RATE = 44100
OUT = Path(__file__).resolve().parents[1] / "assets" / "sfx"


def band(signal, low, high, order=4):
    sos = butter(order, [low, high], btype="bandpass", fs=RATE, output="sos")
    return sosfilt(sos, signal)


def highpass(signal, cut, order=4):
    sos = butter(order, cut, btype="highpass", fs=RATE, output="sos")
    return sosfilt(sos, signal)


def flick(rng, seconds=0.2, center=3200.0, crisp=1.0):
    """Один шелест купюры."""
    n = int(RATE * seconds)
    t = np.arange(n) / RATE
    # «Вжух»: шум бумаги, огибающая — быстрый подъём и спад с небольшим хвостом.
    swish = band(rng.normal(0, 1, n), center * 0.45, min(center * 2.2, 9000))
    env = np.minimum(1.0, t / 0.012) * (np.exp(-t * 22) + 0.15 * np.exp(-t * 7))
    # Лёгкое «дрожание» громкости — бумага трётся неровно.
    wobble = 1.0 + 0.35 * np.sin(2 * np.pi * rng.uniform(25, 45) * t + rng.uniform(0, 6))
    out = swish * env * wobble
    # Хруст: редкие щелчки, гуще в начале, высокие частоты.
    density = 900 * np.exp(-t * 14) + 60
    clicks = (rng.random(n) < density / RATE) * rng.normal(0, 1, n) * 6.0
    out += band(clicks, 3000, 9000) * np.exp(-t * 9) * crisp
    # Щелчок в начале — купюру дёрнули.
    snap_n = int(RATE * 0.004)
    snap = band(rng.normal(0, 1, snap_n), 2500, 9000, order=2) * np.linspace(1, 0, snap_n) * 3.0 * crisp
    out[:snap_n] += snap
    # Мягкий конец без щелчка.
    out[-200:] *= np.linspace(1, 0, 200)
    return out


def count_stack(rng):
    """Пересчёт пачки: 10 шелестов подряд, последний — самый звонкий."""
    total = np.zeros(int(RATE * 0.75))
    for k in range(10):
        piece = flick(rng, 0.12, rng.uniform(2800, 3800), crisp=0.8) * (0.6 + 0.04 * k)
        start = int(RATE * (0.035 + k * 0.045))
        end = min(len(total), start + len(piece))
        total[start:end] += piece[: end - start]
    last = flick(rng, 0.22, 3400, crisp=1.3) * 1.1
    start = int(RATE * 0.5)
    total[start:start + len(last)] += last[: len(total) - start]
    return total


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
    for old in OUT.glob("coin_*.wav"):
        old.unlink()
    for old in OUT.glob("cash.wav"):
        old.unlink()
    rng = np.random.default_rng(2026)
    for i, (center, length) in enumerate(((2600, 0.18), (3200, 0.2), (3800, 0.16), (2900, 0.22)), 1):
        save("bill_%d.wav" % i, flick(rng, length, center), 0.55)
    save("count.wav", count_stack(rng), 0.55)
    print("готово:", sorted(p.name for p in OUT.glob("*.wav")))


if __name__ == "__main__":
    main()
