#!/usr/bin/env python3
"""Size the Flutter-rendered launch lockup for Android and iOS (Pillow)."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


def main():
    for name, size in {
        "launch-lockup": (320, 284),
        "launch-icon": (288, 288),
        "launch-wordmark": (200, 80),
    }.items():
        with Image.open(ROOT / f"assets/branding/{name}.png") as image:
            for density, scale in {
                "mdpi": 1,
                "hdpi": 1.5,
                "xhdpi": 2,
                "xxhdpi": 3,
                "xxxhdpi": 4,
            }.items():
                target = ROOT / f"android/app/src/main/res/drawable-{density}/{name.replace('-', '_')}.png"
                target.parent.mkdir(parents=True, exist_ok=True)
                image.resize(
                    tuple(round(n * scale) for n in size), Image.Resampling.LANCZOS
                ).save(target, optimize=True)
            if name == "launch-lockup":
                for scale in (1, 2, 3):
                    suffix = "" if scale == 1 else f"@{scale}x"
                    target = ROOT / f"ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage{suffix}.png"
                    image.resize(
                        tuple(n * scale for n in size), Image.Resampling.LANCZOS
                    ).save(target, optimize=True)
    print("Exported 15 Android splash assets and 3 iOS launch images.")


if __name__ == "__main__":
    main()
