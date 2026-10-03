#!/usr/bin/env python3
"""Export Beakbound's approved artwork to mobile icons (requires Pillow)."""

import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
MASTER = ROOT / "assets/branding/beakbound-master.png"


def main():
    with Image.open(MASTER) as image:
        source = image.convert("RGBA")
        if source.width != source.height or source.getextrema()[3] != (255, 255):
            raise ValueError("The approved master must be a fully opaque square.")

        def export(path, size, *, alpha=False):
            output = source.resize((size, size), Image.Resampling.LANCZOS)
            output = output.convert("RGBA" if alpha else "RGB")
            destination = ROOT / path
            destination.parent.mkdir(parents=True, exist_ok=True)
            output.save(destination, optimize=True)

        export("assets/images/beakbound-logo.png", 512)
        store = "assets/branding/beakbound-play-store-512.png"
        export(store, 512, alpha=True)
        if (ROOT / store).stat().st_size > 1024 * 1024:
            raise ValueError("Play Store icon exceeds 1 MB.")

        for density, size in {
            "mdpi": 48,
            "hdpi": 72,
            "xhdpi": 96,
            "xxhdpi": 144,
            "xxxhdpi": 192,
        }.items():
            export(f"android/app/src/main/res/mipmap-{density}/ic_launcher.png", size)

        catalog = Path("ios/Runner/Assets.xcassets/AppIcon.appiconset")
        entries = json.loads((ROOT / catalog / "Contents.json").read_text())["images"]
        sizes = {
            entry["filename"]: round(
                float(entry["size"].split("x")[0]) * float(entry["scale"].removesuffix("x"))
            )
            for entry in entries
        }
        for filename, size in sizes.items():
            export(catalog / filename, size)
        print(f"Exported menu + store artwork, 5 Android icons, {len(sizes)} iOS icons.")


if __name__ == "__main__":
    main()
