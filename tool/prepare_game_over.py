"""Build the three-beat game-over cue from the ElevenLabs voice and piano takes.

Requires ffmpeg. The source takes are kept beside this script so the in-game
asset can be rebuilt without another generation.
"""

from array import array
from math import exp, pi, tanh
from pathlib import Path
import subprocess
import wave


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "tool/audio_sources/game_over"
RATE = 44_100
DURATION = 2.98
MUSIC_START = 1.17
MUSIC_GAIN = 2.0
MUSIC_DRIVE = 2.6
MUSIC_CEILING = 0.94


def decode(path: Path) -> array:
    raw = subprocess.check_output(
        [
            "ffmpeg", "-v", "error", "-i", str(path), "-f", "s16le",
            "-acodec", "pcm_s16le", "-ac", "1", "-ar", str(RATE), "-",
        ]
    )
    samples = array("h")
    samples.frombytes(raw)
    return samples


def sample_at(samples: array, position: float) -> float:
    index = int(position)
    if index + 1 >= len(samples):
        return 0.0
    fraction = position - index
    return (samples[index] * (1 - fraction) + samples[index + 1] * fraction) / 32768


def add_beat(
    mix: list[float],
    music: array,
    *,
    start: float,
    length: float,
    pitch: float,
    gain: float,
    cutoff: float,
    decay: float,
) -> None:
    """Play one sampled piano chord with its own pitch, shade and decay."""
    first = round((MUSIC_START + start) * RATE)
    count = min(round(length * RATE), len(mix) - first)
    alpha = min(1.0, 2 * pi * cutoff / (RATE + 2 * pi * cutoff))
    filtered = 0.0
    for i in range(count):
        seconds = i / RATE
        value = sample_at(music, i * pitch)
        filtered += alpha * (value - filtered)
        attack = min(1.0, seconds / 0.012)
        tail = min(1.0, (length - seconds) / 0.09)
        envelope = attack * max(0.0, tail) * exp(-seconds / decay)
        mix[first + i] += filtered * gain * envelope


def main() -> None:
    voice = decode(SOURCE / "voice.mp3")
    music = decode(SOURCE / "low_piano.mp3")
    mix = [0.0] * round(DURATION * RATE)

    # Preserve the same spoken reaction, including its natural consonant tail.
    voice_start = round(0.10 * RATE)
    voice_length = round(1.12 * RATE)
    for i in range(voice_length):
        seconds = i / RATE
        attack = min(1.0, seconds / 0.015)
        tail = min(1.0, (1.12 - seconds) / 0.025)
        mix[i] += voice[voice_start + i] / 32768 * 0.85 * attack * max(0.0, tail)

    # A quiet sustained piano bed connects the beats without adding attacks.
    music_first = round(MUSIC_START * RATE)
    for i in range(len(mix) - music_first):
        seconds = i / RATE
        fade = min(1.0, (DURATION - MUSIC_START - seconds) / 0.24)
        mix[music_first + i] += sample_at(music, i) * 0.10 * max(0.0, fade)

    # Three beats, about 0.58 s apart: progressively lower and darker, with
    # different attack strengths and overlapping tails.
    add_beat(mix, music, start=0.00, length=0.78, pitch=1.0000,
             gain=0.77, cutoff=5500, decay=0.64)
    add_beat(mix, music, start=0.58, length=0.80, pitch=0.9439,
             gain=0.82, cutoff=3500, decay=0.74)
    add_beat(mix, music, start=1.16, length=0.65, pitch=0.8909,
             gain=0.94, cutoff=2300, decay=0.86)

    # A very quiet lower octave gives the last beat a heavier final landing.
    add_beat(mix, music, start=1.16, length=0.65, pitch=0.4454,
             gain=0.15, cutoff=1200, decay=0.90)

    # Push the piano forward while soft limiting only the instrumental section.
    # The voice stays at its original level and piano transients remain smooth.
    for i in range(music_first, len(mix)):
        mix[i] = MUSIC_CEILING * tanh(
            MUSIC_DRIVE * mix[i] * MUSIC_GAIN / MUSIC_CEILING
        )

    peak = max(abs(value) for value in mix)
    scale = min(1.0, 0.94 / peak)
    pcm = array("h", (round(max(-1, min(1, value * scale)) * 32767) for value in mix))
    for target in (
        ROOT / "assets/audio/game_over.wav",
        ROOT / "assets/audio/game_over_examples/game_over_01.wav",
    ):
        target.parent.mkdir(parents=True, exist_ok=True)
        with wave.open(str(target), "wb") as output:
            output.setnchannels(1)
            output.setsampwidth(2)
            output.setframerate(RATE)
            output.writeframes(pcm.tobytes())
        print(f"{target.relative_to(ROOT)}: {DURATION:.2f}s, peak {peak * scale:.3f}")


if __name__ == "__main__":
    main()
