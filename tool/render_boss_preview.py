#!/usr/bin/env python3
"""Mux the actual Flutter-rendered choreography frames and timed sound cues.

First: flutter test --no-pub --dart-define=CAPTURE_BOSS_MOVIE=true
       test/boss_choreography_art_test.dart
Then:  python3 tool/render_boss_preview.py

For the Spitter King use CAPTURE_SPITTER_BOSS_MOVIE=true and --boss spitter.
"""
import argparse
import array
import json
import pathlib
import subprocess
import sys
import wave

ROOT = pathlib.Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--boss', choices=['bat', 'spitter'], default='bat')
args = parser.parse_args()
prefix = 'spitter-boss' if args.boss == 'spitter' else 'boss'
FRAMES = ROOT / f'build/visual-review/{prefix}-movie'
RATE = 22050
duration = len(list(FRAMES.glob('frame-*.png'))) / 30
mix = [0.0] * (round(duration * RATE) + RATE)
for event in json.loads((FRAMES / 'cues.json').read_text()):
    with wave.open(str(ROOT / 'assets/audio' / f"{event['cue']}.wav"), 'rb') as source:
        assert source.getframerate() == RATE and source.getnchannels() == 1
        samples = array.array('h', source.readframes(source.getnframes()))
        if sys.byteorder != 'little':
            samples.byteswap()
    offset = round(event['time'] * RATE)
    for i, sample in enumerate(samples):
        if offset + i < len(mix):
            mix[offset + i] += sample * .65
peak = max(abs(v) for v in mix) or 1
scale = min(1, 30000 / peak)
pcm = array.array('h', (round(v * scale) for v in mix))
if sys.byteorder != 'little':
    pcm.byteswap()
with wave.open(str(FRAMES / 'soundtrack.wav'), 'wb') as output:
    output.setparams((1, 2, RATE, len(pcm), 'NONE', 'not compressed'))
    output.writeframes(pcm.tobytes())
target = ROOT / f'build/visual-review/{prefix}-cinematic-preview.mp4'
subprocess.run([
    'ffmpeg', '-y', '-loglevel', 'error', '-framerate', '30', '-i', str(FRAMES / 'frame-%04d.png'),
    '-i', str(FRAMES / 'soundtrack.wav'), '-c:v', 'libx264', '-crf', '18', '-pix_fmt', 'yuv420p',
    '-c:a', 'aac', '-b:a', '128k', '-shortest', '-movflags', '+faststart', str(target),
], check=True)
print(target)
