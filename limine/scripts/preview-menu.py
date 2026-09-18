#!/usr/bin/env python3
"""Approximate 1920x1080 Limine menu mockup for previewing a theme.

This is a development tool: it renders the packed Limine font at the same
scale Limine will use (8x16 @ 2x2) over a wallpaper with the same translucent
background, so we can sanity-check contrast before rebooting.

Usage:
  preview-menu.py --theme obsidian --wallpaper w1.jpg --font font.f16 --out preview.png
"""

import argparse
import os
from PIL import Image

PALETTES = {
    "obsidian": dict(
        bg="0a0a0c",
        fg="e6e6e6",
        muted="8b8f98",
        sel_bg="3a3f4b",
        sel_fg="ffffff",
        accent="ffffff",
    ),
    "crimson": dict(
        bg="08080a",
        fg="e8e8e8",
        muted="8a8a8a",
        sel_bg="ff2a3d",
        sel_fg="ffffff",
        accent="ff2a3d",
    ),
    "aether": dict(
        bg="141820",
        fg="eaf2ff",
        muted="9aa6b2",
        sel_bg="7aa2f7",
        sel_fg="ffffff",
        accent="7aa2f7",
    ),
    "ember": dict(
        bg="140e08",
        fg="e6d3b3",
        muted="a89984",
        sel_bg="e0af68",
        sel_fg="140e08",
        accent="e0af68",
    ),
    "drift": dict(
        bg="12141a",
        fg="d6dbe3",
        muted="8f96a3",
        sel_bg="c792ea",
        sel_fg="12141a",
        accent="7aa2a9",
    ),
    "windows": dict(
        bg="202226",
        fg="e6e6e6",
        muted="b3b3b3",
        sel_bg="283f4d",
        sel_fg="e6e6e6",
        accent="4cc2ff",
    ),
}

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
    ap.add_argument("--theme", default="obsidian")
    ap.add_argument("--wallpaper", required=True)
    ap.add_argument("--font", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    pal = PALETTES.get(args.theme, PALETTES["obsidian"])
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
