#!/bin/bash
# Wallpaper switcher for the current theme.
#
# Usage: wallpaper_switch.sh apply <wallpaper-id>
#
# Wallpaper ids and tags come from `hypr/themes/themes.json`; only entries
# whose tags intersect the current theme's tags are selectable. Images are
# drawn by `awww`, videos by `mpvpaper`.
#
# The Quickshell launcher wallpapers page (Super + T) drives this script.
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/wallpaper.sh
. "$SCRIPT_DIR/lib/wallpaper.sh"

CONFIG="$HOME/.config/hypr/themes/themes.json"
BASE="$HOME/.config/hypr/themes"

THEME_STATE="$HOME/.cache/theme_state"
WALL_STATE_PREFIX="$HOME/.cache/wallpaper_state_"

current_wall="$BASE/wallpapers/current"

theme=$(cat "$THEME_STATE" 2>/dev/null || true)
if [ -z "${theme:-}" ] || ! jq -e --arg theme "$theme" '.themes[$theme]' "$CONFIG" >/dev/null 2>&1; then
    theme="obsidian"
fi

notify_err() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "$1" "$2"
    else
        echo "ERROR: $1: $2" >&2
    fi
}

usage() {
    echo "usage: $(basename "$0") apply <wallpaper-id>" >&2
    echo "wallpapers for theme '$theme': $(list_wallpapers | cut -d'|' -f1 | paste -sd', ' -)" >&2
}

# ----------------------
# list matching wallpapers as "id|path" lines
# ----------------------
list_wallpapers() {
    jq -r --arg theme "$theme" '
        .themes[$theme].tags? as $tags |
        select($tags != null) |
        .wallpapers[] |
        select(any(.tags[]; . as $t | $tags | index($t))) |
        "\(.id)|\(.path)"
    ' "$CONFIG"
}

# ----------------------
# apply a wallpaper by id
# ----------------------
apply_wallpaper_id() {
    local id="$1"
    local rel
    rel=$(list_wallpapers | awk -F'|' -v c="$id" '$1==c {print $2}' | head -n1)

    if [ -z "$rel" ]; then
        notify_err "Wallpaper Error" "Unknown wallpaper for theme $theme: $id"
        return 1
    fi

    local full="$BASE/$rel"
    set_wallpaper_file "$full"

    mkdir -p "$(dirname "$current_wall")"
    rm -f "$current_wall"
    ln -s "$full" "$current_wall"

    echo "$full" > "${WALL_STATE_PREFIX}${theme}"
}

# ----------------------
# CLI entry (used by the Quickshell launcher / Super + T)
#   wallpaper_switch.sh apply <wallpaper-id>
# ----------------------
command="${1:-}"
case "$command" in
    apply)
        if [ -z "${2:-}" ]; then
            usage
            exit 1
        fi
        apply_wallpaper_id "$2"
        ;;
    *)
        usage
        exit 1
        ;;
esac
