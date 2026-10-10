#!/usr/bin/env bash
# Build the Limine wallpaper pack from the Hyprland wallpaper assets.
# Output: <repo>/limine/assets/wallpapers/w*.jpg (1920x1080, 8.3-safe names)
set -euo pipefail

ASSETS="$HOME/.config/hypr/themes/wallpapers/assets"
# Repo-relative, so the checkout can live anywhere.
OUT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../assets/wallpapers" && pwd)"
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

add_image "$ASSETS/a_cat_walking_on_a_hill.png"                        70 "0x3"
add_image "$ASSETS/an_astronaut_playing_a_piano.png"                   78 "0x3"
add_image "$ASSETS/a_painting_of_a_man_with_a_dripping_face.jpg"       70 "0x2"
add_image "$ASSETS/arch.png"                                           92 "0"
add_image "$ASSETS/a_space_ship_flying_in_the_sky.jpg"                 80 "0x2"
add_image "$ASSETS/a_video_game_screen_with_a_diamond_and_green_lights.png" 80 "0x2"
add_image "$ASSETS/black.jpg"                                         85 "0x2"
add_image "$ASSETS/fireplace.gif[0]"                                     75 "0x3"
add_video "$ASSETS/pixel-sakura.1920x1080.mp4"                         5  75 "0x3"
add_image "$ASSETS/red.jpg"                                           85 "0"

magick montage "$OUT"/w*.jpg -tile 4x -geometry 480x270+6+6 \
  -background '#0a0a0c' "$OUT/preview-wallpapers.png"

echo "pack:"
ls -lh "$OUT"/w*.jpg
echo "preview: $OUT/preview-wallpapers.png"
