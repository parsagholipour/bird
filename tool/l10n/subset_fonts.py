#!/usr/bin/env python3
"""Cuts the localization fonts to the characters the translations use.

  python3 tool/l10n/subset_fonts.py --fetch        # download sources, subset
  python3 tool/l10n/subset_fonts.py --sources DIR  # sources already on disk
  python3 tool/l10n/subset_fonts.py --report       # sizes only, write nothing

Run it again whenever translations (lib/l10n/arb/app_*.arb) or story
captions (assets/l10n/story/*.json) change: a character a subset lacks
falls back to a system font on the phone, and check_arb.py reports it.

For each family in tool/l10n/fonts.json with "subset": true, the kept
characters are the union, over the family's languages, of every character
in their ARB messages, their captions, their native name and their seed
set (fonts.json "seeds"), intersected with what the source font has. The
full source fonts are pinned to one google/fonts commit and checked by
sha256; --fetch keeps them in build/l10n-fonts/ (not in the repo, not in
the app). OpenType layout features are kept (Arabic joining, Japanese
vertical forms are dropped by nothing), hinting is dropped, the name table
(copyright, license) is kept. The total of the families must stay within
"budgetBytes" (3 MB).
"""
from __future__ import annotations

import argparse
import hashlib
import os
import sys
import urllib.parse
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import arb_lib as L  # noqa: E402

CACHE = os.path.join(L.ROOT, 'build', 'l10n-fonts')


def sha256(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(1 << 20), b''):
            h.update(chunk)
    return h.hexdigest()


def source_path(cfg, family, spec, sources, fetch):
    name = os.path.basename(spec['source'])
    path = os.path.join(sources, name)
    if not os.path.exists(path):
        if not fetch:
            raise SystemExit(f'{family}: source {path} missing; run with --fetch '
                             'or --sources DIR')
        os.makedirs(sources, exist_ok=True)
        url = cfg['sourceBase'] + urllib.parse.quote(spec['source'])
        print(f'fetching {url}')
        tmp = path + '.part'
        with urllib.request.urlopen(url, timeout=120) as r, open(tmp, 'wb') as f:
            f.write(r.read())
        os.replace(tmp, path)
    digest = sha256(path)
    if digest != spec['sha256']:
        raise SystemExit(f'{family}: {path} sha256 {digest} != pinned {spec["sha256"]}')
    return path


def family_chars(cfg, spec):
    chars = set()
    for slug in spec.get('languages', []):
        chars |= L.language_chars(slug, cfg)
    # Every language's own name, for the language picker.
    for slug, (_, _, native) in L.LANGUAGES.items():
        chars |= set(native)
    return chars


def subset(src, dst, chars):
    from fontTools import subset as fts
    from fontTools.ttLib import TTFont
    font = TTFont(src)
    cmap = font.getBestCmap()
    keep = sorted({ord(c) for c in chars} & set(cmap))
    opts = fts.Options()
    opts.layout_features = ['*']
    opts.name_IDs = ['*']
    opts.name_languages = ['*']
    opts.name_legacy = True
    opts.hinting = False
    opts.notdef_outline = True
    opts.glyph_names = False
    opts.drop_tables += ['DSIG']
    sub = fts.Subsetter(options=opts)
    sub.populate(unicodes=keep)
    sub.subset(font)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    font.save(dst)
    return len(keep), len({ord(c) for c in chars} - set(cmap))


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--fetch', action='store_true', help='download missing sources')
    ap.add_argument('--sources', default=CACHE, help=f'source fonts dir (default {CACHE})')
    ap.add_argument('--report', action='store_true', help='print sizes, write nothing')
    args = ap.parse_args()
    cfg = L.fonts_config()
    total = 0
    for family, spec in cfg['families'].items():
        asset = os.path.join(L.ROOT, spec['asset'])
        if spec.get('subset') and not args.report:
            src = source_path(cfg, family, spec, args.sources, args.fetch)
            chars = family_chars(cfg, spec)
            kept, absent = subset(src, asset, chars)
            note = f'{kept} chars kept, {absent} wanted chars not in the font'
        else:
            note = 'bundled as is' if not spec.get('subset') else 'subset'
        size = os.path.getsize(asset) if os.path.exists(asset) else 0
        if spec.get('subset'):
            total += size
        print(f'{family:16s} {size / 1024:8.1f} KB  {spec["asset"]}  ({note})')
        lic = os.path.join(L.ROOT, spec['license'])
        if not os.path.exists(lic):
            print(f'  warning: license file {spec["license"]} missing')
    budget = cfg['budgetBytes']
    print(f'added by localization: {total / 1024:.1f} KB of {budget / 1024:.0f} KB budget')
    if total > budget:
        print('error: over the font budget')
        sys.exit(1)


if __name__ == '__main__':
    main()
