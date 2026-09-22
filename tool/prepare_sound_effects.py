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


def synth(name, seconds, variant):
    if name in MENU_NOTES:
        return menu_chime(name, seconds)
    data = [0.0] * int(RATE * seconds)
    if name == 'sprint':
        rush(data)
        impact(data, .10, .22)
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
    args = parser.parse_args()
    bank = (ROOT / 'lib/game/sound_bank.dart').read_text()
    records = []
    for match in re.finditer(r"'([a-z_]+)': SoundSpec\((.*?)\)", bank, re.S):
        name, fields = match.groups()
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
    report = ROOT / 'build/sound-effects/verification.json'
    report.parent.mkdir(parents=True, exist_ok=True)
    report.write_text(json.dumps(records, indent=2) + '\n')
    print(f'Mastered {len(records)} effects; report: {report}')


if __name__ == '__main__':
    main()
