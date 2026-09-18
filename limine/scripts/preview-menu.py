#!/usr/bin/env python3
"""Approximate 1920x1080 Limine menu mockup for previewing the autotheme.

This is a development tool: it renders the packed Limine font at the same
scale Limine will use (8x16 @ 2x2) over a wallpaper with the same translucent
background, so we can sanity-check contrast before rebooting.

The palette comes from ~/.cache/autotheme.json (same mapping as
limine-deploy); --bg/--fg/--muted/--accent override individual roles.

Usage:
  preview-menu.py --wallpaper w1.jpg --font font.f16 --out preview.png
"""

import argparse
import json
import os
from PIL import Image

FALLBACK = dict(
    bg="0a0a0c",
    fg="e6e6e6",
    muted="8b8f98",
    sel_bg="3a3f4b",
    sel_fg="ffffff",
    accent="ffffff",
)


def strip(hexcode):
    h = hexcode.lstrip("#")
    if len(h) == 8:
        h = h[2:]
    if len(h) != 6:
        raise ValueError(hexcode)
    return h.lower()


def dark_text_reads_better(rrggbb):
    r, g, b = (int(rrggbb[i : i + 2], 16) for i in (0, 2, 4))
    return (299 * r + 587 * g + 114 * b) > 600 * 255


def palette_from_autotheme(path):
    pal = dict(FALLBACK)
    try:
        with open(path) as f:
            data = json.load(f)
        pal["bg"] = strip(data["bgSolid"])
        pal["fg"] = strip(data["fg"])
        pal["muted"] = strip(data["muted"])
        pal["accent"] = strip(data["accent"])
        pal["sel_bg"] = pal["accent"]
        pal["sel_fg"] = pal["bg"] if dark_text_reads_better(pal["accent"]) else "ffffff"
    except (OSError, ValueError, KeyError) as e:
        print(f"warning: {path}: {e}, using fallback palette")
    return pal


SCALE = 2  # term_font_scale: 2x2
MARGIN = 48
BG_ALPHA = 0x66  # term_background transparency byte
ENTRIES = ["Arch Linux", "Windows"]
SELECTED = 0


def hx(s):
    return tuple(int(s[i : i + 2], 16) for i in (0, 2, 4))


def draw_glyph(img, fontdata, idx, x, y, color):
    px = img.load()
    h = len(fontdata) // 256
    glyph = fontdata[(idx % 256) * h : (idx % 256 + 1) * h]
    for gy in range(h):
        row = glyph[gy]
        for gx in range(8):
            if row & (1 << (7 - gx)):
                for sy in range(SCALE):
                    for sx in range(SCALE):
                        xx, yy = x + gx * SCALE + sx, y + gy * SCALE + sy
                        if 0 <= xx < img.width and 0 <= yy < img.height:
                            px[xx, yy] = color
    return x + 8 * SCALE


def draw_text(img, fontdata, text, x, y, color):
    for ch in text:
        draw_glyph(img, fontdata, ord(ch) & 0xFF, x, y, color)
        x += 8 * SCALE
    return x


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--autotheme", default=os.path.expanduser("~/.cache/autotheme.json")
    )
    ap.add_argument("--wallpaper", required=True)
    ap.add_argument("--font", required=True)
    ap.add_argument("--out", required=True)
    for role in ("bg", "fg", "muted", "sel_bg", "sel_fg", "accent"):
        ap.add_argument("--" + role, default=None)
    args = ap.parse_args()

    pal = palette_from_autotheme(args.autotheme)
    for role in ("bg", "fg", "muted", "sel_bg", "sel_fg", "accent"):
        override = getattr(args, role)
        if override:
            pal[role] = strip(override)
    fontdata = open(args.font, "rb").read()

    # wallpaper, cover-cropped
    wall = Image.open(args.wallpaper).convert("RGB")
    ratio = max(1920 / wall.width, 1080 / wall.height)
    wall = wall.resize(
        (round(wall.width * ratio), round(wall.height * ratio)), Image.LANCZOS
    )
    left = (wall.width - 1920) // 2
    top = (wall.height - 1080) // 2
    img = wall.crop((left, top, left + 1920, top + 1080)).convert("RGBA")

    # translucent terminal background inset by term_margin
    overlay = Image.new(
        "RGBA",
        (1920 - 2 * MARGIN, 1080 - 2 * MARGIN),
        hx(pal["bg"]) + (255 - BG_ALPHA,),
    )
    img.alpha_composite(overlay, (MARGIN, MARGIN))
    img = img.convert("RGB")

    # branding (top center)
    bw = len("Arch Linux") * 8 * SCALE
    draw_text(img, fontdata, "Arch Linux", (1920 - bw) // 2, 80, hx(pal["accent"]))

    # entries
    row_h = 16 * SCALE + 24
    y = 400
    for i, entry in enumerate(ENTRIES):
        if i == SELECTED:
            bar = Image.new("RGB", (1920 - 2 * MARGIN, row_h), hx(pal["sel_bg"]))
            img.paste(bar, (MARGIN, y - 8))
            draw_text(img, fontdata, entry, MARGIN + 64, y, hx(pal["sel_fg"]))
        else:
            draw_text(img, fontdata, entry, MARGIN + 64, y, hx(pal["fg"]))
        y += row_h

    img.save(args.out)
    print(f"preview: {args.out}")


if __name__ == "__main__":
    main()
