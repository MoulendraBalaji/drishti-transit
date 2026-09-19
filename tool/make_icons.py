"""Generate the Drishti Transit app icons.

Renders a single master design (night-navy gradient tile, signal-teal iris,
saffron pupil) and writes:

  * Android legacy launcher icons (mipmap-mdpi..xxxhdpi ic_launcher.png)
  * iOS AppIcon.appiconset (all sizes in Contents.json)

Run from the repo root:  python tool/make_icons.py
"""

import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
S = 4096  # master/supersample size

# ---- palette (mirrors lib/app/palette.dart) ----
INK_TOP = (17, 27, 51)      # 0x101B33
INK_BOT = (7, 11, 20)       # 0x070B14
GLOW = (21, 43, 76)
TEAL = (52, 226, 180)       # 0x34E2B4 signal
SAFFRON = (233, 162, 59)    # 0xE9A23B brand
SAFFRON_LIGHT = (248, 208, 122)
FLEET = (63, 106, 150)


def gradient() -> Image.Image:
    xx, yy = np.meshgrid(np.linspace(0.0, 1.0, S), np.linspace(0.0, 1.0, S))
    w = (xx + yy) / 2.0
    r = INK_TOP[0] + (INK_BOT[0] - INK_TOP[0]) * w
    g = INK_TOP[1] + (INK_BOT[1] - INK_TOP[1]) * w
    b = INK_TOP[2] + (INK_BOT[2] - INK_TOP[2]) * w
    arr = np.stack([r, g, b], axis=-1).astype(np.uint8)
    return Image.fromarray(arr)


def render_master() -> Image.Image:
    base = gradient().convert("RGBA")

    glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([0.22 * S, 0.22 * S, 0.78 * S, 0.78 * S], fill=GLOW + (170,))
    base = Image.alpha_composite(base, glow.filter(ImageFilter.GaussianBlur(180)))

    d = ImageDraw.Draw(base)
    cx = cy = 0.5 * S
    F = lambda v: v * S  # noqa: E731 -- unit fraction -> pixels

    # ---- iris: outer signal ring ----
    d.ellipse([cx - F(0.205), cy - F(0.205), cx + F(0.205), cy + F(0.205)],
              outline=TEAL + (255,), width=int(F(0.032)))

    # ---- eyelids: two short arcs just outside the ring ----
    lid = TEAL + (135,)
    d.arc([cx - F(0.235), cy - F(0.235), cx + F(0.235), cy + F(0.235)],
          200, 340, fill=lid, width=int(F(0.014)))
    d.arc([cx - F(0.235), cy - F(0.235), cx + F(0.235), cy + F(0.235)],
          20, 160, fill=lid, width=int(F(0.014)))

    # ---- pupil: saffron with offset light glint ----
    d.ellipse([cx - F(0.062), cy - F(0.062), cx + F(0.062), cy + F(0.062)],
              fill=SAFFRON + (255,))
    d.ellipse([cx - F(0.062) + F(-0.014), cy - F(0.062) + F(-0.014),
               cx + F(0.062) + F(-0.014), cy + F(0.062) + F(-0.014)],
              fill=SAFFRON_LIGHT + (235,))

    # ---- fleet dots: four quiet stations on the diagonals ----
    for a in (45, 135, 225, 315):
        ax = cx + 0.33 * S * math.cos(math.radians(a))
        ay = cy + 0.33 * S * math.sin(math.radians(a))
        d.ellipse([ax - F(0.016), ay - F(0.016), ax + F(0.016), ay + F(0.016)],
                  fill=FLEET + (120,))

    return base


def rounded_mask(size: int, radius_frac: float) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, size - 1, size - 1], radius=int(size * radius_frac), fill=255)
    return mask


def emit(size: int, path: str, rounded: float | None = None) -> None:
    img = render_master().resize((size, size), Image.LANCZOS)
    if rounded:
        img.putalpha(rounded_mask(size, rounded))
    # App stores reject alpha; flatten onto the tile color when opaque.
    flat = Image.new("RGB", (size, size), INK_BOT)
    flat.paste(img, mask=img.split()[-1])
    os.makedirs(os.path.dirname(path), exist_ok=True)
    flat.save(path)
    print(f"wrote {size:4d}  {os.path.relpath(path, REPO)}")


def main() -> None:
    android = [
        (48,  "android/app/src/main/res/mipmap-mdpi/ic_launcher.png"),
        (72,  "android/app/src/main/res/mipmap-hdpi/ic_launcher.png"),
        (96,  "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png"),
        (144, "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png"),
        (192, "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"),
    ]
    ios = [
        (20,  "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png"),
        (40,  "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png"),
        (60,  "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png"),
        (29,  "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png"),
        (58,  "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png"),
        (87,  "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png"),
        (40,  "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png"),
        (80,  "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png"),
        (120, "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png"),
        (120, "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png"),
        (180, "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png"),
        (76,  "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png"),
        (152, "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png"),
        (167, "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png"),
        (1024, "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png"),
    ]
    for size, rel in android:
        emit(size, os.path.join(REPO, rel))
    for size, rel in ios:
        emit(size, os.path.join(REPO, rel), rounded=0.2245)
    # Preview strip for eyeballing the result.
    preview = [
        (256, "tool/_preview.png", None),
        (48, "tool/_preview_small.png", None),
    ]
    for size, rel, rr in preview:
        emit(size, os.path.join(REPO, rel), rounded=rr)
    print("done")


if __name__ == "__main__":
    sys.exit(main())