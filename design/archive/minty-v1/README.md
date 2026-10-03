# Minty v1 (backup, 2026-10-03)

The original Minty artwork, kept before the 2026-10-03 redesign.

- `minty.svg`: the puppet source (was `design/minty.svg`).
- `trail-minty.svg`: the leaf trail source (was `design/trail-minty.svg`).
- `minty-portrait.png`: the menu portrait (was `assets/images/minty.png`).

To restore: copy `minty.svg` and `trail-minty.svg` back into `design/`, run
`python3 tool/generate_bird_paths.py`, then re-export the portraits with
`flutter test test/bird_portrait_export_test.dart --dart-define=EXPORT_BIRD_PORTRAITS=true`.
The old version is also in git history (`git show 0e494c5:design/minty.svg`).
