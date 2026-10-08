#!/usr/bin/env python3
"""Checks the store listing and Play Games translations (l10n/store/).

  python3 tool/l10n/check_store.py            # every l10n/store/<slug>.json
  python3 tool/l10n/check_store.py de ja

Each translation must have every text of l10n/store/en.json, non-empty and
within its "maxChars" (Play Console counts characters), and nothing more.
A text identical to the English is reported unless the English entry says
"keepEnglish": true.
"""
from __future__ import annotations

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import arb_lib as L  # noqa: E402

STORE = os.path.join(L.ROOT, 'l10n', 'store')


def texts(node, path=()):
    """(path, entry) for every {"text": ...} entry."""
    if isinstance(node, dict):
        if 'text' in node and isinstance(node['text'], str):
            yield path, node
            return
        for k, v in node.items():
            if not k.startswith('@'):
                yield from texts(v, path + (k,))


def main():
    english = dict(texts(L.load_json(os.path.join(STORE, 'en.json'))))
    slugs = sys.argv[1:] or [s for s in L.LANGUAGES if s != 'en'
                             and os.path.exists(os.path.join(STORE, f'{s}.json'))]
    errors = 0
    for slug in slugs:
        path = os.path.join(STORE, f'{slug}.json')
        if not os.path.exists(path):
            print(f'{slug}: no {os.path.relpath(path, L.ROOT)} yet')
            continue
        tr = dict(texts(L.load_json(path)))
        problems = []
        for key, en in english.items():
            name = '.'.join(key)
            entry = tr.get(key)
            if entry is None or not entry['text'].strip():
                problems.append(f'missing {name}')
                continue
            if len(entry['text']) > en.get('maxChars', 10 ** 9):
                problems.append(f'{name}: {len(entry["text"])} > {en["maxChars"]} characters')
            if entry['text'] == en['text'] and not en.get('keepEnglish'):
                problems.append(f'{name}: identical to the English (warning)')
        for key in tr:
            if key not in english:
                problems.append(f'extra {".".join(key)}')
        hard = [p for p in problems if not p.endswith('(warning)')]
        errors += len(hard)
        print(f'{slug}: {len(english) - sum(1 for p in problems if p.startswith("missing"))}'
              f'/{len(english)} texts' + (' | FAIL' if hard else ''))
        for p in problems:
            print(f'    {p}')
    sys.exit(1 if errors else 0)


if __name__ == '__main__':
    main()
