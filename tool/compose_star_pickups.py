"""Compose short layered pickup auditions from the ElevenLabs source takes.

Run from the repository root with ``python3 tool/compose_star_pickups.py``.
Only the Python standard library and ffmpeg are required.
"""

from __future__ import annotations

import array
import math
from pathlib import Path
import subprocess


RATE = 44100
ROOT = Path("assets/audio/star_layered_examples")
SOURCES = ROOT / "sources"
PREVIEWS = ROOT / "repeat_previews"
LENGTH = int(0.56 * RATE)

# Body, lift, glint, lift delay (ms), body/lift/glint gains, low bloom pitch.
RECIPES = [
    (2, 2, 1, 44, 1.00, 0.82, 0.28, 440),
    (4, 1, 2, 52, 1.05, 0.75, 0.32, 466),
    (1, 4, 3, 60, 0.95, 0.90, 0.25, 415),
    (3, 3, 1, 38, 1.12, 0.78, 0.30, 494),
    (2, 4, 4, 55, 0.90, 0.92, 0.22, 523),
    (4, 2, 3, 46, 1.08, 0.72, 0.34, 392),
    (1, 3, 2, 64, 1.00, 0.88, 0.26, 440),
    (3, 1, 4, 42, 1.10, 0.70, 0.36, 466),
    (2, 1, 3, 58, 0.98, 0.84, 0.24, 494),
    (4, 4, 1, 48, 1.02, 0.86, 0.28, 415),
]


def decode(path: Path) -> list[float]:
    raw = subprocess.check_output(
        [
            "ffmpeg", "-hide_banner", "-loglevel", "error", "-i", str(path),
            "-f", "f32le", "-ar", str(RATE), "-ac", "1", "-",
        ]
    )
    samples = array.array("f")
    samples.frombytes(raw)
    return list(samples)


def write_mp3(path: Path, samples: list[float]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    data = array.array("f", samples).tobytes()
    proc = subprocess.run(
        [
            "ffmpeg", "-y", "-hide_banner", "-loglevel", "error", "-f", "f32le",
            "-ar", str(RATE), "-ac", "1", "-i", "-", "-codec:a", "libmp3lame",
            "-q:a", "0", str(path),
        ],
        input=data,
        capture_output=True,
        check=False,
    )
    if proc.returncode:
        raise RuntimeError(proc.stderr.decode())


def trim_onset(samples: list[float]) -> list[float]:
    step = int(0.005 * RATE)
    levels = [
        math.sqrt(sum(value * value for value in samples[i : i + step]) / len(samples[i : i + step]))
        for i in range(0, len(samples), step)
    ]
    threshold = max(0.001, max(levels) * 0.08)
    first = next((i for i, level in enumerate(levels) if level >= threshold), 0)
    return samples[max(0, first * step - int(0.004 * RATE)) :]


def lowpass(samples: list[float], cutoff: float) -> list[float]:
    alpha = 1 - math.exp(-2 * math.pi * cutoff / RATE)
    previous = 0.0
    output = []
    for value in samples:
        previous += alpha * (value - previous)
        output.append(previous)
    return output


def fade(samples: list[float], attack_ms: float, release_ms: float) -> None:
    attack = min(len(samples), int(attack_ms * RATE / 1000))
    release = min(len(samples), int(release_ms * RATE / 1000))
    for i in range(attack):
        samples[i] *= 0.5 - 0.5 * math.cos(math.pi * i / attack)
    for i in range(release):
        samples[-release + i] *= 0.5 + 0.5 * math.cos(math.pi * i / release)


def soft_normalize(samples: list[float], mean_db: float, ceiling_db: float) -> list[float]:
    target = 10 ** (mean_db / 20)
    ceiling = 10 ** (ceiling_db / 20)

    def rms(gain: float) -> float:
        return math.sqrt(
            sum((ceiling * math.tanh(gain * value / ceiling)) ** 2 for value in samples)
            / len(samples)
        )

    low, high = 0.0, 1e6
    for _ in range(36):
        middle = (low + high) / 2
        if rms(middle) < target:
            low = middle
        else:
            high = middle
    return [ceiling * math.tanh(high * value / ceiling) for value in samples]


def prepare(kind: str, number: int) -> list[float]:
    samples = decode(SOURCES / f"{kind}_{number:02d}.mp3")
    dc = sum(samples) / len(samples)
    samples = trim_onset([value - dc for value in samples])
    cutoff = {"body": 3400, "lift": 5100, "glint": 4500}[kind]
    samples = lowpass(samples, cutoff)
    samples = samples[:LENGTH]
    fade(samples, attack_ms={"body": 6, "lift": 7, "glint": 4}[kind], release_ms=35)
    level = {"body": -20, "lift": -20, "glint": -25}[kind]
    return soft_normalize(samples, mean_db=level, ceiling_db=-8)


def add(mix: list[float], samples: list[float], offset_ms: float, gain: float) -> None:
    offset = int(offset_ms * RATE / 1000)
    for index, value in enumerate(samples[: len(mix) - offset]):
        mix[offset + index] += value * gain


def compose(recipe: tuple) -> list[float]:
    body, lift, glint, delay, body_gain, lift_gain, glint_gain, pitch = recipe
    mix = [0.0] * LENGTH
    add(mix, prepare("body", body), 0, body_gain)
    add(mix, prepare("glint", glint), 12, glint_gain)
    add(mix, prepare("lift", lift), delay, lift_gain)

    # A quiet low note gives the pickup weight without another hard transient.
    for i in range(int(0.18 * RATE)):
        time = i / RATE
        envelope = (1 - math.exp(-time / 0.009)) * math.exp(-time / 0.075)
        mix[i] += 0.022 * envelope * math.sin(2 * math.pi * pitch * time)

    mix = lowpass(mix, 5800)
    fade(mix, attack_ms=2, release_ms=28)
    return soft_normalize(mix, mean_db=-16.5, ceiling_db=-4.5)


def repeat_preview(samples: list[float]) -> list[float]:
    step = int(0.30 * RATE)
    mix = [0.0] * (step * 7 + len(samples))
    for n in range(8):
        add(mix, samples, n * 300, 1.0)
    ceiling = 10 ** (-3.5 / 20)
    return [ceiling * math.tanh(value / ceiling) for value in mix]


def main() -> None:
    for number, recipe in enumerate(RECIPES, start=1):
        samples = compose(recipe)
        name = f"layered_star_{number:02d}"
        write_mp3(ROOT / f"{name}.mp3", samples)
        write_mp3(PREVIEWS / f"{name}_repeat.mp3", repeat_preview(samples))
        print(name)


if __name__ == "__main__":
    main()
