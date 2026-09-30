"""Generate BuzzIt's two original default tones with the Python standard library.

Run from the repository root: python3 tools/generate_default_sounds.py
The output is deterministic and uses no third-party recordings or samples.
"""

from array import array
from math import exp, pi, sin
from pathlib import Path
import sys
import wave

SAMPLE_RATE = 44_100
OUTPUT_DIR = Path(__file__).resolve().parents[1] / "assets" / "sound"


def write_wave(name: str, samples: list[float]) -> None:
    peak = max(abs(sample) for sample in samples)
    pcm = array("h", (round(sample * 0.72 / peak * 32767) for sample in samples))
    if sys.byteorder != "little":
        pcm.byteswap()
    with wave.open(str(OUTPUT_DIR / name), "wb") as sound:
        sound.setnchannels(1)
        sound.setsampwidth(2)
        sound.setframerate(SAMPLE_RATE)
        sound.writeframes(pcm.tobytes())


def ding() -> list[float]:
    duration = 0.7
    result = []
    for index in range(round(duration * SAMPLE_RATE)):
        time = index / SAMPLE_RATE
        attack = min(1.0, time / 0.008)
        release = min(1.0, (duration - time) / 0.06)
        envelope = attack * release * exp(-4.4 * time)
        tone = (
            sin(2 * pi * 880 * time)
            + 0.38 * sin(2 * pi * 1320 * time)
            + 0.16 * sin(2 * pi * 2200 * time)
        )
        result.append(envelope * tone)
    return result


def buzz() -> list[float]:
    duration = 0.48
    result = []
    for index in range(round(duration * SAMPLE_RATE)):
        time = index / SAMPLE_RATE
        attack = min(1.0, time / 0.008)
        release = min(1.0, (duration - time) / 0.06)
        envelope = attack * release * exp(-1.8 * time)
        tone = sum(
            weight * sin(2 * pi * 175 * harmonic * time)
            for harmonic, weight in ((1, 1.0), (3, 0.36), (5, 0.18), (7, 0.08))
        )
        result.append(envelope * tone)
    return result


if __name__ == "__main__":
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    write_wave("ding.wav", ding())
    write_wave("buzz.wav", buzz())
