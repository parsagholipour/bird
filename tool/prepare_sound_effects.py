#!/usr/bin/env python3
"""Master the offline SFX bank. Requires FFmpeg; no network or credentials.

ElevenLabs source takes belong in build/sound-effects/source. Short tonal
feedback is composed here; generated Foley supplies the organic combat layer.
"""
import argparse
import array
import hashlib
import json
import math
from pathlib import Path
import random
import re
import subprocess
import sys
import wave

ROOT = Path(__file__).resolve().parents[1]
RATE = 44100


def decode(path):
    raw = subprocess.check_output([
        'ffmpeg', '-v', 'error', '-i', str(path), '-f', 'f32le',
        '-ac', '1', '-ar', str(RATE), '-',
    ])
    samples = array.array('f', raw)
    if sys.byteorder != 'little':
        samples.byteswap()
    return list(samples)


def excerpt(samples, seconds, stretch=False, transient=False, attack_lead=.07):
    # Remove only leading silence; retain the transient and quiet organic tail.
    window = 220
    energies = [math.sqrt(sum(v * v for v in samples[i:i+window]) / window)
                for i in range(0, len(samples), window)]
    threshold = max(energies) * .055
    first = next((i for i, v in enumerate(energies) if v > threshold), 0)
    if transient:
        # Some generated takes contain several gestures. Extract one decisive
        # attack, not a quiet preliminary rustle or a repeated sequence.
        peak_window = max(range(len(energies)), key=energies.__getitem__)
        first = peak_window
        while first > 0 and energies[first - 1] > max(energies) * .12:
            first -= 1
        first = max(first, peak_window - int(attack_lead * RATE / window))
    start = max(0, first * window - int(.004 * RATE))
    samples = samples[start:]
    count = int(seconds * RATE)
    if stretch and len(samples) > count:
        # Warning/roar envelopes retain their complete gesture in the animation.
        ratio = (len(samples) - 1) / max(1, count - 1)
        samples = [samples[min(len(samples)-1, int(i * ratio))] for i in range(count)]
    return (samples[:count] + [0.0] * count)[:count]


def bell(data, hz, at, length, gain=.22, warm=False):
    start = int(at * RATE)
    for j in range(min(int(length * RATE), len(data) - start)):
        t = j / RATE
        env = (1 - math.exp(-t / .0025)) * math.exp(-t / (length * .23))
        # Wood/bell partials with independent damping, never a raw sine beep.
        value = math.sin(2 * math.pi * hz * t)
        value += .35 * math.sin(2 * math.pi * hz * (2.01 if warm else 2.76) * t) * math.exp(-t * 18)
        value += .13 * math.sin(2 * math.pi * hz * 4.1 * t) * math.exp(-t * 30)
        data[start + j] += gain * env * value


def whoosh(data, seconds, gain=.2, descending=False, seed=9):
    rng = random.Random(seed)
    low = 0.0
    for i in range(min(len(data), int(seconds * RATE))):
        t = i / RATE
        low += .11 * (rng.uniform(-1, 1) - low)
        env = math.sin(math.pi * t / seconds) ** 1.5
        freq = (800 - 650 * t / seconds) if descending else (180 + 950 * t / seconds)
        data[i] += gain * env * (low + .22 * math.sin(2 * math.pi * freq * t))


def impact(data, seconds=.25, gain=.3, seed=12, heavy=False):
    rng = random.Random(seed)
    phase = 0.0
    low = 0.0
    for i in range(min(len(data), int(seconds * RATE))):
        t = i / RATE
        phase += 2 * math.pi * ((70 if heavy else 160) + 160 * math.exp(-t * 40)) / RATE
        low += .3 * (rng.uniform(-1, 1) - low)
        attack = min(1, t / .0015)
        data[i] += gain * attack * (math.sin(phase) * math.exp(-t * 18) + low * math.exp(-t * 35))


NOTES = {
    'star': [1174.66, 1567.98], 'point': [659.25, 880],
    'trio': [783.99, 987.77, 1174.66], 'perfect': [659.25, 987.77, 1318.51],
    'streak': [783.99, 987.77, 1174.66, 1567.98],
    'magnet': [392, 587.33, 783.99, 987.77, 1174.66],
    'magnet_end': [783.99, 587.33, 392],
    'letter': [523.25, 783.99], 'delivery': [659.25, 783.99, 1046.5],
    'letter_lost': [440, 329.63, 220],
    'wing': [783.99, 1046.5, 1318.51], 'cloud': [523.25, 659.25, 880, 783.99],
    'shield': [587.33, 783.99, 1174.66], 'shield_pop': [1174.66, 587.33],
    'heart': [523.25, 659.25, 1046.5], 'final_stretch': [523.25, 783.99],
    'ready': [523.25], 'go': [523.25, 659.25, 783.99],
    'finish': [659.25, 523.25, 392],
    'complete': [523.25, 659.25, 783.99, 1046.5, 1318.51],
    'record': [659.25, 830.61, 987.77, 1318.51],
    'unlock': [523.25, 659.25, 783.99, 1046.5],
    'boss_victory': [293.66, 440, 587.33, 739.99, 880],
    'deflect': [1567.98, 1174.66], 'boss_block': [880, 1323],
    'boss_hit': [440, 1174.66], 'boss_shield': [293.66, 440, 587.33],
    'shot_charged': [1318.51, 1760], 'ammo_empty': [293.66, 220],
    'sprint_ready': [698.46, 1046.5, 1396.91],
}


MENU_NOTES = {
    'ui_tap': [783.99, 987.77],
    'ui_back': [783.99],
    'ui_toggle': [987.77, 1174.66],
    'pause': [587.33, 783.99],
    'resume': [783.99, 987.77, 1174.66],
}


def menu_chime(name, seconds):
    """Soft rounded major-key plucks: a friendly, tiny reward on each action."""
    data = [0.0] * int(RATE * seconds)
    notes = MENU_NOTES[name]
    for index, hz in enumerate(notes):
        start = int(index * .055 * RATE)
        length = seconds - start / RATE
        for j in range(len(data) - start):
            t = j / RATE
            # Gentle mallet attack and only tuned harmonics. The previous
            # metallic partials and very short decay read as an alarm/click.
            attack = 1 - math.exp(-t / .007)
            release = math.exp(-t / .080) * min(1, (length - t) / .055)
            fundamental = math.sin(2 * math.pi * hz * t)
            octave = .10 * math.sin(2 * math.pi * hz * 2 * t) * math.exp(-t * 18)
            body = .12 * math.sin(2 * math.pi * hz * .5 * t)
            data[start + j] += (.22 + index * .02) * attack * release * (fundamental + octave + body)
    return data


def rush(data):
    """Air tearing past: a fast swell of filtered noise over a rising body."""
    rng = random.Random(29)
    phase = 0.0
    low = band = 0.0
    seconds = len(data) / RATE
    for i in range(len(data)):
        t = i / RATE
        noise = rng.uniform(-1, 1)
        low += .20 * (noise - low)
        band += .45 * (low - band)
        env = min(1, t / .035) * math.exp(-t / (seconds * .32))
        phase += 2 * math.pi * (240 + 760 * min(1, t / (seconds * .45))) / RATE
        data[i] += env * (.60 * (low - band) + .30 * band + .14 * math.sin(phase))


def crumble(data, seed, grains=9):
    """Chunks landing after a break: short, darkening noise ticks."""
    rng = random.Random(seed)
    for g in range(grains):
        at = .03 + rng.random() ** 1.6 * (len(data) / RATE - .1)
        start = int(at * RATE)
        gain = .30 * (1 - g / grains) + .08
        low = 0.0
        smooth = .18 + rng.random() * .35
        for j in range(min(int(.035 * RATE), len(data) - start)):
            t = j / RATE
            low += smooth * (rng.uniform(-1, 1) - low)
            data[start + j] += gain * min(1, t / .0008) * math.exp(-t * 110) * low


def ship_bell(data, at, gain=.24):
    """A struck brass ship's bell: inharmonic partials, long shimmer."""
    start = int(at * RATE)
    partials = [(1, 1, 1.9), (2.0, .55, 2.6), (2.76, .42, 4.2),
                (5.4, .22, 7.5), (8.9, .10, 12)]
    for j in range(len(data) - start):
        t = j / RATE
        strike = 1 - math.exp(-t / .0012)
        value = sum(a * math.sin(2 * math.pi * 587.33 * r * t + r) * math.exp(-t * d)
                    for r, a, d in partials)
        # A slight beating between near partials makes it ring like metal.
        value += .18 * math.sin(2 * math.pi * 591.2 * t) * math.exp(-t * 2.1)
        data[start + j] += gain * strike * value


def sea_noise(data, seed, start, seconds, gain, bright_from, bright_to,
              attack=.2, release=.35):
    """Moving water: two-pole filtered noise whose brightness sweeps."""
    rng = random.Random(seed)
    low = band = 0.0
    first = int(start * RATE)
    count = min(len(data) - first, int(seconds * RATE))
    for j in range(count):
        t = j / RATE
        u = t / seconds
        bright = bright_from + (bright_to - bright_from) * u
        low += bright * (rng.uniform(-1, 1) - low)
        band += bright * .6 * (low - band)
        env = min(1, t / attack) * min(1, (seconds - t) / release)
        # Slow swells so the water churns instead of hissing flat.
        churn = .75 + .25 * math.sin(2 * math.pi * 3.1 * t + seed)
        data[first + j] += gain * env * churn * (band + .45 * (low - band))


def boom(data, seed, gain=.9, hz=58):
    """Black powder: a bright crack, a falling chest thump, rolling smoke."""
    rng = random.Random(seed)
    phase = 0.0
    low = 0.0
    for i in range(len(data)):
        t = i / RATE
        crack = rng.uniform(-1, 1) * math.exp(-t / .006)
        phase += 2 * math.pi * (hz + 140 * math.exp(-t * 26)) / RATE
        thump = math.sin(phase) * math.exp(-t * 7.5) * min(1, t / .002)
        low += .035 * (rng.uniform(-1, 1) - low)
        rumble = low * 7 * min(1, t / .03) * math.exp(-t * 3.4)
        data[i] += gain * (.55 * crack + thump + .6 * rumble)


def flame(data, seed, start, seconds, gain, attack=.05, release=.3,
          flicker=11.0):
    """A jet of fire: a dark roaring body under a bright hiss, torn up by
    turbulence so it churns rather than whooshing flat."""
    rng = random.Random(seed)
    low = mid = hiss = 0.0
    first = int(start * RATE)
    count = min(len(data) - first, int(seconds * RATE))
    for j in range(count):
        t = j / RATE
        noise = rng.uniform(-1, 1)
        low += .045 * (noise - low)
        mid += .22 * (noise - mid)
        hiss = noise - mid
        env = min(1, t / attack) * min(1, (seconds - t) / release)
        # Two unsynchronised flutters make the flame lick and gutter.
        churn = (.72 + .18 * math.sin(2 * math.pi * flicker * t + seed)
                 + .10 * math.sin(2 * math.pi * flicker * 1.73 * t))
        data[first + j] += gain * env * churn * (2.6 * low + 1.1 * (mid - low) + .07 * hiss)


def crackle(data, seed, start, seconds, count, gain):
    """Embers popping: tiny bright snaps scattered through a span."""
    rng = random.Random(seed)
    for _ in range(count):
        at = start + rng.random() * seconds
        first = int(at * RATE)
        size = gain * (.4 + .6 * rng.random())
        for j in range(min(int(.004 * RATE), len(data) - first)):
            tt = j / RATE
            data[first + j] += size * rng.uniform(-1, 1) * math.exp(-tt / .0009)


def growl(data, start, seconds, hz_from, hz_to, gain, seed, swell=0.0):
    """A great throat: a low saw-like drone with a slow, rough tremor.
    [swell] starts it that much quieter and lets it build to full."""
    rng = random.Random(seed)
    phase = 0.0
    first = int(start * RATE)
    count = min(len(data) - first, int(seconds * RATE))
    rough = 0.0
    for j in range(count):
        t = j / RATE
        u = t / seconds
        hz = hz_from + (hz_to - hz_from) * u
        rough += .002 * (rng.uniform(-1, 1) - rough)
        phase += 2 * math.pi * hz * (1 + 6 * rough) / RATE
        tone = sum(math.sin(k * phase) / k for k in range(1, 7))
        tremor = .7 + .3 * math.sin(2 * math.pi * 7.5 * t)
        env = min(1, t / .12) * min(1, (seconds - t) / .08)
        env *= 1 - swell + swell * u
        data[first + j] += gain * env * tremor * tone


def chirp(data, at, length, hz_from, hz_to, gain):
    """One bat call: a quick falling sweep with a soft attack."""
    start = int(at * RATE)
    phase = 0.0
    for j in range(min(int(length * RATE), len(data) - start)):
        t = j / RATE
        u = t / length
        phase += 2 * math.pi * (hz_from + (hz_to - hz_from) * u) / RATE
        env = math.sin(math.pi * u) ** 2
        data[start + j] += gain * env * (math.sin(phase) + .25 * math.sin(2 * phase))


def whistle(data, seed, start, seconds, hz_from, hz_to, gain, tremor=0.0,
            swell=0.0):
    """A shrill voice: a few detuned partials gliding from [hz_from] to
    [hz_to], roughened by a fast [tremor] and a touch of breath noise.
    [swell] starts it that much quieter and lets it build to full."""
    rng = random.Random(seed)
    first = int(start * RATE)
    count = min(len(data) - first, int(seconds * RATE))
    phases = [0.0, 0.0, 0.0]
    breath = 0.0
    for j in range(count):
        t = j / RATE
        u = t / seconds
        hz = hz_from * (hz_to / hz_from) ** u
        wobble = 1 + (.035 * math.sin(2 * math.pi * tremor * t) if tremor else 0)
        tone = 0.0
        for k, (detune, amp) in enumerate([(1, 1), (1.012, .6), (1.5, .28)]):
            phases[k] += 2 * math.pi * hz * detune * wobble / RATE
            tone += amp * math.sin(phases[k])
        breath += .5 * (rng.uniform(-1, 1) - breath)
        env = min(1, t / .025) * min(1, (seconds - t) / .25)
        env *= 1 - swell + swell * u
        data[first + j] += gain * env * (tone / 1.9 + .25 * breath)

# ---------------------------------------------------------------------------
# New York (rules version 43): the Alley Pigeon, Steam Geysers, King Coo and
# the Searchlight Gargoyle. Seeds are unique per cue: steam 201-249, pigeon
# 251-299, King Coo 301-399, Gargoyle 401-499 (existing cues use up to 191).
NEW_YORK_CUES = [
    'pigeon_coo', 'pigeon_flap', 'pigeon_snatch', 'pigeon_defeat', 'star_rescue',
    'steam_hiss', 'steam_burst', 'pipe_clang', 'steam_ride',
    'gargoyle_strike', 'gargoyle_awaken', 'beam_warning', 'beam_sweep',
    'beam_spot', 'lamp_vent', 'lamp_glance', 'feather_drop',
    'coo_roar', 'coo_whistle', 'crumb_throw', 'crumb_splat', 'squad_flutter',
    'coo_puff', 'coo_pop', 'coo_defeat',
    # The audio fix round: a shorter arrival shout timed to the beak, the
    # Gargoyle's own fury and shattering, the chest inflating at King Coo's end.
    'coo_shout', 'gargoyle_fury', 'gargoyle_shatter', 'coo_inflate',
]


def coo_voice(data, at, length, hz_from, hz_to, gain=.30, vibrato=6.0,
              roll=24.0, seed=1, bright=0.0):
    """One pigeon coo: a hooty, nearly sinusoidal voice (a fundamental and a
    weak second harmonic), a slow vibrato, a fast throat roll that roughens the
    amplitude and a touch of breath. Glides exponentially [hz_from] to [hz_to].
    [bright] adds harmonics 4-10 weighted by a vowel-like formant near 750 Hz
    (1.0 = as loud as the fundamental at its peak), so a deep voice still has
    something a phone speaker can play."""
    rng = random.Random(seed)
    first = int(at * RATE)
    count = min(len(data) - first, int(length * RATE))
    phase = 0.0
    breath = 0.0
    for j in range(count):
        t = j / RATE
        u = t / length
        hz = hz_from * (hz_to / hz_from) ** u
        hz *= 1 + .018 * math.sin(2 * math.pi * vibrato * t)
        phase += 2 * math.pi * hz / RATE
        tone = math.sin(phase) + .42 * math.sin(2 * phase + .6) + .12 * math.sin(3 * phase)
        if bright:
            # A vowel-like formant near 750 Hz that the harmonics slide through.
            tone += bright * sum(
                math.exp(-((k * hz - 750) / 450) ** 2) * math.sin(k * phase + k)
                for k in range(4, 11))
        rough = .80 + .20 * math.sin(2 * math.pi * roll * t)
        breath += .3 * (rng.uniform(-1, 1) - breath)
        env = min(1, t / .04) * min(1, (length - t) / .09) * (1 - .25 * u)
        data[first + j] += gain * env * rough * (tone / 1.4 + .05 * breath)


def clap(data, at, gain, seed):
    """A wing clap: a dry band-limited 'whap' (about 280 Hz - 1.7 kHz) over a
    soft body thump."""
    rng = random.Random(seed)
    start = int(at * RATE)
    low = knee = 0.0
    for j in range(min(int(.09 * RATE), len(data) - start)):
        t = j / RATE
        noise = rng.uniform(-1, 1)
        low += .22 * (noise - low)
        knee += .04 * (low - knee)
        whap = (low - knee) * min(1, t / .0006) * math.exp(-t / .020)
        thump = math.sin(2 * math.pi * 260 * t) * math.exp(-t / .022) * .30
        data[start + j] += gain * (2.2 * whap + thump)


def tick(data, at, hz, gain):
    """A beak tick: a few milliseconds of bright sine."""
    start = int(at * RATE)
    for j in range(min(int(.006 * RATE), len(data) - start)):
        t = j / RATE
        data[start + j] += gain * math.sin(2 * math.pi * hz * t) * math.exp(-t / .0018)


def puff(data, seed, start, seconds, gain):
    """Feathers: soft low-passed noise that swells and thins."""
    rng = random.Random(seed)
    low = 0.0
    first = int(start * RATE)
    for j in range(min(int(seconds * RATE), len(data) - first)):
        t = j / RATE
        low += .07 * (rng.uniform(-1, 1) - low)
        data[first + j] += gain * (math.sin(math.pi * t / seconds) ** 2) * low * 5


def steam_noise(data, seed, start, seconds, gain, lp_from, lp_to, hp=.30,
                attack=.02, release=.2, spit=0.0, spit_to=0.0):
    """Steam: white noise band-passed between a slow low-pass knee [hp] and a
    sweeping high cut (one-pole coefficient from [lp_from] to [lp_to], larger is
    brighter), so it hisses rather than rumbles. [spit] gates it at that many
    Hz (rising to [spit_to]) like a valve leaking in gasps."""
    rng = random.Random(seed)
    knee = high = 0.0
    first = int(start * RATE)
    count = min(len(data) - first, int(seconds * RATE))
    phase = 0.0
    for j in range(count):
        t = j / RATE
        u = t / seconds
        coef = lp_from + (lp_to - lp_from) * u
        noise = rng.uniform(-1, 1)
        knee += hp * (noise - knee)
        high += coef * ((noise - knee) - high)
        env = min(1, t / attack) * min(1, (seconds - t) / release)
        if spit:
            phase += 2 * math.pi * (spit + (spit_to - spit) * u) / RATE
            env *= .62 + .38 * math.sin(phase) * math.sin(phase * .37 + 1.3)
        data[first + j] += gain * env * high


def band_noise(data, seed, start, seconds, gain, hz, q=1.6, attack=.03,
               release=.2):
    """Noise through two cascaded resonant band-pass filters (state-variable,
    12 dB per octave in all) centred on [hz]: a rustle or a whisper with a
    clear colour, unlike [steam_noise]'s wide hiss."""
    rng = random.Random(seed)
    f = 2 * math.sin(math.pi * hz / RATE)
    damp = 1 / q
    low = band = low2 = band2 = 0.0
    first = int(start * RATE)
    count = min(len(data) - first, int(seconds * RATE))
    for j in range(count):
        t = j / RATE
        noise = rng.uniform(-1, 1)
        low += f * band
        band += f * (noise - low - damp * band)
        low2 += f * band2
        band2 += f * (band - low2 - damp * band2)
        env = min(1, t / attack) * min(1, (seconds - t) / release)
        data[first + j] += gain * env * band2


def clang(data, at, hz, gain, seed=5):
    """An iron pipe or grate struck once: inharmonic partials with their own
    decays over a tiny noise tick."""
    start = int(at * RATE)
    partials = [(1.0, 1.0, 9.0), (2.32, .55, 14.0), (3.90, .30, 22.0),
                (5.60, .16, 34.0)]
    rng = random.Random(seed)
    for j in range(len(data) - start):
        t = j / RATE
        if t > .6:
            break
        strike = 1 - math.exp(-t / .0008)
        value = sum(a * math.sin(2 * math.pi * hz * r * t) * math.exp(-t * d)
                    for r, a, d in partials)
        value += .5 * rng.uniform(-1, 1) * math.exp(-t / .0025)
        data[start + j] += gain * strike * value


def updraft(data, seed, seconds, gain, f_from, f_to):
    """A rising column of air: noise through a resonant band-pass whose centre
    climbs from [f_from] to [f_to] Hz under a smooth swell."""
    rng = random.Random(seed)
    low = band = 0.0
    for i in range(min(len(data), int(seconds * RATE))):
        t = i / RATE
        u = t / seconds
        f = f_from * (f_to / f_from) ** u
        k = 2 * math.sin(math.pi * f / RATE)
        noise = rng.uniform(-1, 1)
        low += k * band
        high = noise - low - .35 * band
        band += k * high
        env = math.sin(math.pi * u) ** 2
        data[i] += gain * env * band


def pea_whistle(data, at, length, hz=2950.0, trill=28.0, depth=.55, gain=.30,
                seed=3):
    """A police pea whistle: a steady two-tone carrier (two reeds 130 Hz apart)
    whose amplitude flutters at the pea's rattle rate, over band-limited breath.
    Steady pitch and AM, so it never resembles the falling FM screeches."""
    rng = random.Random(seed)
    first = int(at * RATE)
    count = min(len(data) - first, int(length * RATE))
    p1 = p2 = 0.0
    low = band = 0.0
    for j in range(count):
        t = j / RATE
        hz_t = hz * (1 + .012 * min(1, t / .05))  # a small blow-in glide
        p1 += 2 * math.pi * hz_t / RATE
        p2 += 2 * math.pi * (hz_t + 130) / RATE
        flutter = 1 - depth * (.5 + .5 * math.sin(2 * math.pi * trill * t))
        noise = rng.uniform(-1, 1)
        low += .55 * (noise - low)
        band += .85 * (low - band)
        hiss = low - band
        env = min(1, t / .008) * min(1, (length - t) / .06)
        data[first + j] += gain * env * flutter * (math.sin(p1) + .7 * math.sin(p2) + .35 * hiss)


def wing_claps(data, at, length, rate_from, rate_to, gain=.22, seed=5):
    """A flock taking off: band-passed clap transients whose density rises then
    thins; each is a few ms of filtered noise with its own centre frequency."""
    rng = random.Random(seed)
    t = at
    while t < at + length:
        u = (t - at) / length
        rate = rate_from + (rate_to - rate_from) * math.sin(math.pi * u) ** .7
        start = int(t * RATE)
        centre = rng.uniform(700, 2600)
        low = 0.0
        size = gain * (.4 + .6 * rng.random()) * (1 - .55 * u)
        for j in range(min(int(.028 * RATE), len(data) - start)):
            tt = j / RATE
            noise = rng.uniform(-1, 1)
            low += (centre / 9000) * (noise - low)
            data[start + j] += size * (low - .4 * noise) * math.exp(-tt / .0075) * min(1, tt / .001)
        t += 1.0 / max(6.0, rate) * rng.uniform(.6, 1.4)


def squeak(data, at, length, hz_from, hz_to, gain=.16, tremor=14.0):
    """Rubber under strain: a glide with a fast tremor and a pinched harmonic."""
    first = int(at * RATE)
    count = min(len(data) - first, int(length * RATE))
    phase = 0.0
    for j in range(count):
        t = j / RATE
        u = t / length
        hz = hz_from + (hz_to - hz_from) * u ** .8
        phase += 2 * math.pi * hz * (1 + .03 * math.sin(2 * math.pi * tremor * t)) / RATE
        env = math.sin(math.pi * min(1, u)) ** .7
        data[first + j] += gain * env * (math.sin(phase) + .35 * math.sin(3 * phase))


def arc_buzz(data, seed, start, seconds, hz_from, hz_to, glide, gain,
             tremor=7.0, release=.25, swell=0.0):
    """A searchlight's carbon arc: a bright buzzing saw (harmonics 1..n, each
    1/k^.55 as loud, so the mids carry on a phone) that glides from [hz_from]
    to [hz_to] over [glide] seconds and then holds, its level fluttering at
    [tremor] Hz, with a hiss of arc noise. [swell] starts it that much quieter
    and lets it build to full."""
    rng = random.Random(seed)
    first = int(start * RATE)
    count = min(len(data) - first, int(seconds * RATE))
    phase = 0.0
    hiss = 0.0
    for j in range(count):
        t = j / RATE
        u = min(1.0, t / glide)
        hz = hz_from + (hz_to - hz_from) * u * u * (3 - 2 * u)
        phase += 2 * math.pi * hz / RATE
        top = max(3, min(24, int(3200 / hz)))
        saw = sum(math.sin(k * phase) / k ** .55 for k in range(1, top + 1))
        hiss += .35 * (rng.uniform(-1, 1) - hiss)
        flutter = .78 + .22 * math.sin(2 * math.pi * tremor * t)
        env = min(1, t / .05) * min(1, (seconds - t) / release)
        env *= 1 - swell + swell * t / seconds
        data[first + j] += gain * env * flutter * (saw + .10 * hiss)


def stone_grind(data, seed, start, seconds, gain, lo=250, hi=1500, rate=8.0,
                swell=0.0):
    """Stone grinding on stone: band-passed noise in a stick-slip rhythm of
    [rate] gasps a second, each slip a little irregular."""
    rng = random.Random(seed)
    a_hi = 1 - math.exp(-2 * math.pi * hi / RATE)
    a_lo = 1 - math.exp(-2 * math.pi * lo / RATE)
    low = knee = 0.0
    first = int(start * RATE)
    count = min(len(data) - first, int(seconds * RATE))
    for j in range(count):
        t = j / RATE
        u = t / seconds
        noise = rng.uniform(-1, 1)
        low += a_hi * (noise - low)
        knee += a_lo * (low - knee)
        slip = .5 + .5 * math.sin(2 * math.pi * rate * t + 1.7 * math.sin(2 * math.pi * 1.3 * t)
                                  + .9 * math.sin(2 * math.pi * 2.9 * t))
        env = min(1, t / .08) * min(1, (seconds - t) / .15) * (1 - swell + swell * u)
        data[first + j] += gain * env * slip * slip * (low - knee) * 4


def crinkle(data, seed, start, seconds, count, gain, lo=1100, hi=3200):
    """Crumbs, foil or chips: [count] short grains of band-passed noise (each
    about 12 ms, a resonance somewhere in [lo, hi] Hz) scattered through a
    span, louder early. Unlike [crumble] it lives in the mids a phone plays."""
    rng = random.Random(seed)
    for g in range(count):
        at = start + rng.random() ** 1.3 * seconds
        centre = rng.uniform(lo, hi)
        f = 2 * math.sin(math.pi * centre / RATE)
        size = gain * (1 - .55 * g / count) * (.5 + .5 * rng.random())
        low = band = 0.0
        first = int(at * RATE)
        for j in range(min(int(.02 * RATE), len(data) - first)):
            t = j / RATE
            noise = rng.uniform(-1, 1)
            low += f * band
            band += f * (noise - low - .25 * band)
            data[first + j] += size * min(1, t / .0006) * math.exp(-t / .0045) * band

# ---------------------------------------------------------------------------
# The campaign finish line: the gate's "almost there" sting, the tape snap and
# confetti cannons, the birds' cheer and the swoop onto the result cloud.
# finish_snap and finish_cheer start from ElevenLabs takes (see main()); the
# other two are syntheses. Seeds 501-549.
FINISH_CUES = ['finish_near', 'finish_snap', 'finish_cheer', 'finish_swoop']


def pluck(data, at, hz, gain, decay=.32):
    """A harp string: six harmonics, the higher ones softer and quicker to die,
    over a 2 ms finger attack."""
    start = int(at * RATE)
    for j in range(min(int(decay * 5 * RATE), len(data) - start)):
        t = j / RATE
        value = sum(math.sin(2 * math.pi * hz * k * t) * math.exp(-t * k / decay) / k ** 1.3
                    for k in range(1, 7))
        data[start + j] += gain * min(1, t / .002) * value


def shaker(data, seed, start, seconds, gain, rate_from, rate_to, release=.12):
    """A shaker or soft snare roll: high-passed noise grains [rate_from] rising
    to [rate_to] a second, swelling from silence to full at the end of the span
    and then let go over [release] seconds, so it builds and never lands."""
    rng = random.Random(seed)
    first = int(start * RATE)
    count = min(len(data) - first, int((seconds + release) * RATE))
    low = high = 0.0
    phase = 0.0
    for j in range(count):
        t = j / RATE
        u = min(1.0, t / seconds)
        phase += (rate_from + (rate_to - rate_from) * u) / RATE
        grain = math.exp(-(phase % 1) / .22)
        noise = rng.uniform(-1, 1)
        # Beads in a gourd: about 2.5 to 9 kHz.
        low += .30 * (noise - low)
        high += .70 * ((noise - low) - high)
        env = u ** 1.8 * (1 if t < seconds else math.exp(-(t - seconds) / (release / 3)))
        data[first + j] += gain * env * (.35 + .65 * grain) * high


def popper(data, at, gain, hz, seed):
    """A party popper: a sharp cap crack, the paper tube's hollow pop near [hz]
    and a small chest thump."""
    rng = random.Random(seed)
    start = int(at * RATE)
    f = 2 * math.sin(math.pi * hz / RATE)
    low = band = 0.0
    for j in range(min(int(.09 * RATE), len(data) - start)):
        t = j / RATE
        noise = rng.uniform(-1, 1)
        low += f * band
        band += f * (noise - low - .30 * band)
        crack = noise * math.exp(-t / .0011)
        body = band * math.exp(-t / .011)
        thump = math.sin(2 * math.pi * (150 + 250 * math.exp(-t / .004)) * t) * math.exp(-t / .016)
        data[start + j] += gain * min(1, t / .0002) * (.9 * crack + 1.6 * body + .45 * thump)


def twang(data, at, hz, length, gain, wobble=13.0):
    """A taut ribbon let go: a tone that springs down to [hz] from a little
    above it and wobbles at [wobble] Hz while it dies away."""
    start = int(at * RATE)
    phase = 0.0
    for j in range(min(int(length * RATE), len(data) - start)):
        t = j / RATE
        bend = 1 + .12 * math.exp(-t / .025)
        vibrato = 1 + .025 * math.sin(2 * math.pi * wobble * t) * math.exp(-t / (length * .6))
        phase += 2 * math.pi * hz * bend * vibrato / RATE
        env = min(1, t / .003) * math.exp(-t / (length * .28))
        data[start + j] += gain * env * (math.sin(phase) + .30 * math.sin(2 * phase))


def tweet(data, at, length, hz_from, hz_to, gain, vibrato=24.0):
    """One bird's whistled note: an exponential glide, a quick bird vibrato and
    a soft swell and fall; two of them make a 'wheet-whoo'."""
    first = int(at * RATE)
    count = min(len(data) - first, int(length * RATE))
    phase = 0.0
    for j in range(count):
        t = j / RATE
        u = t / length
        hz = hz_from * (hz_to / hz_from) ** u
        phase += 2 * math.pi * hz * (1 + .012 * math.sin(2 * math.pi * vibrato * t)) / RATE
        env = math.sin(math.pi * min(1.0, u ** .7)) ** 1.5
        data[first + j] += gain * env * (math.sin(phase) + .12 * math.sin(2 * phase))


def swoop_air(data, seed, peak, seconds, gain, f_from, f_to):
    """Air rushing past something flying closer: noise through a resonant
    band-pass whose centre climbs from [f_from] to [f_to] Hz, swelling to
    [peak] seconds and falling away quickly after it."""
    rng = random.Random(seed)
    low = band = body = 0.0
    for i in range(min(len(data), int(seconds * RATE))):
        t = i / RATE
        u = min(1.0, t / peak)
        f = f_from * (f_to / f_from) ** u
        k = 2 * math.sin(math.pi * f / RATE)
        noise = rng.uniform(-1, 1)
        low += k * band
        band += k * (noise - low - .45 * band)
        body += .05 * (noise - body)
        env = u ** 2.2 if t < peak else math.exp(-(t - peak) / .045)
        data[i] += gain * env * (1.4 * band + .5 * body)


def fwump(data, at, gain, seed):
    """Landing on a cloud: a cushioned low thump with a 6 ms rounded attack
    and a soft 'poof' of air around 500 Hz, which a phone can play."""
    rng = random.Random(seed)
    start = int(at * RATE)
    f = 2 * math.sin(math.pi * 500 / RATE)
    low = band = smooth = 0.0
    phase = 0.0
    for j in range(min(int(.30 * RATE), len(data) - start)):
        t = j / RATE
        attack = .5 - .5 * math.cos(math.pi * min(1.0, t / .006))
        phase += 2 * math.pi * (85 + 70 * math.exp(-t / .03)) / RATE
        noise = rng.uniform(-1, 1)
        low += f * band
        band += f * (noise - low - 1.0 * band)
        smooth += .06 * (noise - smooth)
        value = (.5 * math.sin(phase) * math.exp(-t / .08) + 1.0 * smooth * math.exp(-t / .07)
                 + 5.0 * band * math.exp(-t / .09))
        data[start + j] += gain * attack * value


def finish_foley(name, data):
    """Finishes a generated finish-line take (already excerpted to the cue's
    length) with the layers the take lacked."""
    count = len(data)
    if name == 'finish_snap':
        # The take's snap peaks at 13 ms; its long ribbon ring is let go from
        # .20 to .50 s, under a springier twang, two poppers 50 ms apart (the
        # gate's post-top cannons, the first 27 ms after the snap) and the
        # confetti showering down and thinning out. A high-pass at 180 Hz
        # first takes out the take's rumble, which the soft knee would raise.
        low = 0.0
        alpha = 1 - math.exp(-2 * math.pi * 180 / RATE)
        for i in range(count):
            low += alpha * (data[i] - low)
            data[i] -= low
            t = i / RATE
            if t > .20:
                data[i] *= .5 + .5 * math.cos(math.pi * min(1.0, (t - .20) / .30))
        twang(data, .006, 398, .32, .10)
        popper(data, .040, .55, 1500, 501)
        popper(data, .090, .46, 1250, 503)
        confetti = [0.0] * count
        crinkle(confetti, 505, .09, .70, 90, .20, lo=1800, hi=6000)
        band_noise(confetti, 507, .08, .72, .10, 3500, q=1.0, attack=.03, release=.5)
        for i in range(count):
            data[i] += confetti[i] * math.exp(-max(0.0, i / RATE - .10) / .30)
    if name == 'finish_cheer':
        # The take's flock chirps in waves with gaps at .10-.38 and .68-.86 s:
        # one bird whistles a 'wheet-whoo' into each, a different pitch each
        # time. The cheer is full for its first .90 s, then dies away over
        # the rest (6 dB down at 1.60 s, where the bird lands on its cloud),
        # so it is gone before the result card's star chimes.
        tweet(data, .11, .12, 1900, 2800, .30)
        tweet(data, .26, .15, 2600, 1700, .28)
        tweet(data, .70, .11, 2300, 3300, .25)
        tweet(data, .85, .14, 3100, 2100, .22)
        for i in range(count):
            t = i / RATE
            if t > .90:
                data[i] *= .5 + .5 * math.cos(math.pi * min(1.0, (t - .90) / (count / RATE - .90)))


# ---------------------------------------------------------------------------
# Egypt (rules version 50): Neferhoo, the Mummy Courier. 13 cues, seeds
# 501-619 (New York used up to 499; the cue's hundreds digit is its order in
# EGYPT_CUES: roar 501-507, devil 511-515, mail call 521-523, flick 531-533,
# return 541-543, postage due 551-555, scuff 561, raise 571, whir 581-583,
# catch 591, fury 601-605, mask pop 611-619). Designed by
# egypt-ws/reports/01-egypt-guardian.md section 6 and prototyped offline by
# proof/mummy_cues_prototype.py; the cues are that prototype's, except that
# hoopoe_roar's three notes follow the picture's beak pulses (see ROAR_NOTES).
EGYPT_CUES = [
    'hoopoe_roar', 'sand_devil', 'mail_call', 'letter_flick', 'letter_return',
    'postage_due', 'wrap_scuff', 'ankh_raise', 'ankh_whir', 'ankh_catch',
    'mummy_fury', 'mask_pop', 'lost_letter',
]

# The arrival roar's HOO-POO-POO: the picture pulses his beak at 2.65, 2.80
# and 2.95 s of the arrival for .15 s each (the roar cue starts at 2.65 s), so
# the three hoots start .02 s after each pulse opens: (start, length, hz_from,
# hz_to) in seconds from the cue's start. The prototype's notes were .34 s
# apart (.05, .39, .73), twice as slow as the beak.
ROAR_NOTES = [(.02, .17, 330, 300), (.17, .17, 300, 270), (.32, .32, 300, 240)]


def hoot(data, at, length, hz_from, hz_to, gain, seed):
    """One giant hoopoe 'hoo': the pigeon voice with a rounder, lower roll."""
    coo_voice(data, at, length, hz_from, hz_to, gain, vibrato=4.5, roll=11.0,
              seed=seed, bright=1.1)


def gong(data, at, hz, length, gain):
    """A small temple gong: five inharmonic partials with their own decays and
    a slow bloom (about 20 ms) to the strike."""
    start = int(at * RATE)
    parts = [(1.0, 1.0), (1.47, .55), (2.09, .38), (2.56, .22), (3.42, .15)]
    for j in range(min(int(length * RATE), len(data) - start)):
        t = j / RATE
        env = (1 - math.exp(-t / .02)) * math.exp(-t / (length * .32))
        v = sum(a * math.sin(2 * math.pi * hz * r * t + r) * math.exp(-t * r * 1.3)
                for r, a in parts)
        data[start + j] += gain * env * v / 2.3


def whir(data, seed, start, seconds, rate_from, rate_to, hz, gain):
    """A thrown boomerang: noise band-passed around [hz], chopped at a spin
    rate (turns a second) gliding from [rate_from] to [rate_to]."""
    first = int(start * RATE)
    rng = random.Random(seed)
    lo = hi = 0.0
    a_lo = 1 - math.exp(-2 * math.pi * hz * 1.6 / RATE)
    a_hi = 1 - math.exp(-2 * math.pi * hz * .6 / RATE)
    phase = 0.0
    for j in range(min(int(seconds * RATE), len(data) - first)):
        t = j / RATE
        u = t / seconds
        n = rng.uniform(-1, 1)
        lo += a_lo * (n - lo)
        hi += a_hi * (lo - hi)
        band = lo - hi
        phase += 2 * math.pi * (rate_from + (rate_to - rate_from) * u) / RATE
        chop = .25 + .75 * max(0.0, math.sin(phase)) ** 2
        env = min(1, t / .08) * min(1, (seconds - t) / .2)
        data[first + j] += gain * env * chop * band * 3


def synth(name, seconds, variant):
    if name in MENU_NOTES:
        return menu_chime(name, seconds)
    data = [0.0] * int(RATE * seconds)
    if name == 'sprint':
        rush(data)
        impact(data, .10, .22)
        return data
    if name == 'sprint_ring':
        # A bright double ping; each chained ring climbs a whole tone.
        lift = 2 ** (2 * variant / 12)
        for i, hz in enumerate([1318.51, 1975.53, 2637.02]):
            bell(data, hz * lift, i * .045, seconds - i * .045, .20 - .04 * i)
        whoosh(data, seconds * .8, .07, seed=31 + variant)
        return data
    if name == 'rubble_smash':
        impact(data, .30, .62, seed=40 + variant, heavy=True)
        whoosh(data, seconds * .6, .16, descending=True, seed=44 + variant)
        crumble(data, 47 + variant)
        return data
    if name == 'lava_burst':
        # A deep whump, then hissing spray and spatter falling back.
        impact(data, .34, .58, seed=70 + variant, heavy=True)
        rng = random.Random(73 + variant)
        low = 0.0
        for i in range(len(data)):
            t = i / RATE
            noise = rng.uniform(-1, 1)
            low += .55 * (noise - low)
            env = min(1, t / .04) * math.exp(-t / (seconds * .35))
            data[i] += .22 * env * (noise - low)
        crumble(data, 77 + variant, grains=7)
        return data
    if name == 'rush_alarm':
        # Three urgent hi-lo stabs over a rising rumble: danger behind.
        for i in range(3):
            bell(data, 880, i * .30, .26, .24)
            bell(data, 659.25, i * .30 + .13, .26, .22)
        whoosh(data, seconds, .14, seed=53)
        impact(data, .18, .30, seed=55, heavy=True)
        return data
    if name == 'gust_warning':
        # A quick whistle climbing over a gust of air: something is coming.
        phase = 0.0
        for i in range(len(data)):
            t = i / RATE
            hz = 1046.5 * 2 ** (min(1, t / (seconds * .55)) * 7 / 12)
            phase += 2 * math.pi * hz / RATE
            env = min(1, t / .015) * math.exp(-t / (seconds * .3))
            data[i] += .20 * env * (math.sin(phase) + .25 * math.sin(2 * phase))
        whoosh(data, seconds, .22, descending=True, seed=83)
        return data
    if name == 'cannon_fuse':
        # A lit fuse: fizzing sparks that crackle faster as it burns down.
        rng = random.Random(91)
        low = lower = 0.0
        for i in range(len(data)):
            t = i / RATE
            u = t / seconds
            # Band-limited so it sizzles rather than hisses like static.
            low += .5 * (rng.uniform(-1, 1) - low)
            lower += .12 * (low - lower)
            hiss = low - lower
            env = min(1, t / .03) * (.55 + .45 * u)
            data[i] += .16 * env * hiss
        for k in range(26):
            at = (k / 26) ** .8 * (seconds - .03) + rng.uniform(0, .012)
            start = int(at * RATE)
            for j in range(min(int(.006 * RATE), len(data) - start)):
                tt = j / RATE
                data[start + j] += .32 * rng.uniform(-1, 1) * math.exp(-tt / .0012)
        return data
    if name == 'cannon_fire':
        boom(data, 101 + variant, hz=58 - 6 * variant)
        # The deck and carriage take the recoil: a short wooden knock.
        bell(data, 196 - 12 * variant, .035, .22, .10, warm=True)
        impact(data, .16, .20, seed=107 + variant, heavy=True)
        return data
    if name == 'tide_warning':
        # Two strikes of the ship's bell over water swelling from below.
        sea_noise(data, 111, 0, seconds, .5, .02, .09, attack=.6, release=.3)
        phase = 0.0
        for i in range(len(data)):
            t = i / RATE
            phase += 2 * math.pi * (46 + 10 * t / seconds) / RATE
            env = min(1, t / .5) * min(1, (seconds - t) / .25)
            data[i] += .26 * env * math.sin(phase)
        ship_bell(data, 0, .24)
        ship_bell(data, .34, .20)
        return data
    if name == 'tide_surge':
        # The sea heaves up: a deep roar that brightens into foaming spray.
        sea_noise(data, 121, 0, seconds, .75, .03, .30, attack=.12, release=.4)
        sea_noise(data, 123, .18, seconds - .18, .35, .25, .55, attack=.3, release=.3)
        phase = 0.0
        for i in range(len(data)):
            t = i / RATE
            phase += 2 * math.pi * (38 + 34 * min(1, t / .6)) / RATE
            data[i] += .34 * math.sin(phase) * min(1, t / .08) * math.exp(-t * 1.6)
        return data
    if name == 'sea_splash':
        # A heavy plunge: the cavity's falling bloop, then spray and drips.
        phase = 0.0
        for i in range(len(data)):
            t = i / RATE
            phase += 2 * math.pi * (95 + (260 + 40 * variant) * math.exp(-t * 16)) / RATE
            data[i] += .55 * math.sin(phase) * min(1, t / .004) * math.exp(-t * 11)
        sea_noise(data, 131 + variant, 0, seconds * .8, .9, .55, .25, attack=.006, release=.3)
        rng = random.Random(137 + variant)
        for k in range(7):
            at = .12 + rng.random() * (seconds - .2)
            hz = 900 + rng.random() * 900
            start = int(at * RATE)
            for j in range(min(int(.05 * RATE), len(data) - start)):
                tt = j / RATE
                data[start + j] += .07 * math.sin(2 * math.pi * hz * (1 + 2.5 * tt) * tt) * math.exp(-tt * 70)
        return data
    if name == 'dragon_inhale':
        # A vast breath drawn in: air rushing into the jaws, brightening as
        # the lungs fill, over a growl that climbs, and embers starting to
        # crackle in the throat before the flame.
        rng = random.Random(151)
        low = band = 0.0
        for i in range(len(data)):
            t = i / RATE
            u = t / seconds
            bright = .015 + .09 * u * u
            low += bright * (rng.uniform(-1, 1) - low)
            band += bright * .7 * (low - band)
            env = (u ** 1.6) * min(1, (seconds - t) / .06)
            data[i] += .95 * env * (band + .5 * (low - band))
        growl(data, .05, seconds - .05, 42, 74, .16, 153, swell=.75)
        crackle(data, 157, seconds * .45, seconds * .5, 26, .20)
        return data
    if name == 'dragon_breath':
        # The flame: a heavy ignition whump, then a roaring jet that holds
        # and gutters out, with embers snapping all through it.
        impact(data, .30, .70, seed=161, heavy=True)
        flame(data, 163, 0, seconds, .55, attack=.04, release=.45)
        flame(data, 165, .02, seconds * .7, .22, attack=.08, release=.3,
              flicker=17.0)
        growl(data, 0, seconds * .55, 70, 48, .10, 167)
        crackle(data, 169, .1, seconds - .3, 40, .18)
        return data
    if name == 'ember_split':
        # A fireball bursting: a sharp pop, three embers hissing away.
        impact(data, .12, .55, seed=171)
        for k in range(3):
            flame(data, 173 + k, .02 + k * .025, seconds * .6, .12,
                  attack=.01, release=.2, flicker=23.0 + 4 * k)
        crackle(data, 179, .02, seconds * .6, 14, .22)
        return data
    if name == 'screech_warning':
        # Echolocation: short falling chirps that quicken and climb as the
        # Baron's ears flare, over a thin whistle drawing tight.
        at, gap, k = 0.0, .30, 0
        while at < seconds - .06:
            u = at / seconds
            chirp(data, at, .028, 1900 + 1500 * u, 1150 + 900 * u,
                  .20 + .22 * u)
            at += gap
            gap = max(.055, gap * .80)
            k += 1
        whistle(data, 181, .1, seconds - .1, 2300, 3300, .07, swell=.9)
        return data
    if name == 'sonic_screech':
        # The screech: a shrill, wavering shriek that tears out of the jaws
        # and sweeps away, over a rush of air and a soft thump of pressure.
        impact(data, .18, .35, seed=185, heavy=True)
        whistle(data, 187, 0, seconds, 2600, 1500, .30, tremor=31.0)
        whistle(data, 189, .01, seconds * .85, 1750, 1050, .16, tremor=23.0)
        whoosh(data, seconds, .20, descending=True, seed=191)
        return data
    # ---- Alley Pigeon (reports/02-alley-pigeon.md §4) ---------------------
    if name == 'pigeon_coo':
        # "coo-ROO-oo": a short rise, a fuller hold, a falling tail. The second
        # take is a whole tone higher, so a flock coos in a rolling chorus.
        lift = 2 ** (2 * variant / 12)
        coo_voice(data, 0, .13, 360 * lift, 430 * lift, .22, roll=26, seed=251 + variant)
        coo_voice(data, .15, .21, 430 * lift, 400 * lift, .30, roll=26, seed=253 + variant)
        coo_voice(data, .38, .17, 400 * lift, 290 * lift, .24, roll=26, seed=255 + variant)
        return data
    if name == 'pigeon_flap':
        # Four dry wing claps, fading, over a low thump and a thin whoosh.
        for i, (at, gain) in enumerate([(0, 1), (.075, .85), (.145, .7), (.21, .5)]):
            clap(data, at + .004 * variant, gain * .55, 261 + 4 * i + variant)
        whoosh(data, seconds * .9, .10, seed=269 + variant)
        return data
    if name == 'pigeon_snatch':
        # A clap and a beak tick, then the star's chime played backwards (E6
        # falling to B5: the sound of a loss) over a falling whistle.
        clap(data, 0, .55, 273)
        tick(data, .022, 3400, .30)
        bell(data, 1318.51, .05, seconds - .05, .20)
        bell(data, 987.77, .14, seconds - .14, .18)
        whistle(data, 277, .04, .22, 1900, 950, .05)
        return data
    if name == 'pigeon_defeat':
        # Two falling squeaks, a puff of feathers, a light thump and a tiny
        # falling coo.
        lift = 2 ** (2 * variant / 12)
        chirp(data, 0, .09, 1700 * lift, 620 * lift, .30)
        chirp(data, .10, .07, 1300 * lift, 520 * lift, .18)
        puff(data, 281 + variant, .03, .20, .22)
        impact(data, .14, .22, seed=283 + variant)
        coo_voice(data, .22, .22, 330 * lift, 240 * lift, .16, roll=26, seed=285 + variant)
        return data
    if name == 'star_rescue':
        # A star freed: three bright rising bells over a small lift of air.
        for i, hz in enumerate([1567.98, 2093.0, 2637.02]):
            bell(data, hz, i * .06, seconds - i * .06, .18 - .03 * i)
        whoosh(data, seconds * .6, .07, seed=291)
        tick(data, .02, 4200, .12)
        return data
    # ---- Steam Geysers (reports/03-steam-geysers.md §4) -------------------
    if name == 'steam_hiss':
        # Pressure building in an old pipe: a thin, bright hiss that swells and
        # spits faster, with iron knocks ticking ever quicker under it.
        steam_noise(data, 201, 0, seconds, 1.15, .22, .40, hp=.10, attack=.25,
                    release=.05, spit=6.0, spit_to=15.0)
        for k, at in enumerate([.06, .50, .86, 1.12, 1.29, 1.40]):
            clang(data, at, 232 + 14 * k, .22 + .06 * k, seed=210 + k)
        for i in range(len(data)):
            t = i / RATE
            data[i] *= (t / seconds) ** .7 * .8 + .2
        return data
    if name == 'steam_burst':
        # A valve letting go: a crack and chest thump, a bright roaring jet
        # that darkens as it spreads, and a fading hiss, over an iron clang.
        impact(data, .16, .55, seed=221 + variant, heavy=True)
        steam_noise(data, 223 + variant, 0, seconds, 1.55, .48, .09, hp=.10,
                    attack=.006, release=.45)
        steam_noise(data, 227 + variant, .03, seconds * .55, .55, .38, .20,
                    hp=.04, attack=.01, release=.25, spit=23.0, spit_to=9.0)
        clang(data, .012, 301 * (1 + .07 * variant), .22, seed=229 + variant)
        return data
    if name == 'pipe_clang':
        # The grate's lid bangs up and settles: a ringing strike and a softer,
        # lower clunk right behind it.
        clang(data, 0, 392 * (1 + .09 * variant), .55, seed=231 + variant)
        clang(data, .11, 329 * (1 + .09 * variant), .32, seed=233 + variant)
        impact(data, .08, .18, seed=235 + variant)
        return data
    if name == 'steam_ride':
        # An updraft catches the bird: a soft rising whoosh of air with a warm
        # two-note sparkle (E5 then B5) on top.
        updraft(data, 241, seconds, 3.4, 420, 2600)
        whoosh(data, seconds * .8, .05, seed=243)
        bell(data, 659.25, .05, seconds - .05, .60, warm=True)
        bell(data, 987.77, .15, seconds - .15, .95, warm=True)
        return data
    # ---- Searchlight Gargoyle (reports/04-gargoyle.md §4) -----------------
    if name == 'gargoyle_strike':
        # Lightning hits the tower's rod: a tearing crack (a burst of 2.4 kHz
        # noise a phone can play) over a chest thump, a spray of arcing snaps,
        # the rod ringing, and thunder rolling away.
        boom(data, 401, gain=.75, hz=70)
        band_noise(data, 407, 0, .28, 1.4, 2400, q=.9, attack=.001, release=.27)
        crackle(data, 403, 0, seconds * .6, 30, .30)
        clang(data, .004, 1046.5, .10, seed=405)
        return data
    if name == 'gargoyle_awaken':
        # The stone wakes: a groan from the ledge and stone grinding in slow,
        # irregular slips (both peak at once and die away over the cue),
        # twelve chunks of limestone falling away, and the steel lenses ringing
        # as they blaze (three inharmonic partials of one bell).
        layer = [0.0] * len(data)
        growl(layer, 0, seconds, 38, 55, .30, 411, swell=.3)
        stone_grind(layer, 413, 0, seconds - .2, .30, rate=4.3)
        for i, v in enumerate(layer):
            t = i / RATE
            data[i] += v * min(1, t / .12) * (1 if t < .7 else math.exp(-(t - .7) * 1.9))
        crumble(data, 415, grains=12)
        for i, (hz, gain) in enumerate([(466.16, .15), (1286.6, .10), (2517.2, .06)]):
            bell(data, hz, .30 + .05 * i, seconds - .30 - .05 * i, gain)
        return data
    if name == 'beam_warning':
        # The shutter slams and the lamp winds up: a hum climbing 120 to 360 Hz
        # under arcing crackle, relay ticks quickening into the ignition.
        impact(data, .12, .40, seed=421)
        whistle(data, 423, .02, seconds - .02, 120, 360, .22, tremor=6.0, swell=.9)
        arc_buzz(data, 424, .02, seconds - .02, 120, 360, seconds, .05, tremor=9.0,
                 release=.05, swell=.85)
        crackle(data, 425, .10, seconds - .15, 34, .12)
        at, gap = .20, .26
        while at < seconds - .06:
            u = at / seconds
            chirp(data, at, .022, 1500 + 900 * u, 1000 + 500 * u, .16 + .14 * u)
            at += gap
            gap = max(.05, gap * .82)
        return data
    if name == 'beam_sweep':
        # The beam burns: an arc-lamp buzz (a 100 Hz saw) that glides up as the
        # beam travels for 1.8 s and then holds, its level fluttering at 7 Hz,
        # under a soft whoosh of ignition.
        arc_buzz(data, 431, 0, seconds, 100, 128, 1.8, .12, tremor=7.0)
        crackle(data, 435, .3, seconds - .6, 22, .05)
        whoosh(data, .7, .10, seed=433)
        return data
    if name == 'beam_spot':
        # Caught: a pop and a bright G6 bell ("Spotted!").
        impact(data, .12, .30, seed=441)
        bell(data, 1567.98, 0, seconds, .40)
        return data
    if name == 'lamp_vent':
        # The shutters fold open: eleven ratchet ticks falling 900 to 500 Hz,
        # steam hissing out brighter and brighter, and a low sigh.
        for k in range(11):
            chirp(data, .02 + k * .028, .016, 900 - 36 * k, 820 - 32 * k - 20, .30)
        sea_noise(data, 453, .10, seconds - .2, .40, .03, .28, attack=.35, release=.5)
        whistle(data, 455, .25, seconds - .4, 240, 130, .05)
        return data
    if name == 'lamp_glance':
        # A rock clinks off the shuttered lamp: steel partials and a dry tick.
        lift = 1 + .09 * variant
        bell(data, 1320 * lift, 0, seconds, .28)
        bell(data, 1980 * lift, .012, seconds - .012, .10)
        impact(data, .05, .25, seed=461 + variant)
        return data
    if name == 'feather_drop':
        # A stone feather leaves the cornice: a rustle of 3 kHz air and a tick
        # of stone, then it falls away on a thin whoosh.
        band_noise(data, 471 + variant, 0, seconds * .7, .9, 3000 * (1 + .1 * variant),
                   q=1.6, attack=.03, release=.25)
        tick(data, .004, 950 * (1 + .12 * variant), .35)
        whoosh(data, seconds, .05, descending=True, seed=473 + variant)
        return data
    # ---- King Coo (reports/05-king-coo.md §4) -----------------------------
    if name == 'coo_roar':
        # COO-ROO-COOOO: a giant pigeon's chest voice in three glides (with
        # upper harmonics so a phone speaker has something to play), under a
        # chest thump and a rough growl.
        impact(data, .22, .42, seed=301, heavy=True)
        coo_voice(data, .06, .36, 150, 196, .32, seed=303, bright=1.0)
        coo_voice(data, .46, .34, 198, 168, .30, seed=305, bright=1.0)
        coo_voice(data, .86, .70, 168, 104, .34, vibrato=5.0, seed=307, bright=1.0)
        growl(data, .06, seconds - .3, 52, 66, .07, 309, swell=.3)
        return data
    if name == 'coo_whistle':
        # tweet-tweeeet: a short blast, then the long trilled one from 0.12 s,
        # so it sounds while the blast pose (0.4 s from the whistle) is on.
        pea_whistle(data, 0.0, .11, hz=2900, trill=26, seed=311)
        pea_whistle(data, .12, seconds - .19, hz=3000, trill=30, seed=313)
        return data
    if name == 'crumb_throw':
        # An underhand toss from the sack: a cloth swish (1.7 kHz, not a bass
        # whoosh), a dry thwup as it leaves the wing, and crumbs scattering.
        band_noise(data, 321, 0, .26, .9, 1700, q=1.0, attack=.09, release=.15)
        impact(data, .08, .22, seed=323)
        crinkle(data, 326, .11, .23, 8, .30, lo=1100, hi=3000)
        return data
    if name == 'crumb_splat':
        # pfft-splat: a soft pop and a wet slap of noise, then dry crumbs
        # pattering down (crinkle grains in the 1-3.5 kHz band).
        impact(data, .12, .30, seed=331)
        band_noise(data, 337, 0, .30, 1.0, 1400, q=.9, attack=.004, release=.25)
        crinkle(data, 338, .05, .50, 18, .28, lo=1000, hi=3500)
        return data
    if name == 'squad_flutter':
        # A beat of silence, then a flock takes off over a chorus of soft coos.
        wing_claps(data, .10, seconds - .15, 10, 26, .26, seed=341)
        for k, hz in enumerate((260, 300, 340)):
            coo_voice(data, .12 + .08 * k, .34, hz, hz * .8, .07, seed=343 + k)
        whoosh(data, seconds, .07, descending=True, seed=349)
        return data
    if name == 'coo_puff':
        # The chest inflates: rising air, a rubbery squeak and a tight creak.
        whoosh(data, seconds * .92, .24, seed=351)
        squeak(data, .10, seconds - .35, 240, 560, .15)
        impact(data, .09, .22, seed=353)
        bell(data, 740, seconds - .22, .20, .10, warm=True)
        return data
    if name == 'coo_pop':
        # POP! then a sad deflating squeal and a dizzy little coo.
        impact(data, .12, .62, seed=361)
        whoosh(data, .36, .22, descending=True, seed=363)
        squeak(data, .06, seconds - .30, 1150, 240, .22, tremor=9.0)
        crumble(data, 365, grains=6)
        coo_voice(data, seconds - .26, .22, 320, 250, .16, seed=367)
        return data
    if name == 'coo_defeat':
        # The burst: a soft heavy whump, a deflating pbbbt, two sad falling coos.
        impact(data, .30, .50, seed=371, heavy=True)
        whoosh(data, .5, .18, descending=True, seed=373)
        rng = random.Random(375)
        low = 0.0
        first = int(.06 * RATE)
        for i in range(int(.9 * RATE)):
            t = i / RATE
            u = t / .9
            flutter = .5 + .5 * math.sin(2 * math.pi * (13 - 9 * u) * t)
            noise = rng.uniform(-1, 1)
            low += (.10 + .18 * (1 - u)) * (noise - low)
            data[first + i] += .22 * (1 - u) * flutter * low
        coo_voice(data, .55, .42, 210, 150, .22, seed=377, bright=.9)
        coo_voice(data, 1.02, .55, 168, 92, .22, vibrato=4.5, seed=379, bright=.9)
        return data
    # ---- Audio fix round (reports/22-review-motion-audio.md) --------------
    if name == 'coo_shout':
        # The arrival COO!, cut to the beak: the pose opens his beak as a sine
        # pulse over 0.8 s (shut at 0, widest at 0.4 s, shut at 0.8 s), so one
        # shout (a short rise, then a long fall) rides that pulse and the thump
        # lands with the shock ring at 0 s. The fury keeps the 1.6 s coo_roar.
        layer = [0.0] * len(data)
        coo_voice(layer, .03, .36, 168, 205, .34, seed=381, bright=1.0)
        coo_voice(layer, .30, .46, 205, 112, .34, vibrato=5.0, seed=383, bright=1.0)
        growl(layer, .05, seconds - .12, 54, 62, .07, 385, swell=.2)
        for i, v in enumerate(layer):
            t = i / RATE
            data[i] += v * (math.sin(math.pi * t / .80) ** .6 if t < .80 else 0)
        impact(data, .22, .40, seed=387, heavy=True)
        return data
    if name == 'gargoyle_fury':
        # His own fury, in the mids a phone plays: a stone crack and thump, a
        # grinding roar and a searing arc surge (full by 0.1 s and held to 0.4 s, as the pose
        # throws its roar), and the steel lenses ringing as they go white-hot.
        impact(data, .22, .50, seed=481, heavy=True)
        band_noise(data, 483, 0, .35, 1.3, 2200, q=.9, attack=.002, release=.33)
        layer = [0.0] * len(data)
        stone_grind(layer, 485, .04, .9, .50, lo=300, hi=2000, rate=9.0)
        arc_buzz(layer, 487, .06, 1.0, 140, 230, .5, .14, tremor=11.0)
        for i, v in enumerate(layer):
            t = i / RATE
            data[i] += v * min(1, t / .06) * (1 if t < .40 else math.exp(-(t - .40) * 3.2))
        crackle(data, 489, .05, .6, 26, .22)
        for i, (hz, gain) in enumerate([(466.16, .22), (1286.6, .17), (2517.2, .11)]):
            bell(data, hz, .10 + .04 * i, seconds - .10 - .04 * i, gain)
        return data
    if name == 'gargoyle_shatter':
        # The burst that ends him: a stone crack and thump, the lamp glass
        # shattering (three short high partials and 44 snaps), limestone chips
        # and rubble falling, and nine pigeons breaking out of the dust.
        impact(data, .30, .55, seed=491, heavy=True)
        band_noise(data, 493, 0, .30, 1.3, 1800, q=.8, attack=.001, release=.29)
        crackle(data, 495, 0, .5, 44, .28)
        crinkle(data, 497, .05, .9, 26, .25, lo=1200, hi=4200)
        for i, hz in enumerate([3136.0, 4186.0, 5274.0]):
            bell(data, hz, .02 + .01 * i, .35, .10 - .02 * i)
        crumble(data, 499, grains=14)
        wing_claps(data, .45, .65, 10, 22, .14, seed=492)
        return data
    if name == 'coo_inflate':
        # His chest inflating under the hit-stop (death +0.12 s to the pop at
        # +0.85 s): rising air, a rubbery squeak climbing and tightening, and
        # creaks closing up as it nears bursting.
        updraft(data, 391, seconds, 1.6, 500, 2200)
        squeak(data, 0, seconds - .08, 300, 900, .20, tremor=16.0)
        squeak(data, .15, seconds - .25, 450, 1350, .10, tremor=22.0)
        for k, at in enumerate([.42, .54, .62, .68]):
            tick(data, at, 1800 + 150 * k, .16)
        return data
    if name == 'finish_near':
        # A harp glissando up the G major pentatonic (the dominant of the C
        # major `complete` fanfare) to a high D, glockenspiel on its last
        # notes and a shimmering D6, over a shaker roll that swells and stops
        # short: open, expectant, resolved by the crossing.
        gliss = [392.0, 440.0, 493.88, 587.33, 659.25, 783.99, 880.0, 987.77, 1174.66]
        at = 0.0
        for i, hz in enumerate(gliss):
            pluck(data, at, hz, .10 + .008 * i)
            at += .075 - .0025 * i
        for at, hz, gain in [(.38, 783.99, .07), (.45, 987.77, .08), (.52, 1174.66, .10),
                             (.70, 1174.66, .06), (.86, 1174.66, .04)]:
            bell(data, hz, at, seconds - at, gain)
        shaker(data, 521, .10, 1.10, .16, 14, 22)
        return data
    if name == 'finish_swoop':
        # Air rushing closer for half a second, then the bird lands in the
        # cloud with a cushioned fwump at .55 s and a puff of cloud settling.
        swoop_air(data, 531, .52, seconds, .30, 380, 2200)
        fwump(data, .55, .55, 533)
        puff(data, 535, .57, .16, .06)
        return data
    # ---- Egypt: Neferhoo, the Mummy Courier (rules version 50) -------------
    if name == 'hoopoe_roar':
        # The arrival roar, HOO-POO-POO: a giant hoopoe's three-note call,
        # bright enough for a phone, a thump and a small temple gong under it
        # and a puff of sand after. The notes ride the picture's beak pulses.
        impact(data, .2, .35, seed=501, heavy=True)
        for k, (at, length, hz_from, hz_to) in enumerate(ROAR_NOTES):
            hoot(data, at, length, hz_from, hz_to, .34, 503 + k)
        gong(data, .0, 196, 1.3, .16)
        whoosh(data, 1.2, .07, descending=True, seed=507)
        return data
    if name == 'sand_devil':
        # The arrival: a sand devil spins up out of the dunes, letters
        # rattling in it (the picture's devil swells from .4 to 1.6 s).
        updraft(data, 511, 1.5, .5, 300, 1400)
        crackle(data, 513, .1, 1.4, 40, .12)
        crinkle(data, 515, .3, 1.2, 16, .22, lo=1200, hi=3400)
        return data
    if name == 'mail_call':
        # The mail lock: the satchel flap thumps open, papyrus rustles up and
        # three rising chimes (it rings out as the first letter leaves).
        impact(data, .1, .3, seed=521)
        crinkle(data, 523, .08, .7, 22, .3, lo=1300, hi=3600)
        for k, hz in enumerate((659.25, 830.61, 987.77)):
            bell(data, hz, .25 + k * .14, .5, .1, warm=True)
        return data
    if name == 'letter_flick':
        # One letter flicked off his wingtip: a paper snap and a short swish.
        band_noise(data, 531, 0, .12, 1.0, 2600, q=1.4, attack=.003, release=.08)
        band_noise(data, 533, .03, .2, .45, 1500, q=.8, attack=.04, release=.12)
        return data
    if name == 'letter_return':
        # A rock meets a letter: a rubber-stamp thunk, a paper tick and a
        # rising boing as it turns for home.
        impact(data, .12, .45, seed=541)
        band_noise(data, 543, 0, .1, .6, 2200, q=1.2, attack=.002, release=.07)
        chirp(data, .08, .28, 420, 980, .22)
        return data
    if name == 'postage_due':
        # The returned letter lands: KA-CHUNK, a burst of paper and the post
        # office counter bell. The payoff, the loudest hit of his fight.
        impact(data, .16, .45, seed=551, heavy=True)
        impact(data, .08, .4, seed=553)
        band_noise(data, 554, 0, .09, .7, 1100, q=1.1, attack=.002, release=.06)
        crinkle(data, 555, .04, .45, 24, .4, lo=1200, hi=3800)
        bell(data, 1567.98, .12, .55, .34)
        bell(data, 2093.0, .2, .45, .16)
        return data
    if name == 'wrap_scuff':
        # A rock on his wrappings: a soft, dull cloth thud. Deliberately small.
        band_noise(data, 561, 0, .14, .8, 700, q=.9, attack=.003, release=.1)
        return data
    if name == 'ankh_raise':
        # The ankh rises on his magic: a swelling hum and four climbing chimes
        # (1.4 s, as long as the lock-to-throw wait).
        whistle(data, 571, 0, 1.35, 220, 330, .14, tremor=6, swell=.8)
        for k, hz in enumerate((523.25, 659.25, 783.99, 1046.5)):
            bell(data, hz, .3 + k * .22, .5, .1, warm=True)
        return data
    if name == 'ankh_whir':
        # In flight: whup-whup-whup, slowing at the turn, quickening home.
        whir(data, 581, 0, 1.2, 9, 6, 900, .5)
        whir(data, 583, 1.1, 1.5, 6, 10, 980, .5)
        return data
    if name == 'ankh_catch':
        # Back in his wing: a bright gold clink.
        impact(data, .06, .25, seed=591)
        bell(data, 1318.51, 0, .32, .26)
        bell(data, 1975.53, .01, .25, .1)
        return data
    if name == 'mummy_fury':
        # Fury: linen tears, a higher, angrier two-note call, the gong again.
        band_noise(data, 601, 0, .5, .9, 1800, q=.7, attack=.01, release=.3)
        for k, (hz_from, hz_to) in enumerate([(380, 360), (380, 330)]):
            hoot(data, .3 + k * .3, .28, hz_from, hz_to, .3, 603 + k)
        gong(data, .25, 233, 1.0, .14)
        return data
    if name == 'mask_pop':
        # The defeat burst: a gold clang-pop, bandages unravelling, a blizzard
        # of paper and a relieved little hoot.
        clang(data, 0, 880, .32, seed=611)
        impact(data, .14, .45, seed=613)
        wing_claps(data, .1, .7, 30, 12, .16, seed=615)
        crinkle(data, 617, .1, 1.0, 34, .26, lo=1100, hi=3600)
        hoot(data, .9, .32, 300, 250, .22, 619)
        return data
    if name == 'lost_letter':
        # Victory: the lost letter glows. A warm four-note "found it".
        for k, hz in enumerate((523.25, 659.25, 783.99, 1046.5)):
            bell(data, hz, k * .16, .9, .16, warm=True)
        return data
    if name == 'rush_clear':
        run = [523.25, 659.25, 783.99, 1046.5, 1318.51, 1567.98]
        for i, hz in enumerate(run):
            bell(data, hz, i * .055, seconds - i * .055, .18)
        for hz in [523.25, 659.25, 783.99]:
            bell(data, hz, .36, seconds - .36, .12, warm=True)
        whoosh(data, seconds * .7, .10, descending=True, seed=61)
        return data
    notes = NOTES.get(name)
    if notes:
        step = min(.13, seconds * .55 / max(len(notes), 1))
        for i, hz in enumerate(notes):
            bell(data, hz * (1 + .025 * variant), i * step,
                 seconds - i * step, warm=name.startswith('ui_') or name in ['ready', 'letter', 'ammo_empty'])
        if name in ['magnet', 'shield', 'heart', 'boss_shield', 'unlock']:
            whoosh(data, seconds, .09)
        if name in ['shield_pop', 'boss_block', 'boss_hit', 'deflect', 'ammo_empty']:
            impact(data, min(.16, seconds), .25)
        if name in ['complete', 'boss_victory', 'record', 'unlock']:
            for hz in [261.63, 329.63, 392]:
                bell(data, hz, seconds * .4, seconds * .6, .10, warm=True)
    else:
        whoosh(data, seconds, .30, descending=name in ['boss_break', 'bump', 'rock_hit'])
        impact(data, min(seconds, .4), .60, heavy=name.startswith('boss_'))
        if name in ['enemy_charge', 'boss_summon']:
            bell(data, 220, 0, seconds, .16)
        if name == 'boss_break':
            for i, hz in enumerate([220, 207.65, 196]):
                bell(data, hz, i * .16, .35, .24, warm=True)
    return data


def projectile_snap(data):
    """An immediate midrange crack and compact falling body, audible on phones."""
    rng = random.Random(72)
    phase = 0.0
    low = 0.0
    for i in range(len(data)):
        t = i / RATE
        phase += 2 * math.pi * (320 + 1100 * math.exp(-t / .018)) / RATE
        noise = rng.uniform(-1, 1)
        low += .24 * (noise - low)
        attack = min(1, t / .001)
        body = .25 * math.sin(phase) * math.exp(-t / .048)
        crack = .13 * (noise - low) * math.exp(-t / .012)
        data[i] += attack * (body + crack)


def deepen(samples, ratio, count):
    """Slower playback lowers a take's pitch while keeping its gesture."""
    result = []
    for i in range(count):
        position = i * ratio
        j = int(position)
        if j + 1 >= len(samples):
            result.append(0.0)
            continue
        result.append(samples[j] + (samples[j + 1] - samples[j]) * (position - j))
    return result


def power_launch(data):
    """A deeper crack and a falling body in the phone-audible midrange."""
    rng = random.Random(84)
    phase = 0.0
    low = 0.0
    seconds = len(data) / RATE
    for i in range(len(data)):
        t = i / RATE
        phase += 2 * math.pi * (190 + 900 * math.exp(-t / .035)) / RATE
        noise = rng.uniform(-1, 1)
        low += .18 * (noise - low)
        attack = min(1, t / .0015)
        body = .30 * math.sin(phase) * math.exp(-t / .09)
        crack = .12 * (noise - low) * math.exp(-t / .02)
        rush = .10 * low * math.sin(math.pi * t / seconds)
        data[i] += attack * (body + crack) + rush


def phone_presence(data):
    """Bring a boss's midrange forward instead of relying on sub-bass energy."""
    lo = hi = 0.0
    low_alpha = 1 - math.exp(-2 * math.pi * 350 / RATE)
    high_alpha = 1 - math.exp(-2 * math.pi * 2400 / RATE)
    result = []
    for value in data:
        lo += low_alpha * (value - lo)
        hi += high_alpha * (value - hi)
        result.append(value + 1.2 * (hi - lo))
    return result


def master(data, target_peak=.70, rms_db=None, dc_block=False):
    # DC removal, short click-free boundaries, then constant gain (no pumping).
    mean = sum(data) / max(1, len(data))
    data = [v - mean for v in data]
    fade_in, fade_out = int(.002 * RATE), min(int(.035 * RATE), len(data)//5)
    for i in range(fade_in):
        data[i] *= i / fade_in
    for i in range(fade_out):
        data[-1-i] *= i / fade_out
    if rms_db is not None:
        # A soft knee controls isolated peaks that made the old Foley sound
        # quiet despite peak normalization. Fit perceived body, retain headroom.
        peak = max(.001, max(abs(v) for v in data))
        normalized = [v / peak for v in data]
        target_rms = 10 ** (rms_db / 20)
        drive = 1.0
        for _ in range(18):
            shaped = [math.tanh(v * drive) / math.tanh(drive) for v in normalized]
            rms = target_peak * math.sqrt(sum(v*v for v in shaped) / len(shaped))
            if rms >= target_rms or drive >= 8:
                data = shaped
                break
            drive *= 1.16
    if dc_block:
        # The fades and the soft knee leave a little offset: take it out again
        # and fade the edges once more so the ends still start and stop at 0.
        mean = sum(data) / len(data)
        data = [v - mean for v in data]
        for i in range(fade_in):
            data[i] *= i / fade_in
        for i in range(fade_out):
            data[-1-i] *= i / fade_out
    gain = target_peak / max(.001, max(abs(v) for v in data))
    return [v * gain for v in data]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--sources', type=Path, default=ROOT / 'build/sound-effects/source')
    parser.add_argument('--only', nargs='+', metavar='NAME',
                        help='render just these cues and leave the report alone')
    args = parser.parse_args()
    bank = (ROOT / 'lib/game/sound_bank.dart').read_text()
    records = []
    for match in re.finditer(r"'([a-z_]+)': SoundSpec\((.*?)\)", bank, re.S):
        name, fields = match.groups()
        if name == 'game_over':
            continue  # Built by tool/prepare_game_over.py from voice and piano takes.
        if re.search(r"file: '", fields):
            continue  # Another cue's WAV at another level (see SoundSpec.file).
        if args.only and name not in args.only:
            continue
        seconds_match = re.search(r'seconds: ([.\d]+)', fields)
        variants_match = re.search(r'variants: (\d+)', fields)
        seconds = float(seconds_match[1]) if seconds_match else .65
        variants = int(variants_match[1]) if variants_match else 1
        for variant in range(variants):
            stem = name + (f'_{variant+1}' if variant else '')
            source = args.sources / f'{stem}.mp3'
            if name in ['shoot', 'power_shot']:
                source = args.sources / 'shoot_punch.mp3'
            if name == 'boss_enrage':
                source = args.sources / 'boss_roar.mp3'
            if name == 'finish_snap':
                source = args.sources / 'finish_snap_tape.mp3'
            if source.exists():
                # A charged rock reuses the shot take a fourth slower and lower.
                ratio = .75 if name == 'power_shot' else 1
                data = excerpt(decode(source), seconds * ratio,
                               stretch=name in ['boss_warning', 'boss_roar', 'boss_enrage', 'boss_charge'],
                               transient=name in ['shoot', 'power_shot', 'flap', 'enemy_death', 'boss_volley', 'boss_burst'],
                               attack_lead=.006 if name in ['shoot', 'power_shot'] else .07)
                if name == 'shoot':
                    projectile_snap(data)
                if name == 'power_shot':
                    data = deepen(data, ratio, int(seconds * RATE))
                    power_launch(data)
                if name in ['enemy_death', 'boss_volley', 'boss_burst']:
                    impact(data, min(.20, seconds), .10, heavy=name == 'boss_burst')
                if name in FINISH_CUES:
                    finish_foley(name, data)
                origin = source.name
            else:
                if name in ['shoot', 'power_shot', 'enemy_death', 'flap', 'boss_warning', 'boss_roar', 'boss_enrage', 'boss_burst', 'boss_charge', 'boss_volley', 'finish_snap', 'finish_cheer']:
                    raise FileNotFoundError(f'Missing generated source: {source}')
                data = synth(name, seconds, variant)
                origin = 'original synthesis'
            targets = {'shoot': -15, 'power_shot': -15, 'boss_warning': -12, 'boss_reveal': -15, 'boss_roar': -14,
                       # New York's two cinematic roars and the strike, like boss_roar.
                       'coo_roar': -14, 'gargoyle_awaken': -14, 'gargoyle_strike': -16,
                       # The fix round's: the shout like the roar, the mids-heavy crumbs and fury raised.
                       'coo_shout': -14, 'gargoyle_fury': -14, 'gargoyle_shatter': -15,
                       'crumb_throw': -17, 'crumb_splat': -17,
                       # The tape's one sharp crack would set the level of the
                       # whole snap; a soft knee lets the poppers and confetti
                       # through.
                       'finish_snap': -19,
                       # Egypt's three loud payoffs (the roar, the jackpot, the mask).
                       'hoopoe_roar': -15, 'postage_due': -15, 'mask_pop': -15}
            if name in ['boss_warning', 'boss_reveal', 'boss_roar']:
                data = phone_presence(data)
            data = master(data, target_peak=.45 if name in MENU_NOTES else .70,
                          rms_db=targets.get(name),
                          dc_block=name in NEW_YORK_CUES or name in FINISH_CUES or name in EGYPT_CUES)
            pcm = array.array('h', (round(v * 32767) for v in data))
            if sys.byteorder != 'little':
                pcm.byteswap()
            target = ROOT / 'assets/audio' / f'{stem}.wav'
            with wave.open(str(target), 'wb') as output:
                output.setparams((1, 2, RATE, len(data), 'NONE', 'not compressed'))
                output.writeframes(pcm.tobytes())
            rms = math.sqrt(sum(v*v for v in data) / len(data))
            records.append(dict(asset=target.name, seconds=seconds, source=origin,
                                peak_db=round(20*math.log10(max(abs(v) for v in data)),2),
                                rms_db=round(20*math.log10(max(rms, 1e-9)),2),
                                sha256=hashlib.sha256(target.read_bytes()).hexdigest()))
    if args.only:
        print(f'Mastered {len(records)} effects: {", ".join(r["asset"] for r in records)}')
        return
    report = ROOT / 'build/sound-effects/verification.json'
    report.parent.mkdir(parents=True, exist_ok=True)
    report.write_text(json.dumps(records, indent=2) + '\n')
    print(f'Mastered {len(records)} effects; report: {report}')


if __name__ == '__main__':
    main()
