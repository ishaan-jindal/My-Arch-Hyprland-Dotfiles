#!/usr/bin/env bash
# Build the Limine wallpaper pack from the Hyprland wallpaper assets.
# Output: ~/dotfiles/limine/assets/wallpapers/w*.jpg (1920x1080, 8.3-safe names)
set -euo pipefail

ASSETS="$HOME/.config/hypr/themes/wallpapers/assets"
OUT="$HOME/dotfiles/limine/assets/wallpapers"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$OUT"

process_image() { # src filter out
  local src="$1" out="$2"; shift 2
  magick "$src" -auto-orient -resize '1920x1080^' -gravity center -extent 1920x1080 \
    -colorspace sRGB "$@" -quality 84 -strip "$out"
}

frame() { # src time out
  ffmpeg -v error -y -ss "$2" -i "$1" -frames:v 1 \
    -vf "scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080" \
    -q:v 2 "$3"
}

i=0
add_image() { # src dim blur
  i=$((i+1))
  local args=(-modulate "$2,100,100")
  [ "$3" != "0" ] && args+=(-blur "$3")
  process_image "$1" "$OUT/w$i.jpg" "${args[@]}"
}
add_video() { # src time dim blur
  i=$((i+1))
  local f="$TMP/frame$i.png"
  frame "$1" "$2" "$f"
  local args=(-modulate "$3,100,100")
  [ "$4" != "0" ] && args+=(-blur "$4")
  process_image "$f" "$OUT/w$i.jpg" "${args[@]}"
}

add_image "$ASSETS/green-volcano.jpg"       88 "0x3"
add_image "$ASSETS/red-water-sunset.jpg"    72 "0x4"
add_image "$ASSETS/black.jpg"              100 "0"
add_image "$ASSETS/arch.png"                92 "0"
add_image "$ASSETS/home.jpg"                85 "0x3"
add_image "$ASSETS/gold.png"                80 "0x2"
add_video "$ASSETS/gradient-3d-cube.1920x1080.mp4"      4  92 "0"
add_video "$ASSETS/yin-and-yang.1920x1080.mp4"          5  70 "0x2"
add_video "$ASSETS/minimalistic-samurai.1920x1080.mp4"  3  86 "0x3"
add_video "$ASSETS/aesthetic-landscape-with-train.3840x2160.mp4" 10 42 "0x3"

magick montage "$OUT"/w*.jpg -tile 4x -geometry 480x270+6+6 \
  -background '#0a0a0c' "$OUT/preview-wallpapers.png"

echo "pack:"
ls -lh "$OUT"/w*.jpg
echo "preview: $OUT/preview-wallpapers.png"
