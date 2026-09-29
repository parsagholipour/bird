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


def master(data, target_peak=.70, rms_db=None):
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
                origin = source.name
            else:
                if name in ['shoot', 'power_shot', 'enemy_death', 'flap', 'boss_warning', 'boss_roar', 'boss_enrage', 'boss_burst', 'boss_charge', 'boss_volley']:
                    raise FileNotFoundError(f'Missing generated source: {source}')
                data = synth(name, seconds, variant)
                origin = 'original synthesis'
            targets = {'shoot': -15, 'power_shot': -15, 'boss_warning': -12, 'boss_reveal': -15, 'boss_roar': -14}
            if name in ['boss_warning', 'boss_reveal', 'boss_roar']:
                data = phone_presence(data)
            data = master(data, target_peak=.45 if name in MENU_NOTES else .70,
                          rms_db=targets.get(name))
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
