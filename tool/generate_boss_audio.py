#!/usr/bin/env python3
"""Original synthesized boss stingers. Deterministic PCM; no external samples."""
import math
import pathlib
import random
import struct
import wave

RATE = 22050
ROOT = pathlib.Path(__file__).resolve().parents[1] / 'assets/audio'


def cue(name, duration, notes=(), rumble=0, wind=0, sweep=0, impact=0):
    rng = random.Random(name)
    data, low, phase = [], 0.0, 0.0
    for i in range(round(duration * RATE)):
        t = i / RATE
        u = t / duration
        envelope = min(1, t / .018) * min(1, (duration - t) / .08)
        low += (rng.uniform(-1, 1) - low) * .09
        phase += math.tau * (95 * (1 - u) + 38) / RATE
        growl = (math.sin(phase) + .35 * math.sin(phase * 2) + .15 * math.sin(phase * 3))
        sample = rumble * growl * (1 - u) * (.75 + .25 * math.sin(t * 31))
        sample += wind * low * math.sin(math.pi * u) ** 1.2
        sample += sweep * math.sin(math.tau * (180 * t + 750 * t * t)) * math.sin(math.pi * u)
        sample += impact * math.sin(math.tau * (75 * t + 1.7 * (1 - math.exp(-t * 40)))) * math.exp(-t * 8)
        for start, frequency, gain, decay in notes:
            age = t - start
            if age < 0:
                continue
            attack = min(1, age / .012)
            fundamental = math.sin(math.tau * frequency * age)
            overtone = .28 * math.sin(math.tau * frequency * 2.006 * age) * math.exp(-age * 8)
            sample += gain * (fundamental + overtone) * attack * math.exp(-age / decay)
        data.append(sample * envelope)
    peak = max(abs(v) for v in data) or 1
    scale = min(1, .78 / peak)
    with wave.open(str(ROOT / f'{name}.wav'), 'wb') as target:
        target.setparams((1, 2, RATE, len(data), 'NONE', 'not compressed'))
        target.writeframes(b''.join(struct.pack('<h', round(v * scale * 32767)) for v in data))


if __name__ == '__main__':
    ROOT.mkdir(parents=True, exist_ok=True)
    cue('boss_warning', 1.5, [(.08, 110, .2, .5), (.5, 116.54, .18, .5), (.9, 110, .22, .5)], rumble=.22, wind=.6)
    cue('boss_reveal', .9, [(.2, 146.83, .25, .3), (.23, 220, .18, .3), (.26, 293.66, .14, .35)], wind=.8, sweep=.08, impact=.4)
    cue('boss_roar', .82, [(0, 73.42, .2, .5), (.04, 110, .15, .4)], rumble=.4, wind=.5, impact=.35)
    cue('boss_charge', .62, wind=.25, sweep=.15)
    cue('boss_volley', .28, [(0, 146.83, .12, .07)], wind=.5, impact=.45)
    cue('boss_hit', .2, [(0, 880, .22, .04), (.01, 1323, .12, .045)], impact=.2)
    cue('boss_break', .85, [(0, 220, .22, .35), (.18, 207.65, .2, .25), (.36, 196, .18, .2)], wind=.6, sweep=.1)
    cue('boss_burst', 1.4, [(.02, 587.33, .18, .4), (.07, 880, .15, .5), (.13, 1174.66, .12, .5)], rumble=.28, wind=.5, impact=.7)
    cue('boss_victory', 1.65, [(i * .12, f, .22, .45) for i, f in enumerate([293.66, 440, 587.33, 739.99, 880])] + [(.62, 293.66, .13, .7), (.62, 587.33, .16, .65)])
