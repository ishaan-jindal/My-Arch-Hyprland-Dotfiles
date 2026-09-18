#!/usr/bin/env python3
"""Pick vivid accent colors from a wallpaper for the autotheme pipeline.

Material You dark roles are pastel by spec, so saturated wallpapers wash
out. This extracts the image's own most-vibrant hues instead (accent) plus
a second distinct hue (soft), lightness-clamped for readability on dark
backgrounds, and emits a matugen --import-json file:

    vibrant.py <image> <output.json>

Output: {"vibrant": {"color": ...}, "vibrant_soft": {...}, "vibrant_on": {...}}
where vibrant_on is readable text on top of vibrant (white or near-black).

Exits non-zero when no saturated cluster exists (true grayscale — the
caller uses the neutral theme) or when measurement fails. Stdlib only;
quantization via ImageMagick.
"""

import colorsys
import re
import subprocess
import sys

MIN_COVERAGE = 0.008
MIN_SATURATION = 0.20
SOFT_MIN_HUE_DIST = 25.0
ACCENT_LIGHTNESS = 0.66

# ANSI hue families (center degrees) for the terminal palette.
FAMILIES = [
    ("red", 0),
    ("yellow", 50),
    ("green", 130),
    ("cyan", 185),
    ("blue", 220),
    ("magenta", 300),
]
FAMILY_MIN_SAT = 0.10


def histogram(path):
    out = subprocess.run(
        [
            "magick",
            str(path),
            "-resize",
            "160x160",
            "-colors",
            "12",
            "-format",
            "%c",
            "histogram:info:",
        ],
        capture_output=True,
        text=True,
        timeout=60,
    )
    if out.returncode != 0:
        raise RuntimeError("magick failed")
    total = 0
    clusters = []
    for line in out.stdout.splitlines():
        m = re.match(r"\s*(\d+):\s*\(([\d.]+),([\d.]+),([\d.]+)", line)
        if not m:
            continue
        count = int(m.group(1))
        r, g, b = (round(float(m.group(i))) for i in (2, 3, 4))
        total += count
        clusters.append((count, r, g, b))
    if not total:
        raise RuntimeError("empty histogram")
    return total, clusters


def score(count, total, sat):
    # saturation-first: the hero is the most vivid qualifying cluster,
    # not the largest dull field. Coverage only breaks ties (and the
    # MIN_COVERAGE floor already excludes speck noise).
    return (round(sat, 3), count)


def clamp_lightness(r, g, b, light=ACCENT_LIGHTNESS):
    h, _, s = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
    r2, g2, b2 = colorsys.hls_to_rgb(h, light, s)
    return "#{:02x}{:02x}{:02x}".format(
        round(r2 * 255), round(g2 * 255), round(b2 * 255)
    )


def clamp_range(r, g, b, lo, hi):
    h, l, s = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
    l2 = min(max(l, lo), hi)
    r2, g2, b2 = colorsys.hls_to_rgb(h, l2, s)
    return "#{:02x}{:02x}{:02x}".format(
        round(r2 * 255), round(g2 * 255), round(b2 * 255)
    )


def hue_dist(a, b):
    return abs((a - b + 180) % 360 - 180)


def luminance(hexcode):
    h = hexcode.lstrip("#")
    r, g, b = (int(h[i : i + 2], 16) for i in (0, 2, 4))
    return (0.299 * r + 0.587 * g + 0.114 * b) / 255


def hue_of(r, g, b):
    h, _, _ = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
    return h * 360


def family_pick(clusters, total, center):
    """Best cluster near a hue family center, or None."""
    best = None
    for count, r, g, b in clusters:
        if count / total < MIN_COVERAGE:
            continue
        h, _, s = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
        if s < FAMILY_MIN_SAT:
            continue
        if hue_dist(h * 360, center) > 45:
            continue
        key = (round(s, 3), count)
        if best is None or key > best[0]:
            best = (key, (r, g, b))
    return best[1] if best else None


def neutral_at(clusters, total, target, default):
    """Closest neutral (low-sat) cluster to a target lightness."""
    best = None
    for count, r, g, b in clusters:
        if count / total < MIN_COVERAGE:
            continue
        h, l, s = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
        if s >= FAMILY_MIN_SAT:
            continue
        key = abs(l - target)
        if best is None or key < best[0]:
            best = (key, (r, g, b))
    if best is None:
        v = round(default * 255)
        return (v, v, v)
    return best[1]


def to_hex(rgb):
    r, g, b = (round(max(0, min(255, v))) for v in rgb)
    return "#{:02x}{:02x}{:02x}".format(r, g, b)


def build_term_palette(clusters, total):
    """Full 16-color ANSI palette from the image's own hues.

    Normals sit at readable mid lightness, brights one step up; missing
    families and neutrals fall back to a grey ramp so every slot is valid.
    """
    fams = {name: family_pick(clusters, total, center) for name, center in FAMILIES}

    def slot(name, lo, hi, fb_light):
        center = dict(FAMILIES)[name]
        rgb = fams[name]
        if rgb is None:
            # missing hue: tinted grey in the family hue reads intentional,
            # flat grey reads broken
            r2, g2, b2 = colorsys.hls_to_rgb(center / 360, fb_light, 0.18)
            return (round(r2 * 255), round(g2 * 255), round(b2 * 255))
        h, l, s = colorsys.rgb_to_hls(*(v / 255 for v in rgb))
        return tuple(
            round(v * 255) for v in colorsys.hls_to_rgb(h, min(max(l, lo), hi), s)
        )

    def tup(hexcode):
        h = hexcode.lstrip("#")
        return tuple(int(h[i : i + 2], 16) for i in (0, 2, 4))

    black = neutral_at(clusters, total, 0.10, 0.10)
    mid = neutral_at(clusters, total, 0.45, 0.45)
    light = neutral_at(clusters, total, 0.85, 0.85)
    white = neutral_at(clusters, total, 0.93, 0.93)

    order = ["red", "green", "yellow", "blue", "magenta", "cyan"]
    terms = []
    terms.append(clamp_range(*black, 0.08, 0.14))  # 0 black
    for name in order:  # 1-6
        terms.append(to_hex(slot(name, 0.55, 0.70, 0.60)))
    terms.append(clamp_range(*light, 0.80, 0.88))  # 7 white
    terms.append(clamp_range(*mid, 0.38, 0.50))  # 8 bright black
    for name in order:  # 9-14
        terms.append(to_hex(slot(name, 0.72, 0.85, 0.75)))
    terms.append(clamp_range(*white, 0.90, 0.96))  # 15 bright white
    return terms


def main():
    image, dest = sys.argv[1], sys.argv[2]
    total, clusters = histogram(image)

    cands = []
    for count, r, g, b in clusters:
        if count / total < MIN_COVERAGE:
            continue
        h, l, s = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
        if s < MIN_SATURATION:
            continue
        cands.append(
            {
                "score": score(count, total, s),
                "hue": h * 360,
                "sat": s,
                "rgb": (r, g, b),
            }
        )
    if not cands:
        sys.exit(2)
    cands.sort(key=lambda c: c["score"], reverse=True)

    top = cands[0]
    accent = clamp_lightness(*top["rgb"])
    soft = None
    for c in cands[1:]:
        if hue_dist(c["hue"], top["hue"]) >= SOFT_MIN_HUE_DIST:
            soft = clamp_lightness(*c["rgb"])
            break
    if soft is None:
        # same family: nudge lightness for separation, capped for contrast
        h, l, s = colorsys.rgb_to_hls(*(v / 255 for v in top["rgb"]))
        r2, g2, b2 = colorsys.hls_to_rgb(h, min(l + 0.12, 0.80), s)
        soft = "#{:02x}{:02x}{:02x}".format(
            round(r2 * 255), round(g2 * 255), round(b2 * 255)
        )

    on = "#ffffff" if luminance(accent) < 0.45 else "#1a1a1c"

    terms = build_term_palette(clusters, total)

    import json

    with open(dest, "w") as f:
        payload = {
            "vibrant": {"color": accent},
            "vibrant_soft": {"color": soft},
            "vibrant_on": {"color": on},
        }
        for i, color in enumerate(terms):
            payload[f"term{i}"] = {"color": color}
        json.dump(payload, f)


if __name__ == "__main__":
    main()
