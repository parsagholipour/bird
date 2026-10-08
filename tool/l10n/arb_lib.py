"""Shared helpers for the localization tools (tool/l10n/*.py).

ARB files, a small ICU MessageFormat parser for the subset gen-l10n
supports (placeholders, plural, select; no escaping: l10n.yaml leaves
`use-escaping` off, so apostrophes are literal), display widths and the
language table. Standard library only.
"""
from __future__ import annotations

import json
import os
import re
import unicodedata
from collections import OrderedDict

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ARB_DIR = os.path.join(ROOT, 'lib', 'l10n', 'arb')
TEMPLATE = os.path.join(ARB_DIR, 'app_en.arb')
FRAGMENTS = os.path.join(ROOT, 'l10n', 'fragments')
CAPTIONS_DIR = os.path.join(ROOT, 'assets', 'l10n', 'story')
FONTS_JSON = os.path.join(ROOT, 'tool', 'l10n', 'fonts.json')

# AppLanguage (lib/l10n/app_language.dart): slug -> (arb locale, BCP-47 tag,
# native name). English is the template.
LANGUAGES = OrderedDict([
    ('en', ('en', 'en', 'English')),
    ('es_419', ('es_419', 'es-419', 'Español (Latinoamérica)')),
    ('pt_br', ('pt_BR', 'pt-BR', 'Português (Brasil)')),
    ('id', ('id', 'id', 'Bahasa Indonesia')),
    ('fr', ('fr', 'fr', 'Français')),
    ('de', ('de', 'de', 'Deutsch')),
    ('ja', ('ja', 'ja', '日本語')),
    ('ko', ('ko', 'ko', '한국어')),
    ('tr', ('tr', 'tr', 'Türkçe')),
    ('zh_hant', ('zh_Hant', 'zh-Hant', '繁體中文')),
    ('ru', ('ru', 'ru', 'Русский')),
    ('ar', ('ar', 'ar', 'العربية')),
])
# gen-l10n needs a base-language file beside a regional one; these stay
# empty (their messages fall back to English) and translators never fill
# them.
BASE_STUBS = {'es': 'es_419', 'pt': 'pt_BR', 'zh': 'zh_Hant'}
PSEUDO = 'en_XA'
SCRIPT_LANGS = {'ja', 'ko', 'zh_hant', 'ru', 'ar'}  # not Latin script
PLURAL_KEYS = {'zero', 'one', 'two', 'few', 'many', 'other'}


def arb_path(locale: str) -> str:
    return os.path.join(ARB_DIR, f'app_{locale}.arb')


def load_json(path: str) -> 'OrderedDict':
    with open(path, encoding='utf-8') as f:
        return json.load(f, object_pairs_hook=OrderedDict)


def dump_json(data, path: str) -> None:
    tmp = path + '.tmp'
    with open(tmp, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write('\n')
    os.replace(tmp, path)


def messages(arb) -> 'OrderedDict':
    """The message entries of an ARB: no `@key` metadata, no `@@` globals."""
    return OrderedDict((k, v) for k, v in arb.items() if not k.startswith('@'))


# ---------------------------------------------------------------- ICU ----

class IcuError(ValueError):
    pass


def parse(msg: str):
    """Parses an ICU message into nodes:

    ('text', s) | ('arg', name) | (kind, name, {case: nodes}) with kind
    'plural' or 'select'. Raises IcuError on bad syntax.
    """
    nodes, i = _parse_nodes(msg, 0, top=True)
    if i != len(msg):
        raise IcuError(f'unexpected "}}" at {i}')
    return nodes


def _parse_nodes(s, i, top=False):
    nodes, buf = [], []
    while i < len(s):
        ch = s[i]
        if ch == '{':
            if buf:
                nodes.append(('text', ''.join(buf)))
                buf = []
            node, i = _parse_arg(s, i)
            nodes.append(node)
            continue
        if ch == '}':
            if top:
                raise IcuError(f'unbalanced "}}" at {i}')
            break
        buf.append(ch)
        i += 1
    if buf:
        nodes.append(('text', ''.join(buf)))
    return nodes, i


_NAME = re.compile(r'\s*([A-Za-z_][A-Za-z0-9_]*)\s*')


def _parse_arg(s, i):
    assert s[i] == '{'
    m = _NAME.match(s, i + 1)
    if not m:
        raise IcuError(f'bad placeholder at {i}: {s[i:i + 20]!r}')
    name, j = m.group(1), m.end()
    if j < len(s) and s[j] == '}':
        return ('arg', name), j + 1
    if j >= len(s) or s[j] != ',':
        raise IcuError(f'expected "," or "}}" after {name!r}')
    m = re.compile(r'\s*(plural|select|selectordinal)\s*,').match(s, j + 1)
    if not m:
        raise IcuError(f'unknown argument type after {name!r}')
    kind, j = m.group(1), m.end()
    cases = OrderedDict()
    while True:
        while j < len(s) and s[j].isspace():
            j += 1
        if j >= len(s):
            raise IcuError(f'unterminated {kind} for {name!r}')
        if s[j] == '}':
            j += 1
            break
        m = re.compile(r'(=\d+|[A-Za-z0-9_]+)\s*\{').match(s, j)
        if not m:
            raise IcuError(f'bad case in {kind} {name!r} at {j}: {s[j:j + 20]!r}')
        key = m.group(1)
        inner, k = _parse_nodes(s, m.end())
        if k >= len(s) or s[k] != '}':
            raise IcuError(f'unterminated case {key!r} in {name!r}')
        if key in cases:
            raise IcuError(f'duplicate case {key!r} in {name!r}')
        cases[key] = inner
        j = k + 1
    if 'other' not in cases:
        raise IcuError(f'{kind} {name!r} has no "other" case')
    if kind == 'plural':
        bad = [c for c in cases if c not in PLURAL_KEYS and not re.match(r'=\d+$', c)]
        if bad:
            raise IcuError(f'plural {name!r} has unknown cases {bad}')
    return (kind, name, cases), j


def placeholders(nodes) -> set:
    out = set()
    for n in nodes:
        if n[0] == 'arg':
            out.add(n[1])
        elif n[0] in ('plural', 'select', 'selectordinal'):
            out.add(n[1])
            for inner in n[2].values():
                out |= placeholders(inner)
    return out


def texts(nodes) -> list:
    """Every literal text run of a message, all cases included."""
    out = []
    for n in nodes:
        if n[0] == 'text':
            out.append(n[1])
        elif n[0] in ('plural', 'select', 'selectordinal'):
            for inner in n[2].values():
                out += texts(inner)
    return out


def variants(nodes, sample=8) -> list:
    """Each way the message can read, placeholders as `sample` letters
    wide (`{x}` -> 'xxxxxxxx' trimmed to the name), for length checks."""
    outs = ['']
    for n in nodes:
        if n[0] == 'text':
            outs = [o + n[1] for o in outs]
        elif n[0] == 'arg':
            outs = [o + 'x' * min(sample, 4) for o in outs]
        else:
            nxt = []
            for inner in n[2].values():
                for v in variants(inner, sample):
                    nxt += [o + v for o in outs]
            outs = nxt[:64]
    return outs


def rebuild(nodes, text_fn=lambda t: t) -> str:
    """The message from nodes, with every literal run passed through
    [text_fn] (used by the pseudo-locale)."""
    out = []
    for n in nodes:
        if n[0] == 'text':
            out.append(text_fn(n[1]))
        elif n[0] == 'arg':
            out.append('{' + n[1] + '}')
        else:
            cases = ' '.join(f'{k}{{{rebuild(v, text_fn)}}}' for k, v in n[2].items())
            out.append('{' + f'{n[1]}, {n[0]}, {cases}' + '}')
    return ''.join(out)


# ------------------------------------------------------------- widths ----

def display_width(s: str) -> int:
    """Width in Latin-letter units: East Asian wide/fullwidth characters
    count 2, combining marks and invisible format characters (LRM, the
    word joiner…) 0, everything else 1. `x-maxChars` budgets are in these
    units."""
    w = 0
    for ch in s:
        if unicodedata.combining(ch) or unicodedata.category(ch) == 'Cf':
            continue
        w += 2 if unicodedata.east_asian_width(ch) in ('W', 'F') else 1
    return w


# -------------------------------------------------------------- fonts ----

def fonts_config():
    return load_json(FONTS_JSON)


def seed_chars(lang: str, cfg=None) -> set:
    cfg = cfg or fonts_config()
    out = set()
    for key in ('common', lang):
        seed = cfg['seeds'].get(key)
        if not seed:
            continue
        for a, b in seed.get('ranges', []):
            out |= {chr(c) for c in range(a, b + 1)}
        out |= set(seed.get('text', ''))
    return out


def captions_path(slug: str) -> str:
    return os.path.join(CAPTIONS_DIR, f'{slug}.json')


def language_chars(slug: str, cfg=None, include_seeds=True) -> set:
    """Every character [slug]'s translations put on screen: its ARB values
    (base stub included), its story captions and its native name."""
    locale = LANGUAGES[slug][0]
    out = set(LANGUAGES[slug][2])
    paths = [arb_path(locale)]
    for base, regional in BASE_STUBS.items():
        if regional == locale:
            paths.append(arb_path(base))
    for path in paths:
        if os.path.exists(path):
            for key, value in messages(load_json(path)).items():
                if isinstance(value, str):
                    try:
                        for t in texts(parse(value)):
                            out |= set(t)
                    except IcuError:
                        out |= set(value)
    cap = captions_path(slug)
    if os.path.exists(cap):
        for key, value in load_json(cap).items():
            if not key.startswith('@@') and isinstance(value, str):
                out |= set(value)
    if include_seeds:
        out |= seed_chars(slug, cfg)
    return {c for c in out if c not in '\n\t\r'}
