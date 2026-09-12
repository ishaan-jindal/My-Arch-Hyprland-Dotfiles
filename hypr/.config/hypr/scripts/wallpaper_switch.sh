#!/bin/bash

CONFIG="$HOME/.config/hypr/themes/themes.json"
BASE="$HOME/.config/hypr/themes"

THEME_STATE="$HOME/.cache/theme_state"
WALL_STATE_PREFIX="$HOME/.cache/wallpaper_state_"

current_wall="$HOME/.config/hypr/wallpapers/current"

theme=$(cat "$THEME_STATE" 2>/dev/null)
[ -z "$theme" ] && theme="gruvbox"

# ----------------------
# get matching wallpapers
# ----------------------
list=$(jq -r --arg theme "$theme" '
    .themes[$theme].tags? as $tags |
    select($tags != null) |
    .wallpapers[] |
    select(any(.tags[]; . as $t | $tags | index($t))) |
    "\(.id)|\(.path)"
' "$CONFIG")

if [ -z "$list" ]; then
    notify-send "Wallpaper Error" "No wallpapers match theme: $theme"
    exit 1
fi

choice=$(echo "$list" | cut -d'|' -f1 | wofi --dmenu -p "Wallpaper ($theme)")
[ -z "$choice" ] && exit 0

path=$(echo "$list" | awk -F'|' -v c="$choice" '$1==c {print $2}')
full="$BASE/$path"

# ----------------------
# apply
# ----------------------
pkill mpvpaper >/dev/null 2>&1

if [[ "$full" =~ \.mp4$ ]]; then
    pkill awww-daemon >/dev/null 2>&1
    mpvpaper -o "loop --no-audio --hwdec=auto --vo=gpu --profile=fast" "*" "$full" &
else
    if ! pgrep -x awww-daemon >/dev/null; then
        awww-daemon & sleep 0.3
    fi
    awww img "$full" -t wipe
fi

rm -f "$current_wall"
ln -s "$full" "$current_wall"

echo "$full" > "${WALL_STATE_PREFIX}${theme}"

