#!/usr/bin/env python3
"""Find hard-coded, probably user-facing English string literals in lib/.

A heuristic inventory for the localization extraction builders (see
l10n-ws/MASTER-PLAN.md). It tokenizes Dart (comments, raw/triple strings,
nested interpolation), drops literals that are clearly not shown to players
(imports, asset paths, ids, debug/log/assert/throw text, keys, font names)
and prints what is left.

  python3 tool/l10n/find_strings.py                 # per-file counts
  python3 tool/l10n/find_strings.py -v lib/ui/x.dart # every candidate
  python3 tool/l10n/find_strings.py --json          # machine-readable
  python3 tool/l10n/find_strings.py --slice S3 -v    # one builder's files
  python3 tool/l10n/find_strings.py --slices         # per-slice totals; fails
                                                     # on files in no slice

A file is "done" when it reports 0: every player-facing literal is
extracted, or marked `// l10n-ignore` (same line or the line above) because
it is not player-facing, or the file carries a `// l10n-english-twin`
comment because its literals are the domain's English twins of ARB keys
(see MASTER-PLAN.md, "Domain data"). Interpolations are shown as `{}`.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Files that never hold player-facing text, or hold it in a form handled
# elsewhere (generated tables, voice-clip tables, vector paths).
SKIP_FILES = {
    'lib/data/progress_repository.g.dart',
    'lib/tracking/tracking_api.g.dart',
    'lib/game/campaign_voice_clips.dart',
    'lib/game/flight_voice_clips.dart',
    'lib/game/bird_vector_paths.dart',
}
SKIP_DIRS = ('lib/l10n/',)

# Calls whose string arguments are not shown to players.
NON_UI_CALL = re.compile(
    r'(debugPrint|print|assert|log|developer\.log|StateError|ArgumentError|'
    r'UnimplementedError|UnsupportedError|recordDiagnostic|FormatException|Exception|'
    r'RangeError|AssertionError|FlutterError|ValueKey|Key|ObjectKey|'
    r'GlobalKey|PageStorageKey|RegExp|Uri\.parse|Uri|AssetSource|'
    r'Image\.asset|AssetImage|rootBundle\.load|rootBundle\.loadString|'
    r'loadString|load|debugLabel|restorationId|MethodChannel|EventChannel|'
    r'BasicMessageChannel|FontLoader|pragma|Symbol|int\.parse|double\.parse|'
    r'DateTime\.parse|Duration|Offset|Color|fromEnvironment|'
    r'bool\.fromEnvironment|String\.fromEnvironment|int\.fromEnvironment|'
    r'go|push|pushReplacement|replace|goNamed|startsWith|endsWith|contains|'
    r'split|replaceAll|replaceFirst|indexOf|lastIndexOf|substring|join|'
    r'padLeft|padRight|containsKey|remove|getString|setString|getBool|'
    r'setBool|customStatement|tableName|named|byName|fromName|'
    r'queryParameters|pathParameters|tryParse)\s*\($')
NON_UI_PREFIX = re.compile(
    r'(?:^|[^\w])(throw|assert|debugPrint|print|debugLabel\s*:|'
    r'restorationId\s*:|fontFamily\s*:|package\s*:|semanticsIdentifier\s*:|'
    r'path\s*:|route\s*:|asset\s*:|id\s*:|name\s*:\s*\'[a-z])')
ASSETISH = re.compile(
    r'(^assets/|^audio/|^images/|^fonts/|\.(png|jpg|jpeg|webp|svg|ogg|mp3|'
    r'wav|json|ttf|otf|riv|txt|db|sqlite|log|dart|html)$|^package:|^dart:|'
    r'^https?://|^/[a-z])', re.I)
IDENTISH = re.compile(r'^[a-z0-9_\-.:/#@+=%&?<>\[\]{}()|*,;~^!$\\\s]*$')
CAMEL = re.compile(r'^[a-z][A-Za-z0-9_]*$')
HEX = re.compile(r'^(0x)?[0-9a-fA-F]+$')
SVG_PATH = re.compile(r'^(?=.*\d)[MLCQZHVASTmlcqzhvast\d\s.,\-+eE]+$')
SQL = re.compile(r'^(SELECT|UPDATE|INSERT|DELETE|CREATE|ALTER|PRAGMA)\b|'
                 r'^[a-z_]+ (IS|=|IN) |\?\s*$')
DOTTED = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*([.+][A-Za-z_][A-Za-z0-9_]*)+$')
FONT_NAMES = {'Fredoka', 'Nunito', 'MaterialIcons', 'CupertinoIcons',
              'Roboto', 'monospace'}
IGNORE_MARK = 'l10n-ignore'


def tokenize(src: str):
    """(line, text, start, end) for each top-level string literal.

    Adjacent literals are joined into one; interpolations become `{}`.
    """
    i, n, line = 0, len(src), 1
    out = []

    def read_string(i, line):
        raw = False
        if src[i] in 'rR':
            raw = True
            i += 1
        q = src[i]
        triple = src[i:i + 3] == q * 3
        i += 3 if triple else 1
        buf = []
        start_line = line
        while i < n:
            ch = src[i]
            if ch == '\n':
                line += 1
                if not triple:  # unterminated; bail
                    break
            if triple and src[i:i + 3] == q * 3:
                return i + 3, line, ''.join(buf), start_line
            if not triple and ch == q:
                return i + 1, line, ''.join(buf), start_line
            if ch == '\\' and not raw:
                nxt = src[i + 1] if i + 1 < n else ''
                buf.append({'n': '\n', 't': '\t', "'": "'", '"': '"',
                            '$': '$', '\\': '\\'}.get(nxt, nxt))
                i += 2
                continue
            if ch == '$' and not raw:
                if i + 1 < n and src[i + 1] == '{':
                    depth, j = 1, i + 2
                    while j < n and depth:
                        c2 = src[j]
                        if c2 == '\n':
                            line += 1
                        if c2 in '\'"' or (c2 in 'rR' and j + 1 < n and src[j + 1] in '\'"'):
                            j, line, _, _ = read_string(j, line)
                            continue
                        if c2 == '{':
                            depth += 1
                        elif c2 == '}':
                            depth -= 1
                        j += 1
                    buf.append('{}')
                    i = j
                    continue
                m = re.match(r'\$[A-Za-z_][A-Za-z0-9_]*', src[i:])
                if m:
                    buf.append('{}')
                    i += len(m.group(0))
                    continue
            buf.append(ch)
            i += 1
        return i, line, ''.join(buf), start_line

    while i < n:
        ch = src[i]
        if ch == '\n':
            line += 1
            i += 1
            continue
        if src.startswith('//', i):
            j = src.find('\n', i)
            i = n if j < 0 else j
            continue
        if src.startswith('/*', i):
            depth, j = 1, i + 2
            while j < n and depth:
                if src.startswith('/*', j):
                    depth += 1
                    j += 2
                elif src.startswith('*/', j):
                    depth -= 1
                    j += 2
                else:
                    if src[j] == '\n':
                        line += 1
                    j += 1
            i = j
            continue
        if ch in '\'"' or (ch in 'rR' and i + 1 < n and src[i + 1] in '\'"'
                           and (i == 0 or not (src[i - 1].isalnum() or src[i - 1] == '_'))):
            start = i
            i, line2, text, start_line = read_string(i, line)
            # Adjacent literals ('a' 'b') are one message.
            if out and not src[out[-1][3]:start].strip():
                prev = out.pop()
                out.append((prev[0], prev[1] + text, prev[2], i))
            else:
                out.append((start_line, text, start, i))
            line = line2
            continue
        i += 1
    return out


def user_facing(text: str, before: str, line_src: str, prev_src: str) -> bool:
    t = text.strip()
    if not t or not re.search(r'[A-Za-z]', t):
        return False
    if IGNORE_MARK in line_src or IGNORE_MARK in prev_src:
        return False
    stripped = line_src.lstrip()
    if stripped.startswith(('import ', 'export ', 'part ', 'library ', '@')):
        return False
    if (t in FONT_NAMES or ASSETISH.search(t) or HEX.match(t)
            or SVG_PATH.match(t) or DOTTED.match(t) or SQL.match(t)
            or len(t) == 1):
        return False
    if CAMEL.match(t) or IDENTISH.match(t):
        # lower-case single tokens, ids, paths, '1-3', 'ui_toggle', '{}-{}'
        return False
    # Mostly placeholders and punctuation ('{}×', '{} / {}')
    letters = re.sub(r'\{\}', '', t)
    if not re.search(r'[A-Za-z]{2,}', letters) and not re.search(r'\b[A-Z]\b', letters):
        return False
    tail = before.rstrip()
    if NON_UI_CALL.search(tail):
        return False
    if NON_UI_PREFIX.search(stripped.split(text[:8])[0] if text[:8] else stripped):
        return False
    # snake/dot ids with an uppercase letter are rare; keep everything else
    return True


TWIN_MARK = 'l10n-english-twin'


def scan_file(rel: str):
    with open(os.path.join(ROOT, rel), encoding='utf-8') as f:
        src = f.read()
    # A domain file whose literals are only the English twins of ARB keys
    # (shown through lib/l10n/text/*, kept equal by a parity test).
    if TWIN_MARK in src:
        return []
    lines = src.split('\n')
    found = []
    for line, text, start, _ in tokenize(src):
        line_start = src.rfind('\n', 0, start) + 1
        before = src[max(line_start - 200, 0):start]
        line_src = lines[line - 1] if line - 1 < len(lines) else ''
        prev_src = lines[line - 2] if line >= 2 else ''
        if user_facing(text, before, line_src, prev_src):
            found.append((line, text))
    return found


def lib_files():
    for base, _, files in os.walk(os.path.join(ROOT, 'lib')):
        for name in files:
            if not name.endswith('.dart'):
                continue
            rel = os.path.relpath(os.path.join(base, name), ROOT)
            if rel in SKIP_FILES or rel.startswith(SKIP_DIRS):
                continue
            yield rel


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('files', nargs='*', help='lib/ files (default: all)')
    ap.add_argument('-v', '--verbose', action='store_true')
    ap.add_argument('--json', action='store_true')
    ap.add_argument('--min', type=int, default=1, help='hide files below N')
    ap.add_argument('--slice', help='only the files of this slice (tool/l10n/slices.json)')
    ap.add_argument('--slices', action='store_true', help='totals per slice')
    args = ap.parse_args()
    slices = json.load(open(os.path.join(ROOT, 'tool', 'l10n', 'slices.json'), encoding='utf-8'))
    if args.slices:
        owner = {f: 'done' for f in slices['done']}
        for name, sl in slices['slices'].items():
            for f in sl['files']:
                owner[f] = name
        totals = {}
        orphans = []
        for rel in sorted(lib_files()):
            n = len(scan_file(rel))
            if not n:
                continue
            if rel not in owner:
                orphans.append((rel, n))
            totals[owner.get(rel, '?')] = totals.get(owner.get(rel, '?'), 0) + n
        for name, sl in slices['slices'].items():
            print(f'{totals.get(name, 0):5d}  {name}  {sl["title"]}')
        print(f'{totals.get("done", 0):5d}  done (r0)')
        for rel, n in orphans:
            print(f'error: {rel} ({n}) is in no slice: add it to tool/l10n/slices.json')
        sys.exit(1 if orphans else 0)
    files = args.files or (slices['slices'][args.slice]['files'] if args.slice
                           else sorted(lib_files()))
    report = {}
    for rel in files:
        rel = os.path.relpath(os.path.abspath(rel), ROOT) if os.path.exists(rel) else rel
        hits = scan_file(rel)
        if len(hits) >= args.min:
            report[rel] = hits
    if args.json:
        json.dump({k: [{'line': l, 'text': t} for l, t in v] for k, v in report.items()},
                  sys.stdout, ensure_ascii=False, indent=1)
        return
    total = 0
    for rel, hits in sorted(report.items(), key=lambda kv: -len(kv[1])):
        total += len(hits)
        print(f'{len(hits):5d}  {rel}')
        if args.verbose:
            for l, t in hits:
                print(f'        {l:5d}: {t}')
    print(f'{total:5d}  total in {len(report)} files')


if __name__ == '__main__':
    main()
