#!/bin/bash
# Toggle Hyprland built-in cursor zoom (replaces nonexistent `hypr-zoom` binary).
# Usage: zoom_toggle.sh [factor]  (default 2.0, 1.0 = off)
# Reads cursor:zoom_factor via hyprctl; toggles between 1.0 and target.

TARGET="${1:-2.0}"
[ "$TARGET" = "1" ] && TARGET="1.0"

current=$(hyprctl getoption cursor:zoom_factor 2>/dev/null | head -n1 | awk '{print $2}')
[ -z "$current" ] && { echo "zoom: could not read cursor:zoom_factor"; exit 1; }

is_one=$(awk -v c="$current" 'BEGIN { print (c < 1.05 && c > 0.95) }')

set_zoom() {
    # hyprviz Lua parser is live; fall back to legacy keyword if eval fails.
    hyprctl eval "hl.config({cursor = {zoom_factor = $1}})" >/dev/null 2>&1 \
        || hyprctl keyword cursor:zoom_factor "$1" >/dev/null 2>&1 \
        || true
}

if [ "$is_one" = "1" ]; then
    set_zoom "$TARGET"
else
    set_zoom 1.0
fi
