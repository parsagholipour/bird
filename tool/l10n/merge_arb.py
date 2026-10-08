#!/usr/bin/env python3
"""Merges the extraction builders' English fragments into the template.

  python3 tool/l10n/merge_arb.py            # merge l10n/fragments/*.arb
  python3 tool/l10n/merge_arb.py --check    # validate only, write nothing
  python3 tool/l10n/merge_arb.py a.arb b.arb

Each fragment is an ARB holding only English messages and their `@key`
metadata (`l10n/fragments/<slice>.arb`, one per builder). The merge:

* fails on a key whose text differs from the same key in the template or in
  another fragment (identical duplicates are fine: shared `common*` keys);
* fails on a bad key name, a message without an `@key` description, ICU
  syntax errors, and placeholders used but not declared (or declared but
  unused);
* appends new keys to lib/l10n/arb/app_en.arb in fragment order, keeping
  the template's own order and metadata;
* makes sure every language's ARB (and the es / pt / zh base stubs) exists,
  and rewrites the pseudo-locale app_en_XA.arb (pseudo_arb.py).

Then run `flutter gen-l10n`.
"""
from __future__ import annotations

import argparse
import glob
import os
import re
import sys
from collections import OrderedDict

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import arb_lib as L  # noqa: E402
import pseudo_arb  # noqa: E402

KEY = re.compile(r'^[a-z][A-Za-z0-9_]*$')


def validate_entry(key, text, meta, where, errors):
    if not KEY.match(key):
        errors.append(f'{where}: key {key!r} must match {KEY.pattern} '
                      '(lowerCamelCase; data keys may use _ between parts)')
    if not isinstance(text, str):
        errors.append(f'{where}: {key} is not a string')
        return
    if not isinstance(meta, dict) or not str(meta.get('description', '')).strip():
        errors.append(f'{where}: {key} needs "@{key}": {{"description": ...}}')
        meta = meta if isinstance(meta, dict) else {}
    try:
        used = L.placeholders(L.parse(text))
    except L.IcuError as e:
        errors.append(f'{where}: {key}: ICU error: {e}')
        return
    declared = set((meta.get('placeholders') or {}).keys())
    if used - declared:
        errors.append(f'{where}: {key}: placeholders {sorted(used - declared)} '
                      'used but not declared in "placeholders"')
    if declared - used:
        errors.append(f'{where}: {key}: placeholders {sorted(declared - used)} '
                      'declared but not used')
    choices = meta.get('x-choices')
    if choices is not None and (not isinstance(choices, list) or text not in choices):
        errors.append(f'{where}: {key}: x-choices must be a list holding the '
                      f'English value {text!r}')
    budget = meta.get('x-maxChars')
    if budget is not None:
        if not isinstance(budget, int) or budget <= 0:
            errors.append(f'{where}: {key}: x-maxChars must be a positive int')
        else:
            widest = max(L.display_width(v) for v in L.variants(L.parse(text)))
            if widest > budget:
                errors.append(f'{where}: {key}: English is {widest} wide, over '
                              f'its own x-maxChars {budget}')


def merge(fragments, check_only=False):
    template = L.load_json(L.TEMPLATE)
    errors, warnings = [], []
    for key, text in L.messages(template).items():
        validate_entry(key, text, template.get('@' + key), 'app_en.arb', errors)
    seen = {k: 'app_en.arb' for k in L.messages(template)}
    added = OrderedDict()
    for path in fragments:
        name = os.path.relpath(path, L.ROOT)
        try:
            frag = L.load_json(path)
        except Exception as e:  # noqa: BLE001
            errors.append(f'{name}: not valid JSON: {e}')
            continue
        loc = frag.get('@@locale', 'en')
        if loc != 'en':
            errors.append(f'{name}: @@locale must be "en" (fragments are English)')
        for key in frag:
            if key.startswith('@') and not key.startswith('@@') and key[1:] not in frag:
                errors.append(f'{name}: metadata {key} has no message')
        for key, text in L.messages(frag).items():
            meta = frag.get('@' + key)
            validate_entry(key, text, meta, name, errors)
            if key in template or key in added:
                existing = template.get(key, added.get(key, (None,))[0])
                if existing != text:
                    errors.append(f'{name}: {key} conflicts with {seen[key]}: '
                                  f'{existing!r} vs {text!r}')
                else:
                    old = template.get('@' + key) or added.get(key, (None, {}))[1]
                    if (old or {}).get('description') != (meta or {}).get('description'):
                        warnings.append(f'{name}: {key} duplicates {seen[key]} '
                                        'with another description (kept the first)')
                continue
            seen[key] = name
            added[key] = (text, meta)
    for w in warnings:
        print('warning:', w)
    if errors:
        for e in errors:
            print('error:', e)
        print(f'{len(errors)} error(s); nothing written.')
        return 1
    if check_only:
        print(f'ok: {len(L.messages(template))} template keys, {len(added)} new '
              f'from {len(fragments)} fragment(s) (check only)')
        return 0
    for key, (text, meta) in added.items():
        template[key] = text
        template['@' + key] = meta
    L.dump_json(template, L.TEMPLATE)
    ensure_locale_files()
    pseudo_arb.write()
    print(f'ok: merged {len(added)} new key(s) from {len(fragments)} fragment(s); '
          f'template has {len(L.messages(template))} keys. Now: flutter gen-l10n')
    return 0


def ensure_locale_files():
    """Every language's ARB and the base stubs exist (empty = English)."""
    for slug, (locale, tag, native) in L.LANGUAGES.items():
        if slug == 'en':
            continue
        path = L.arb_path(locale)
        if not os.path.exists(path):
            L.dump_json(OrderedDict([
                ('@@locale', locale),
                ('@@x-language', f'{tag} {native}'),
            ]), path)
    for base, regional in L.BASE_STUBS.items():
        path = L.arb_path(base)
        if not os.path.exists(path):
            L.dump_json(OrderedDict([
                ('@@locale', base),
                ('@@x-note', f'Empty on purpose: gen-l10n needs a base file '
                             f'beside app_{regional}.arb. Translate app_{regional}.arb; '
                             f'this one falls back to English.'),
            ]), path)


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('fragments', nargs='*')
    ap.add_argument('--check', action='store_true')
    args = ap.parse_args()
    frags = args.fragments or sorted(glob.glob(os.path.join(L.FRAGMENTS, '*.arb')))
    sys.exit(merge(frags, args.check))


if __name__ == '__main__':
    main()
