#!/usr/bin/env python3
"""Checks every translation against the English template and the fonts.

  python3 tool/l10n/check_arb.py                  # all languages
  python3 tool/l10n/check_arb.py de ja -v         # some, with every finding
  python3 tool/l10n/check_arb.py --require-complete
  python3 tool/l10n/check_arb.py --json report.json

Per language (lib/l10n/arb/app_<locale>.arb, plus its base stub) and its
story captions (assets/l10n/story/<slug>.json):

errors (exit 1)
  extra        a key the template does not have (gen-l10n would drop it)
  icu          ICU syntax: braces, plural/select without "other", bad cases,
               a plural with both =0/zero, =1/one or =2/two (gen-l10n maps
               =N onto the category, so one of the two is silently lost)
  placeholder  a placeholder the English message does not declare, or one
               the English uses that the translation lost
  select       select cases the English message does not have (nor its
               "x-selectCases", the ids a translation may select on)
  length       wider than the key's "x-maxChars" (display width: CJK and
               fullwidth characters count 2)
  empty        an empty translation
  choice       a switch key ("x-choices" in the template, e.g. a layout
               order) whose value is not one of its choices
  subset       a character the script's source font has but the bundled
               subset lacks: run tool/l10n/subset_fonts.py
  caption      a caption for a clip docs/story-voices-sources.json lacks
warnings
  untranslated a key with no translation yet (English shows); an error with
               --require-complete
  long         over 1.6x the English width where no budget is set
  english      identical to the English, or (non-Latin scripts) mostly Latin
               letters: probably left untranslated; mark a deliberate one
               with "x-keepEnglish": true in the template's @key
  glyph        a character no font of the language's chains has (plus the
               key's "x-fontFallback" families, which its widget adds): it falls
               back to a system font (line breaks and invisible bidi/format
               marks never count; a symbol the English message of the same
               key also uses, such as ★, is the English's own choice)
  space        leading/trailing spaces differ from the English
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
from collections import OrderedDict, defaultdict

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import arb_lib as L  # noqa: E402
import build_captions  # noqa: E402

LONG_RATIO = 1.6
SOURCES_DEFAULT = os.path.join(L.ROOT, 'build', 'l10n-fonts')
# Characters no font needs to draw: spaces and line breaks, the invisible
# bidi/format marks (LRM, RLM, the isolates, ALM) that only steer the bidi
# algorithm (the Arabic signs "+5" keep their order with an LRM), and the
# word joiner (U+2060), which keeps a Japanese katakana word on one line.
INVISIBLE = set(' \n\r\t\u200e\u200f\u2066\u2067\u2068\u2069\u061c\u2060')
# Symbols accepted where the English message of the same key has them:
# the English chose them (★ in Google's own save list), not the translator.
ENGLISH_SYMBOLS = set('★')


class Fonts:
    def __init__(self, cfg, sources):
        from fontTools.ttLib import TTFont
        self.cfg = cfg
        self.bundled, self.source = {}, {}
        for family, spec in cfg['families'].items():
            path = os.path.join(L.ROOT, spec['asset'])
            self.bundled[family] = set(TTFont(path).getBestCmap()) if os.path.exists(path) else set()
            if spec.get('subset'):
                src = os.path.join(sources, os.path.basename(spec['source']))
                if os.path.exists(src):
                    self.source[family] = set(TTFont(src).getBestCmap())

    def chains(self, slug):
        lang = self.cfg['languages'][slug]
        return {
            'heading': [lang['heading']] + list(lang['headingFallback']),
            'body': ['Nunito'] + list(lang['bodyFallback']),
        }

    def missing(self, slug, ch, extra=()):
        """(kind, detail) for a character the chains cannot draw, or None.
        [extra] families end every chain (a key's "x-fontFallback")."""
        cp = ord(ch)
        for name, chain in self.chains(slug).items():
            chain = chain + [f for f in extra if f not in chain]
            if any(cp in self.bundled[f] for f in chain):
                continue
            in_source = [f for f in chain if cp in self.source.get(f, set())]
            if in_source:
                return 'subset', f'{name} font {in_source[0]} has it; re-run subset_fonts.py'
            unknown = [f for f in chain if self.cfg['families'][f].get('subset')
                       and f not in self.source]
            return 'glyph', (f'not in the {name} chain {chain}'
                             + (f' (source of {unknown} not on disk: --fetch)' if unknown else ''))
        return None


PLURAL_ALIASES = {'=0': 'zero', '=1': 'one', '=2': 'two'}


def plural_overlaps(nodes):
    """Pairs like ['=1/one'] that gen-l10n would merge into one case."""
    out = []
    for n in nodes:
        if n[0] in ('plural', 'select', 'selectordinal'):
            if n[0] == 'plural':
                out += [f'{a}/{b}' for a, b in PLURAL_ALIASES.items()
                        if a in n[2] and b in n[2]]
            for inner in n[2].values():
                out += plural_overlaps(inner)
    return out


def check_language(slug, template, fonts, args):
    locale = L.LANGUAGES[slug][0]
    findings = defaultdict(list)

    def add(kind, key, detail):
        findings[kind].append((key, detail))

    tr = OrderedDict()
    for base, regional in L.BASE_STUBS.items():
        if regional == locale and os.path.exists(L.arb_path(base)):
            tr.update(L.messages(L.load_json(L.arb_path(base))))
    path = L.arb_path(locale)
    if os.path.exists(path):
        data = L.load_json(path)
        if data.get('@@locale') != locale:
            add('extra', '@@locale', f'is {data.get("@@locale")!r}, expected {locale!r}')
        tr.update(L.messages(data))
    else:
        add('extra', path, 'file missing (merge_arb.py creates it)')
    english = L.messages(template)
    latin_script = slug not in L.SCRIPT_LANGS
    for key in tr:
        if key not in english:
            add('extra', key, 'not in app_en.arb')
    for key, en_text in english.items():
        meta = template.get('@' + key) or {}
        text = tr.get(key)
        if text is None:
            add('untranslated', key, en_text)
            continue
        if not isinstance(text, str) or not text.strip():
            add('empty', key, repr(text))
            continue
        if meta.get('x-choices'):
            if text not in meta['x-choices']:
                add('choice', key, f'{text!r} is not one of {meta["x-choices"]}')
            continue
        try:
            nodes = L.parse(text)
        except L.IcuError as e:
            add('icu', key, str(e))
            continue
        overlap = plural_overlaps(nodes)
        if overlap:
            add('icu', key, f'plural cases {overlap} overlap: keep one of each pair')
        en_nodes = L.parse(en_text)
        declared = set((meta.get('placeholders') or {}).keys()) | L.placeholders(en_nodes)
        used = L.placeholders(nodes)
        if used - declared:
            add('placeholder', key, f'unknown {sorted(used - declared)}')
        # A select's discriminator ("x-selectCases": the boss's id) need not
        # appear in a language whose grammar has no use for it.
        optional = set((meta.get('x-selectCases') or {}).keys())
        lost = L.placeholders(en_nodes) - used - optional
        if lost:
            add('placeholder', key, f'lost {sorted(lost)}')
        en_selects = {n[1]: set(n[2]) for n in en_nodes if n[0] == 'select'}
        for name, cases in (meta.get('x-selectCases') or {}).items():
            en_selects[name] = en_selects.get(name, set()) | set(cases)
        for n in nodes:
            if n[0] == 'select' and n[1] in en_selects:
                extra = set(n[2]) - en_selects[n[1]] - {'other'}
                if extra:
                    add('select', key, f'cases {sorted(extra)} not in English')
        widest = max(L.display_width(v) for v in L.variants(nodes))
        en_widest = max(L.display_width(v) for v in L.variants(en_nodes))
        budget = meta.get('x-maxChars')
        if budget and widest > budget:
            add('length', key, f'{widest} > x-maxChars {budget}: {text}')
        elif not budget and en_widest >= 8 and widest > en_widest * LONG_RATIO:
            add('long', key, f'{widest} vs English {en_widest}: {text}')
        if ((text[:1].isspace(), text[-1:].isspace())
                != (en_text[:1].isspace(), en_text[-1:].isspace())):
            add('space', key, repr(text))
        if not meta.get('x-keepEnglish'):
            letters = ''.join(L.texts(nodes))
            if len(re.findall('[A-Za-z]', letters)) >= 4:
                # One identical word is often right (Paris, OK, Pip).
                if text == en_text and slug != 'en' and (' ' in text.strip() or not latin_script):
                    add('english', key, text)
                elif not latin_script:
                    ascii_letters = len(re.findall('[A-Za-z]', letters))
                    all_letters = len([c for c in letters if c.isalpha()])
                    if all_letters and ascii_letters / all_letters > .5:
                        add('english', key, f'mostly Latin letters: {text}')
        en_chars = set(''.join(L.texts(en_nodes)))
        for ch in sorted(set(''.join(L.texts(nodes)))):
            if ch in INVISIBLE or (ch in ENGLISH_SYMBOLS and ch in en_chars):
                continue
            miss = fonts.missing(slug, ch, meta.get('x-fontFallback') or ())
            if miss:
                add(miss[0], key, f'U+{ord(ch):04X} {ch!r}: {miss[1]}')
    # Story captions.
    cap = L.captions_path(slug)
    if os.path.exists(cap):
        en_clips = build_captions.english_clips()
        for clip, text in L.load_json(cap).items():
            if clip.startswith('@@'):
                continue
            if clip not in en_clips:
                add('caption', clip, 'not in docs/story-voices-sources.json')
                continue
            en = en_clips[clip]
            if L.display_width(text) > L.display_width(en) * LONG_RATIO and len(en) >= 12:
                add('long', f'caption {clip}', f'{L.display_width(text)} vs English {L.display_width(en)}')
            if not latin_script:
                a = len(re.findall('[A-Za-z]', text))
                t = len([c for c in text if c.isalpha()])
                if t and a / t > .5:
                    add('english', f'caption {clip}', f'mostly Latin letters: {text[:60]}')
            for ch in sorted(set(text)):
                if ch in INVISIBLE:
                    continue
                miss = fonts.missing(slug, ch)
                if miss:
                    add(miss[0], f'caption {clip}', f'U+{ord(ch):04X} {ch!r}: {miss[1]}')
    return findings


ERRORS = ['extra', 'icu', 'placeholder', 'select', 'length', 'empty', 'choice', 'subset',
          'caption']
WARNINGS = ['untranslated', 'long', 'english', 'glyph', 'space']


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('languages', nargs='*', help='slugs (default: all but en)')
    ap.add_argument('-v', '--verbose', action='store_true')
    ap.add_argument('--require-complete', action='store_true')
    ap.add_argument('--sources', default=SOURCES_DEFAULT,
                    help='full source fonts (subset_fonts.py --fetch puts them here)')
    ap.add_argument('--json', metavar='FILE')
    args = ap.parse_args()
    template = L.load_json(L.TEMPLATE)
    fonts = Fonts(L.fonts_config(), args.sources)
    slugs = args.languages or [s for s in L.LANGUAGES if s != 'en']
    errors_kinds = ERRORS + (['untranslated'] if args.require_complete else [])
    total_errors = 0
    report = OrderedDict()
    n_keys = len(L.messages(template))
    for slug in slugs:
        if slug not in L.LANGUAGES:
            ap.error(f'unknown language {slug!r}; one of {list(L.LANGUAGES)}')
        f = check_language(slug, template, fonts, args)
        report[slug] = {k: v for k, v in f.items()}
        errs = sum(len(f[k]) for k in errors_kinds)
        total_errors += errs
        done = n_keys - len(f['untranslated'])
        summary = ', '.join(f'{k} {len(f[k])}' for k in ERRORS + WARNINGS if f[k] and k != 'untranslated')
        print(f'{slug:8s} {done:5d}/{n_keys} translated'
              f'{" | " + summary if summary else ""}{" | FAIL" if errs else ""}')
        for kind in ERRORS + WARNINGS:
            items = f[kind]
            if not items or (kind == 'untranslated' and not args.verbose):
                continue
            show = items if args.verbose or kind in errors_kinds else items[:5]
            for key, detail in show:
                print(f'    {kind:12s} {key}: {detail}')
            if len(show) < len(items):
                print(f'    {kind:12s} ... {len(items) - len(show)} more (-v)')
    if args.json:
        with open(args.json, 'w', encoding='utf-8') as fh:
            json.dump(report, fh, ensure_ascii=False, indent=1)
    if total_errors:
        print(f'{total_errors} error(s)')
        sys.exit(1)


if __name__ == '__main__':
    main()
