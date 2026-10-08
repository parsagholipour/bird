#!/usr/bin/env python3
"""Choose which voice packs a dev build carries. Release builds carry all.

`flutter run` and `flutter build apk` put every voice pack listed in
pubspec.yaml into the APK: all 11 add ~229 MB. For day-to-day builds list
only the packs you want, and restore all of them before a Play build:

    python3 tool/l10n/dev_voice_packs.py --only es_419,de   # just these packs
    python3 tool/l10n/dev_voice_packs.py --none             # no pack at all
    python3 tool/l10n/dev_voice_packs.py --all              # every pack (release state)
    python3 tool/l10n/dev_voice_packs.py --status           # what is listed now
    python3 tool/l10n/dev_voice_packs.py --check            # exit 1 unless every pack is listed

Slugs: es_419 pt_br id fr de ja ko tr zh_hant ru ar (BCP-47 tags such as
es-419 or zh-Hant work too).

It rewrites only the two generated blocks between `voice-packs:begin` and
`voice-packs:end`: the deferred components in pubspec.yaml and the feature
module includes in android/settings.gradle.kts. Both must name the same
packs, because Flutter hands every pubspec component to Gradle and Gradle
builds every included module. A subset is marked in both blocks with a
`voice-packs:dev-subset` comment, so `git diff` shows it too.

Guards against shipping a subset:
- `flutter build appbundle` stops in android/app/build.gradle.kts unless
  every android/voice_<slug> module is a deferred component;
- test/voice_pack_wiring_test.dart fails while a subset is listed.
`--all` writes exactly what `prepare_localized_voices.py --wire` writes;
`--wire` (run after every mastering) restores all packs as well.

In a dev build, a language whose pack is left out behaves like a phone that
has not downloaded it: the game asks Play for the pack, which fails outside
Play (the Settings badge shows "failed"), and plays the English voices
under the localized captions.
"""
import argparse
from pathlib import Path
import re
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
import prepare_localized_voices as packs  # noqa: E402

MARK = 'voice-packs:dev-subset'
COMPONENT = re.compile(r'^    - name: voice_(\w+)$', re.M)
INCLUDE = re.compile(r'^include\(":voice_(\w+)"\)$', re.M)


class Files:
    """pubspec.yaml and android/settings.gradle.kts under a project root."""

    def __init__(self, root):
        self.root = root
        self.pubspec = root / 'pubspec.yaml'
        self.settings = root / 'android' / 'settings.gradle.kts'
        self.packs = root / 'assets' / 'voice'

    def block(self, path, begin, end):
        text = path.read_text()
        a, b = text.find(begin), text.find(end)
        if a < 0 or b < a:
            raise SystemExit(f'{path}: the {packs.BEGIN} ... {packs.END} markers are missing')
        return text[text.index('\n', a) + 1:b]

    def listed(self):
        """(pubspec slugs, settings slugs, is a subset marked)."""
        spec = self.block(self.pubspec, f'# {packs.BEGIN}', f'  # {packs.END}')
        gradle = self.block(self.settings, f'// {packs.BEGIN}', f'// {packs.END}')
        return (COMPONENT.findall(spec), INCLUDE.findall(gradle),
                MARK in spec or MARK in gradle)

    def write(self, slugs):
        subset = slugs != list(packs.LANGUAGES)
        names = ','.join(slugs) or 'none'
        note = ('NOT FOR RELEASE: run python3 tool/l10n/dev_voice_packs.py --all '
                'before flutter build appbundle')
        spec = packs.pubspec_components(slugs, self.packs)
        gradle = packs.settings_includes(slugs)
        if subset:
            spec = f'  # {MARK} {names} ({note})\n' + spec
            gradle = f'// {MARK} {names} ({note})\n' + gradle
        for path, begin, end, body in [
            (self.pubspec, f'# {packs.BEGIN}', f'  # {packs.END}', spec),
            (self.settings, f'// {packs.BEGIN}', f'// {packs.END}', gradle),
        ]:
            text = path.read_text()
            new = packs.replace_block(text, begin, end, body, path)
            if new != text:
                path.write_text(new)


def slugs_of(given):
    """Canonical slugs, in the tool's language order, from `es_419,de` or tags."""
    wanted = set()
    for item in re.split(r'[,\s]+', given.strip()):
        if not item:
            continue
        slug = item.lower().replace('-', '_')
        if slug not in packs.LANGUAGES:
            raise SystemExit(f'unknown voice pack {item!r}; known: {" ".join(packs.LANGUAGES)}')
        wanted.add(slug)
    if not wanted:
        raise SystemExit('--only needs at least one pack (or use --none)')
    return [slug for slug in packs.LANGUAGES if slug in wanted]


def describe(files):
    spec, gradle, marked = files.listed()
    every = list(packs.LANGUAGES)
    if spec != gradle:
        return False, (f'pubspec.yaml lists {spec or "no packs"} but '
                       f'android/settings.gradle.kts includes {gradle or "no modules"}: '
                       f'run --all, or --only again')
    if spec == every and not marked:
        return True, f'all {len(every)} voice packs listed (release state)'
    missing = [slug for slug in every if slug not in spec]
    return False, (f'DEV SUBSET: {len(spec)} of {len(every)} voice packs listed '
                   f'({", ".join(spec) or "none"}); missing {", ".join(missing) or "none"}. '
                   f'Run python3 tool/l10n/dev_voice_packs.py --all before a release build.')


def main():
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    action = parser.add_mutually_exclusive_group(required=True)
    action.add_argument('--only', metavar='SLUGS', help='comma-separated packs to list, e.g. es_419,de')
    action.add_argument('--none', action='store_true', help='list no pack')
    action.add_argument('--all', action='store_true', help='list every pack (release state)')
    action.add_argument('--status', action='store_true', help='print what is listed')
    action.add_argument('--check', action='store_true', help='exit 1 unless every pack is listed')
    parser.add_argument('--root', help=argparse.SUPPRESS)  # a project copy (tests)
    args = parser.parse_args()
    files = Files(Path(args.root).resolve() if args.root else packs.ROOT)
    if args.only is not None or args.none or args.all:
        files.write(list(packs.LANGUAGES) if args.all
                    else [] if args.none else slugs_of(args.only))
    ok, text = describe(files)
    print(text)
    if args.check and not ok:
        sys.exit(1)


if __name__ == '__main__':
    main()
