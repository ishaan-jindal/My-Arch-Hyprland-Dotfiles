#!/usr/bin/env python3
"""Generate a Limine-compatible CP437 8xN bitmap font from a TTF.

Limine's `term_font` format:
  - exactly 256 glyphs, glyph i = CP437 byte i
  - each glyph is 8 pixels wide (1 byte per row, MSB = leftmost pixel)
  - glyph height = `term_font_size` (default 8x16), so file size = 256 * height

Also renders preview sheets so we can judge legibility before deploying.

Usage:
  generate-font.py [--size 13] [--height 16] [--threshold 100] [--ss 4] [--name ...]
"""

import argparse
import os
from PIL import Image, ImageDraw, ImageFont

# Standard CP437 glyphs for the control range (0x00-0x1F) and 0x7F
CP437_CONTROL = {
    0x00: " ",
    0x01: "\u263a",
    0x02: "\u263b",
    0x03: "\u2665",
    0x04: "\u2666",
    0x05: "\u2663",
    0x06: "\u2660",
    0x07: "\u2022",
    0x08: "\u25d8",
    0x09: "\u25cb",
    0x0A: "\u25d9",
    0x0B: "\u2642",
    0x0C: "\u2640",
    0x0D: "\u266a",
    0x0E: "\u266b",
    0x0F: "\u263c",
    0x10: "\u25ba",
    0x11: "\u25c4",
    0x12: "\u2195",
    0x13: "\u203c",
    0x14: "\u00b6",
    0x15: "\u00a7",
    0x16: "\u25ac",
    0x17: "\u21a8",
    0x18: "\u2191",
    0x19: "\u2193",
    0x1A: "\u2192",
    0x1B: "\u2190",
    0x1C: "\u221f",
    0x1D: "\u2194",
    0x1E: "\u25b2",
    0x1F: "\u25bc",
    0x7F: "\u2302",
}

FALLBACK_CHAIN = [
    "/usr/share/fonts/TTF/JetBrainsMonoNerdFontMono-Regular.ttf",
    "/usr/share/fonts/TTF/JetBrainsMonoNerdFont-Regular.ttf",
    "/usr/share/fonts/noto/NotoSansMono-Regular.ttf",
    "/usr/share/fonts/noto/NotoSansSymbols2-Regular.ttf",
]

# A codepoint guaranteed not to exist, used to learn what ".notdef" looks like
NOTDEF_CP = "\U000f0ff0"


def cp437_char(b: int) -> str:
    if b in CP437_CONTROL:
        return CP437_CONTROL[b]
    if b < 0x80:
        return chr(b)
    return bytes([b]).decode("cp437")


CP437_REVERSE = {}
for _b in range(32, 127):
    CP437_REVERSE[chr(_b)] = _b
for _b in list(range(0x20)) + list(range(0x7F, 0x100)):
    CP437_REVERSE.setdefault(cp437_char(_b), _b)


def pack_bitmap(img: Image.Image) -> bytes:
    """img: 8xH 1-bit image -> H bytes, one per row, MSB leftmost."""
    w, h = img.size
    assert w == 8
    return bytes(
        sum(1 << (7 - x) for x in range(w) if img.getpixel((x, y))) for y in range(h)
    )


class FontRaster:
    def __init__(self, paths, px_size, cell_w, cell_h, ss, threshold):
        self.cell_w, self.cell_h = cell_w, cell_h
        self.ss = ss
        self.threshold = threshold
        self.fonts = [
            ImageFont.truetype(p, px_size * ss, layout_engine=ImageFont.Layout.BASIC)
            for p in paths
        ]
        self.blank = Image.new("1", (cell_w, cell_h), 0)
        # learn notdef bitmaps per font (thresholded, same repr as render())
        self.notdefs = [
            self.to_bits(self._render_raw(f, NOTDEF_CP)) for f in self.fonts
        ]

    def to_bits(self, gray):
        th = gray.point(lambda v: 255 if v >= self.threshold else 0)
        return th.convert("1")  # threshold at 128

    def _render_raw(self, font, ch):
        ss = self.ss
        W, H = self.cell_w * ss, self.cell_h * ss
        img = Image.new("L", (W, H), 0)
        d = ImageDraw.Draw(img)
        ascent, descent = font.getmetrics()
        # put descenders at the bottom of the cell; keeps cap height visible
        baseline = H - descent
        adv = round(font.getlength("M"))
        x = max(0, (W - adv) // 2)
        d.text((x, baseline), ch, font=font, anchor="ls", fill=255)
        if ss > 1:
            img = img.resize((self.cell_w, self.cell_h), Image.LANCZOS)
        return img

    def render(self, ch):
        if ch == " ":
            return self.blank
        for font, nd in zip(self.fonts, self.notdefs):
            raw = self._render_raw(font, ch)
            bits = self.to_bits(raw)
            if self._same(bits, nd):
                continue  # missing glyph -> try next font
            return bits
        return self.blank

    @staticmethod
    def _same(a, b):
        return a.tobytes() == b.tobytes()


def build_font(raster, path):
    data = bytearray()
    for b in range(256):
        glyph = raster.render(cp437_char(b))
        data += pack_bitmap(glyph)
    with open(path, "wb") as f:
        f.write(data)
    return bytes(data)


def draw_glyph(img, fontdata, idx, x, y, scale, color=(230, 230, 230)):
    px = img.load()
    h = len(fontdata) // 256
    glyph = fontdata[(idx % 256) * h : (idx % 256 + 1) * h]
    for gy in range(h):
        row = glyph[gy]
        for gx in range(8):
            if row & (1 << (7 - gx)):
                for sy in range(scale):
                    for sx in range(scale):
                        xx, yy = x + gx * scale + sx, y + gy * scale + sy
                        if 0 <= xx < img.width and 0 <= yy < img.height:
                            px[xx, yy] = color
    return x + 8 * scale


def draw_text(img, fontdata, text, x, y, scale, color=(230, 230, 230)):
    """Render text using the packed bitmap font. Returns x advance."""
    for ch in text:
        idx = CP437_REVERSE.get(ch, ord("?"))
        x = draw_glyph(img, fontdata, idx, x, y, scale, color)
    return x


def make_contact_sheet(
    fontdata, path, scale=4, bg=(10, 10, 12), fg=(230, 230, 230), grid=(40, 44, 54)
):
    h = len(fontdata) // 256
    cols, rows = 16, 16
    cw, chh = 8 * scale + 6, h * scale + 6
    width = max(cols * cw + 1, 1200)
    samples = [
        "Arch Linux   Windows",
        "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
        "abcdefghijklmnopqrstuvwxyz 0123456789",
        "The quick brown fox jumps over the lazy dog",
        "Box: \u250c\u2500\u252c\u2500\u2510 \u2514\u2500\u2534\u2500\u2518 \u251c\u2500\u253c\u2500\u2524",
        "Blocks: \u2588\u2593\u2592\u2591 \u25b2\u25bc\u25ba\u25c4 \u263a\u2665\u266b\u266c",
    ]
    sample_scales = [2, 2, 2, 2, 1, 1]
    samples_h = sum(h * s + 10 for s in sample_scales) + 20
    height = rows * chh + 1 + 14 + samples_h
    img = Image.new("RGB", (width, height), bg)
    d = ImageDraw.Draw(img)
    tiny = ImageFont.load_default()
    for idx in range(256):
        cx = (idx % cols) * cw + 3
        cy = (idx // cols) * chh + 3
        d.rectangle(
            [cx - 3, cy - 3, cx + 8 * scale + 2, cy + h * scale + 2], outline=grid
        )
        draw_glyph(img, fontdata, idx, cx, cy, scale, fg)
        d.text(
            (cx - 1, cy + h * scale + 2), f"{idx:02x}", font=tiny, fill=(120, 126, 138)
        )
    y0 = rows * chh + 1
    d.text((4, y0 + 2), "samples:", font=tiny, fill=(120, 126, 138))
    y0 += 14
    for s, sc in zip(samples, sample_scales):
        draw_text(img, fontdata, s, 8, y0, sc, fg)
        y0 += h * sc + 10
    img.save(path)
    return path


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--size", type=int, default=13, help="TTF pixel size")
    ap.add_argument("--height", type=int, default=16, help="glyph height")
    ap.add_argument("--threshold", type=int, default=100)
    ap.add_argument("--ss", type=int, default=4, help="supersampling factor")
    ap.add_argument("--name", default="jetbrains-mono")
    ap.add_argument(
        "--outdir", default=os.path.expanduser("~/dotfiles/limine/assets/font")
    )
    args = ap.parse_args()

    os.makedirs(args.outdir, exist_ok=True)
    paths = [p for p in FALLBACK_CHAIN if os.path.exists(p)]
    raster = FontRaster(paths, args.size, 8, args.height, args.ss, args.threshold)
    font_path = os.path.join(args.outdir, f"{args.name}.f{args.height}")
    data = build_font(raster, font_path)
    preview_path = os.path.join(args.outdir, f"preview-{args.name}.png")
    make_contact_sheet(data, preview_path)
    print(f"font:    {font_path} ({len(data)} bytes)")
    print(f"preview: {preview_path}")


if __name__ == "__main__":
    main()
