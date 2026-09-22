#!/usr/bin/env python3
"""Check native Android music playback while the game's menu or flight is open.

Usage: python3 tool/check_music_playback.py [--serial DEVICE] [--silent]
This reads the native players, so it detects audio-focus pauses that Flutter's
cached player state can miss. It does not change settings or interact with UI.
"""

import argparse
import json
import re
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--serial')
    parser.add_argument('--silent', action='store_true')
    args = parser.parse_args()
    adb = ['adb'] + (['-s', args.serial] if args.serial else [])
    dump = subprocess.run(
        adb + ['shell', 'dumpsys', 'media.player'],
        check=True, capture_output=True, text=True,
    ).stdout
    players = []
    for block in re.split(r'\n\s*Client\s*\n', dump):
        if 'packageName: com.ravanix.push_up_bird,' not in block:
            continue
        if 'mime(audio/vorbis)' not in block or 'looping(true)' not in block:
            continue
        connection = re.search(r'connId\((\d+)\)', block)
        volume = re.search(r'left - right volume\(([\d.]+),', block)
        players.append({
            'connection': connection.group(1) if connection else None,
            'playing': 'renderer(paused(0)' in block,
            'volume': float(volume.group(1)) if volume else None,
        })
    active = [p for p in players if p['playing'] and (p['volume'] or 0) > 0]
    expected = 0 if args.silent else 1
    print(json.dumps({'looping_music_players': players, 'expected_active': expected}, indent=2))
    if len(active) != expected:
        raise SystemExit(f'FAIL: expected {expected} active music player(s), found {len(active)}')
    print('PASS: native music playback matches the expected state')


if __name__ == '__main__':
    main()
