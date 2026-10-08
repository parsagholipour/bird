#!/usr/bin/env python3
"""Bundles a language's story captions from its voice script.

  python3 tool/l10n/build_captions.py de path/to/l10n-ws/voice/de/story.json
  python3 tool/l10n/build_captions.py --all path/to/l10n-ws/voice

The translators' voice script is `{"<clip>": {"text": ..., "prompt": ...}}`
(l10n-ws/BRIEF.md, "Contracts"). The game needs only the caption, so this
writes `assets/l10n/story/<slug>.json` as a flat `{"<clip>": "<text>"}`
(in docs/story-voices-sources.json order) and lists the language in
`assets/l10n/story/index.json`. It fails on clip names the English sources
do not have, and reports English clips the language lacks (they show the
English line). Pending English clips are translated like any other: their
captions show although no one voices them yet.
"""
from __future__ import annotations

import argparse
import os
import sys
from collections import OrderedDict

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import arb_lib as L  # noqa: E402

SOURCES = os.path.join(L.ROOT, 'docs', 'story-voices-sources.json')
INDEX = os.path.join(L.CAPTIONS_DIR, 'index.json')


def english_clips():
    src = L.load_json(SOURCES)
    clips = OrderedDict()
    for clip in list(src.get('clips', [])) + list(src.get('optional_clips', [])):
        clips[clip['name']] = clip['text']
    return clips


def build(slug, script_path, english):
    if slug not in L.LANGUAGES or slug == 'en':
        raise SystemExit(f'unknown language slug {slug!r}')
    script = L.load_json(script_path)
    unknown = [k for k in script if k not in english and not k.startswith('@')]
    if unknown:
        raise SystemExit(f'{script_path}: clips not in {os.path.relpath(SOURCES, L.ROOT)}: '
                         f'{unknown[:10]}{"..." if len(unknown) > 10 else ""}')
    out = OrderedDict([('@@language', slug)])
    empty = []
    for name in english:
        entry = script.get(name)
        if entry is None:
            continue
        text = entry.get('text') if isinstance(entry, dict) else entry
        if not isinstance(text, str) or not text.strip():
            empty.append(name)
            continue
        out[name] = text.strip()
    os.makedirs(L.CAPTIONS_DIR, exist_ok=True)
    L.dump_json(out, L.captions_path(slug))
    index = L.load_json(INDEX) if os.path.exists(INDEX) else OrderedDict(languages=[])
    langs = [s for s in L.LANGUAGES if s in set(index.get('languages', [])) | {slug}]
    index['languages'] = langs
    L.dump_json(index, INDEX)
    missing = [n for n in english if n not in out]
    print(f'{slug}: {len(out) - 1} captions -> {os.path.relpath(L.captions_path(slug), L.ROOT)}; '
          f'{len(missing)} clip(s) fall back to English'
          + (f'; {len(empty)} empty' if empty else ''))


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('slug', nargs='?')
    ap.add_argument('script', nargs='?')
    ap.add_argument('--all', metavar='VOICE_DIR',
                    help='every <VOICE_DIR>/<slug>/story.json that exists')
    args = ap.parse_args()
    english = english_clips()
    if args.all:
        for slug in L.LANGUAGES:
            path = os.path.join(args.all, slug, 'story.json')
            if slug != 'en' and os.path.exists(path):
                build(slug, path, english)
    elif args.slug and args.script:
        build(args.slug, args.script, english)
    else:
        ap.error('give SLUG SCRIPT or --all VOICE_DIR')


if __name__ == '__main__':
    main()
