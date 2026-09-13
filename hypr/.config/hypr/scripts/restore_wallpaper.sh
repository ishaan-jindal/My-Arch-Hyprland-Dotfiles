#!/bin/bash
set -u

THEME_STATE="$HOME/.cache/theme_state"
WALL_STATE_PREFIX="$HOME/.cache/wallpaper_state_"
CURRENT_LINK="$HOME/.config/hypr/themes/wallpapers/current"

theme=$(cat "$THEME_STATE" 2>/dev/null || true)
[ -z "${theme:-}" ] && exit 0

wall=$(cat "${WALL_STATE_PREFIX}${theme}" 2>/dev/null || true)
[ -z "${wall:-}" ] && exit 0

# kill existing
pkill mpvpaper >/dev/null 2>&1 || true
pkill awww-daemon >/dev/null 2>&1 || true

if [[ "$wall" == *.mp4 ]]; then
    mpvpaper -o "loop --no-audio --hwdec=auto --vo=gpu --profile=fast" "*" "$wall" &
else
    awww-daemon >/dev/null 2>&1 &
    sleep 0.2
    awww img "$wall" --transition-type none
fi

# restore symlink
mkdir -p "$(dirname "$CURRENT_LINK")"
rm -f "$CURRENT_LINK"
ln -s "$wall" "$CURRENT_LINK"
