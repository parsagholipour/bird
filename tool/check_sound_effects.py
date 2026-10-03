#!/usr/bin/env python3
"""Objective checks of the packaged sound effects (standard library only).

Nobody can audition a synthesised cue while it is being built, so this script
measures what an ear would notice and prints it as a table:

* format: mono, 16-bit, 44.1 kHz, and a length within a frame of the
  `seconds:` the sound bank reserves for it;
* peak, clipped samples, DC offset, whole-file RMS;
* loudness as played: RMS and loudest 100 ms RMS after the SoundSpec's
  playback volume, plain and A-weighted (phone speakers are deaf below about
  250 Hz, so the A-weighted figure is the one to compare across cues);
* the share of the energy in 250 Hz - 8 kHz (the band a phone reproduces);
* an envelope: the RMS of equal time slices (dB) and the spectral centroid of
  each slice (Hz), and with `--pitch` a fundamental-frequency track for tonal
  cues.

    python3 tool/check_sound_effects.py                     # every cue
    python3 tool/check_sound_effects.py --family steam      # one family
    python3 tool/check_sound_effects.py --names dragon_inhale dragon_breath
    python3 tool/check_sound_effects.py --json build/sound-effects/checks.json

`--spectrograms DIR` also writes a spectrogram PNG per cue with FFmpeg, for
looking at a pitch glide or a noise band instead of listening to it.

`--update-sources` rewrites the `files` entries (length, peak, RMS, SHA-256) of
every cue listed under `synthesised` in docs/sound-effects-sources.json from the
WAVs on disk; `--verify-sources` only compares and exits 1 on a difference.
"""
import argparse
import cmath
import hashlib
import json
import math
from pathlib import Path
import re
import subprocess
import sys
import wave

ROOT = Path(__file__).resolve().parents[1]
RATE = 44100

FAMILIES = {
    'pigeon': ['pigeon_coo', 'pigeon_flap', 'pigeon_snatch', 'pigeon_defeat',
               'star_rescue'],
    'steam': ['steam_hiss', 'steam_burst', 'pipe_clang', 'steam_ride'],
    'gargoyle': ['gargoyle_strike', 'gargoyle_awaken', 'beam_warning',
                 'beam_sweep', 'beam_spot', 'lamp_vent', 'lamp_glance',
                 'feather_drop'],
    'coo': ['coo_roar', 'coo_whistle', 'crumb_throw', 'crumb_splat',
            'squad_flutter', 'coo_puff', 'coo_pop', 'coo_defeat'],
    'fix': ['coo_shout', 'gargoyle_fury', 'gargoyle_shatter', 'coo_inflate',
            'steam_burst_duck', 'pipe_clang_duck', 'pigeon_snatch_lift'],
    'dragon': ['dragon_inhale', 'dragon_breath', 'ember_split'],
    # The campaign finish line, in the order they play, with its fanfare.
    'finish': ['finish_near', 'finish_snap', 'finish_cheer', 'complete',
               'finish_swoop'],
    'boss': ['boss_warning', 'boss_reveal', 'boss_roar', 'boss_enrage',
             'boss_charge', 'boss_hit', 'boss_break', 'boss_burst',
             'boss_victory'],
}
FAMILIES['new_york'] = (FAMILIES['pigeon'] + FAMILIES['steam'] +
                        FAMILIES['gargoyle'] + FAMILIES['coo'] + FAMILIES['fix'])
# Egypt (rules version 50): Neferhoo, the Mummy Courier (13 cues), and the
# scuff ducked under his postage due (an alias of wrap_scuff's file).
FAMILIES['egypt'] = ['hoopoe_roar', 'sand_devil', 'mail_call', 'letter_flick',
                     'letter_return', 'postage_due', 'wrap_scuff', 'ankh_raise',
                     'ankh_whir', 'ankh_catch', 'mummy_fury', 'mask_pop',
                     'lost_letter', 'wrap_scuff_duck']


def read_wav(path):
    with wave.open(str(path), 'rb') as w:
        channels, width, rate, frames = (w.getnchannels(), w.getsampwidth(),
                                         w.getframerate(), w.getnframes())
        raw = w.readframes(frames)
    import array
    pcm = array.array('h')
    pcm.frombytes(raw)
    if sys.byteorder != 'little':
        pcm.byteswap()
    return dict(channels=channels, width=width, rate=rate, pcm=pcm,
                samples=[v / 32768 for v in pcm])


def sound_specs():
    """Reads volume/seconds/variants/priority from lib/game/sound_bank.dart."""
    bank = (ROOT / 'lib/game/sound_bank.dart').read_text()
    specs = {}
    for name, fields in re.findall(r"'([a-z_]+)': SoundSpec\((.*?)\)", bank, re.S):
        def num(key, default):
            m = re.search(key + r': ([.\d]+)', fields)
            return float(m[1]) if m else default
        alias = re.search(r"file: '([a-z_]+)'", fields)
        specs[name] = dict(volume=num('volume', .42), priority=int(num('priority', 2)),
                           seconds=num('seconds', .65), cooldown=int(num('cooldownMs', 100)),
                           variants=int(num('variants', 1)), file=alias[1] if alias else None)
    return specs


def asset_files(name, variants, file=None):
    return [ROOT / 'assets/audio' /
            ((file or name) + (f'_{v + 1}' if v else '') + '.wav') for v in range(variants)]


def fft(values):
    """Iterative radix-2 FFT of a power-of-two list of floats."""
    n = len(values)
    bits = n.bit_length() - 1
    a = [complex(values[int(format(i, f'0{bits}b')[::-1], 2)]) for i in range(n)]
    size = 2
    while size <= n:
        step = cmath.exp(-2j * math.pi / size)
        half = size // 2
        for start in range(0, n, size):
            w = 1 + 0j
            for k in range(half):
                u = a[start + k]
                v = a[start + k + half] * w
                a[start + k] = u + v
                a[start + k + half] = u - v
                w *= step
        size *= 2
    return a


def a_weight(f):
    """IEC 61672 A-weighting as a power ratio (1.0 at 1 kHz)."""
    if f <= 0:
        return 0.0
    f2 = f * f
    ra = (12194 ** 2 * f2 * f2) / ((f2 + 20.6 ** 2) * math.sqrt((f2 + 107.7 ** 2) *
                                                           (f2 + 737.9 ** 2)) *
                                   (f2 + 12194 ** 2))
    return (ra / 0.7943) ** 2  # ra(1 kHz) = 0.7943 (-2 dB), so this is 1 there


def hann(n):
    return [.5 - .5 * math.cos(2 * math.pi * i / (n - 1)) for i in range(n)]


def db(power, floor=1e-12):
    return 10 * math.log10(max(power, floor))


def frames(samples, size, hop):
    window = hann(size)
    out = []
    for start in range(0, max(1, len(samples) - size + 1), hop):
        chunk = samples[start:start + size]
        chunk += [0.0] * (size - len(chunk))
        out.append((start, [c * w for c, w in zip(chunk, window)]))
    return out


def spectrum_stats(samples, rate, size=2048, hop=1024):
    """Per frame: (time, total power, A-weighted power, 250-8k power, centroid)."""
    freqs = [i * rate / size for i in range(size // 2 + 1)]
    weights = [a_weight(f) for f in freqs]
    band = [250 <= f <= 8000 for f in freqs]
    norm = sum(w * w for w in hann(size))
    out = []
    for start, chunk in frames(samples, size, hop):
        spec = fft(chunk)
        # Parseval: the half-spectrum sums (doubled) to the frame's mean square.
        power = [abs(spec[i]) ** 2 / (norm * size) for i in range(size // 2 + 1)]
        total = sum(power) * 2
        aw = sum(p * w for p, w in zip(power, weights)) * 2
        inband = sum(p for p, b in zip(power, band) if b) * 2
        centroid = (sum(f * p for f, p in zip(freqs, power)) / sum(power)
                    if sum(power) > 1e-18 else 0.0)
        out.append(((start + size / 2) / rate, total, aw, inband, centroid))
    return out


def rms(values):
    return math.sqrt(sum(v * v for v in values) / max(1, len(values)))


def pitch_track(samples, rate, hop=.02, low=110, high=1400, size=.05):
    """A crude normalised-autocorrelation f0 track (Hz, 0 = unvoiced) on a
    4x decimated signal, enough to see that a designed glide went where it
    should. Returns [(time, f0, clarity)]."""
    dec = 4
    x = [sum(samples[i:i + dec]) / dec for i in range(0, len(samples) - dec, dec)]
    r = rate / dec
    win = int(size * r)
    lo, hi = int(r / high), int(r / low)
    out = []
    t = 0.0
    while int(t * r) + win + hi < len(x):
        s = int(t * r)
        seg = x[s:s + win + hi]
        energy = sum(v * v for v in seg[:win])
        best, best_lag = 0.0, 0
        if energy > 1e-7:
            for lag in range(lo, hi + 1):
                num = sum(seg[i] * seg[i + lag] for i in range(win))
                den = math.sqrt(energy * sum(v * v for v in seg[lag:lag + win]) + 1e-18)
                c = num / den
                if c > best:
                    best, best_lag = c, lag
        out.append((t + size / 2, r / best_lag if best > .55 and best_lag else 0.0, best))
        t += hop
    return out


def analyse(name, path, spec, slices, pitch):
    wav = read_wav(path)
    x, pcm = wav['samples'], wav['pcm']
    n = len(x)
    seconds = n / wav['rate']
    mean = sum(x) / n
    peak = max(abs(v) for v in x)
    clipped = sum(1 for v in pcm if v >= 32767 or v <= -32768)
    level = rms(x)
    gain = spec['volume'] if spec else 1.0
    stats = spectrum_stats(x, wav['rate'])
    # Short-term loudness: the loudest 100 ms of plain RMS.
    win = int(.1 * wav['rate'])
    hop = win // 2
    loud = max(rms(x[i:i + win]) for i in range(0, max(1, n - win + 1), hop))
    total_p = sum(s[1] for s in stats)
    aw_p = sum(s[2] for s in stats) / len(stats)
    band_share = sum(s[3] for s in stats) / max(total_p, 1e-18)
    # Loudest 100 ms A-weighted (about two frames of 2048 at hop 1024).
    aw_max = max((stats[i][2] + stats[min(i + 1, len(stats) - 1)][2]) / 2
                 for i in range(len(stats)))
    out = dict(
        name=name, file=path.name, seconds=round(seconds, 3),
        spec_seconds=spec['seconds'] if spec else None,
        format=f"{wav['channels']}ch/{wav['width'] * 8}bit/{wav['rate']}",
        peak_db=round(db(peak * peak), 2), clipped=clipped,
        dc=round(mean, 6), rms_db=round(db(level * level), 2),
        gain_db=round(20 * math.log10(gain), 2) if spec else 0.0,
        played_rms_db=round(db(level * level) + (20 * math.log10(gain) if spec else 0), 2),
        played_loud100_db=round(db(loud * loud) + (20 * math.log10(gain) if spec else 0), 2),
        played_aw_db=round(db(aw_p) + (20 * math.log10(gain) if spec else 0), 2),
        played_aw_max_db=round(db(aw_max) + (20 * math.log10(gain) if spec else 0), 2),
        band_250_8k=round(band_share, 3),
    )
    # Envelope and centroid per equal slice.
    per = n // slices
    env, cent = [], []
    for i in range(slices):
        part = x[i * per:(i + 1) * per]
        env.append(round(db(rms(part) ** 2), 1))
        lo_t, hi_t = i * per / wav['rate'], (i + 1) * per / wav['rate']
        inside = [s for s in stats if lo_t <= s[0] < hi_t and s[1] > 1e-9]
        if inside:
            weight = sum(s[1] for s in inside)
            cent.append(round(sum(s[4] * s[1] for s in inside) / weight))
        else:
            cent.append(0)
    out['slice_rms_db'], out['slice_centroid_hz'] = env, cent
    # Where the loudest 10 ms is, and how fast the attack is.
    small = int(.01 * wav['rate'])
    rms10 = [rms(x[i:i + small]) for i in range(0, n - small, small)]
    top = max(range(len(rms10)), key=rms10.__getitem__)
    out['peak_at_s'] = round(top * .01, 2)
    tail = x[-int(.05 * wav['rate']):]
    out['tail_rms_db'] = round(db(rms(tail) ** 2), 1)
    out['head_rms_db'] = round(db(rms(x[:int(.005 * wav['rate'])]) ** 2), 1)
    if pitch:
        out['f0'] = [(round(t, 2), round(f)) for t, f, c in pitch_track(x, wav['rate'])
                     if f][::2]
    return out


def spectrogram(path, target):
    target.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run([
        'ffmpeg', '-v', 'error', '-y', '-i', str(path), '-lavfi',
        'showspectrumpic=s=900x260:legend=1:scale=log:fscale=log:stop=16000:'
        'start=40:gain=6:drange=90:color=intensity',
        str(target)], check=True)


SOURCES = ROOT / 'docs/sound-effects-sources.json'


def source_files(name, variants):
    files = []
    for path in asset_files(name, variants):
        w = read_wav(path)
        x = w['samples']
        rms_v = math.sqrt(sum(v * v for v in x) / len(x))
        files.append(dict(asset=path.name, seconds=round(len(x) / w['rate'], 3),
                          peak_db=round(20 * math.log10(max(abs(v) for v in x)), 2),
                          rms_db=round(20 * math.log10(rms_v), 2),
                          sha256=hashlib.sha256(path.read_bytes()).hexdigest()))
    return files


def sync_sources(write):
    """Compares (or rewrites) the `files` entries of the synthesised cues."""
    data = json.loads(SOURCES.read_text())
    stale = []
    for group in data.get('synthesised', {}).values():
        if not isinstance(group, dict):
            continue
        for name, entry in group.get('cues', {}).items():
            fresh = source_files(name, entry['spec']['variants'])
            if fresh != entry.get('files'):
                stale.append(name)
                entry['files'] = fresh
    if write and stale:
        SOURCES.write_text(json.dumps(data, indent=2) + '\n')
    return stale


def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--names', nargs='+')
    parser.add_argument('--family', choices=sorted(FAMILIES))
    parser.add_argument('--slices', type=int, default=8)
    parser.add_argument('--pitch', action='store_true')
    parser.add_argument('--json', type=Path)
    parser.add_argument('--spectrograms', type=Path)
    parser.add_argument('--update-sources', action='store_true')
    parser.add_argument('--verify-sources', action='store_true')
    args = parser.parse_args()
    if args.update_sources or args.verify_sources:
        stale = sync_sources(write=args.update_sources)
        verb = 'updated' if args.update_sources else 'stale'
        print(f'{verb}: {", ".join(stale) if stale else "none"}')
        sys.exit(1 if stale and args.verify_sources else 0)
    specs = sound_specs()
    names = args.names or (FAMILIES[args.family] if args.family else
                           [n for n in specs if n != 'game_over'])
    results = []
    for name in names:
        spec = specs.get(name)
        variants = spec['variants'] if spec else 1
        for variant, path in enumerate(
                asset_files(name, variants, spec['file'] if spec else None)):
            if not path.exists():
                print(f'{name}: missing {path.name}')
                continue
            # An alias (SoundSpec.file) is labelled with its own name.
            label = name + (f'_{variant + 1}' if variant else '')
            r = analyse(label, path, spec, args.slices, args.pitch)
            results.append(r)
            if args.spectrograms:
                spectrogram(path, args.spectrograms / f'{label}.png')
    print(f"{'asset':18s} {'sec':>5s} {'spec':>5s} {'peak':>6s} {'clip':>4s} {'dc':>8s} "
          f"{'rms':>6s} {'gain':>5s} {'rms@play':>8s} {'loud100':>7s} {'Aw@play':>7s} "
          f"{'Awmax':>6s} {'250-8k':>6s} {'pk@':>5s}")
    for r in results:
        print(f"{r['name']:18s} {r['seconds']:5.2f} {r['spec_seconds'] or 0:5.2f} "
              f"{r['peak_db']:6.2f} {r['clipped']:4d} {r['dc']:8.5f} {r['rms_db']:6.2f} "
              f"{r['gain_db']:5.1f} {r['played_rms_db']:8.2f} {r['played_loud100_db']:7.2f} "
              f"{r['played_aw_db']:7.2f} {r['played_aw_max_db']:6.2f} "
              f"{r['band_250_8k']:6.3f} {r['peak_at_s']:5.2f}")
    print()
    for r in results:
        print(f"{r['name']:18s} rms/slice {' '.join(f'{v:6.1f}' for v in r['slice_rms_db'])}")
        print(f"{'':18s} centroid  {' '.join(f'{v:6d}' for v in r['slice_centroid_hz'])}")
        if args.pitch and r.get('f0'):
            print(f"{'':18s} f0        " + ' '.join(f"{t}s:{f}" for t, f in r['f0']))
    if args.json:
        args.json.parent.mkdir(parents=True, exist_ok=True)
        args.json.write_text(json.dumps(results, indent=1) + '\n')


if __name__ == '__main__':
    main()
