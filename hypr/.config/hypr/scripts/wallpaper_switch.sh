#!/bin/bash
# Dynamic wallpaper switcher + autothemer. No configs, no registries.
#
# Usage:
#   wallpaper_switch.sh apply <name-or-path>  # any image/video file
#   wallpaper_switch.sh list-json             # JSON array of assets dir (for Quickshell)
#   wallpaper_switch.sh ensure-thumbs         # generate missing video thumbnails
#
# apply sets the wallpaper (awww/mpvpaper), runs matugen once in dark mode to
# regenerate ~/.cache/autotheme.json (watched live by Quickshell), syncs the
# fixed dark GTK furniture and the Limine boot menu. Drop a file into the
# assets dir and it is immediately usable — nothing else to edit.
#
# The Quickshell wallpaper picker (Super + T) drives this script.
set -u

SCRIPT_SRC="${BASH_SOURCE[0]}"
if command -v readlink >/dev/null 2>&1; then
    SCRIPT_SRC="$(readlink -f "$SCRIPT_SRC")"
fi
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_SRC")" && pwd)"
# Repo checkout root (hypr/.config/hypr/scripts → up 4 levels); the
# limine-sync path below falls back to ~/dotfiles when that fails.
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." 2>/dev/null && pwd || echo "$HOME/dotfiles")"
LIMINE_SYNC="$REPO_ROOT/limine/scripts/limine-sync"
[ -x "$LIMINE_SYNC" ] || LIMINE_SYNC="$HOME/dotfiles/limine/scripts/limine-sync"
# shellcheck source=lib/wallpaper.sh
. "$SCRIPT_DIR/lib/wallpaper.sh"
# shellcheck source=lib/autotheme.sh
. "$SCRIPT_DIR/lib/autotheme.sh"

usage() {
    echo "usage: $(basename "$0") apply <name-or-path> | list-json | ensure-thumbs" >&2
}

# ----------------------
# apply a wallpaper by filename (assets dir) or path
# ----------------------
apply_wallpaper() {
    local full
    full="$(resolve_wallpaper "$1")" || {
        notify_err "Wallpaper Error" "File not found: $1"
        return 1
    }

    set_wallpaper_file "$full"

    mkdir -p "$(dirname "$CURRENT_LINK")"
    rm -f "$CURRENT_LINK"
    ln -s "$full" "$CURRENT_LINK"

    # Same file re-applied and the generated outputs are still valid: skip
    # the one-shot matugen run, just repaint and relink.
    local prev=""
    [ -f "$WALL_STATE" ] && prev="$(cat "$WALL_STATE")"
    if [ "$prev" = "$full" ] && autotheme_valid && [ -f "$GHOSTTY_THEME" ]; then
        "$LIMINE_SYNC" >/dev/null 2>&1 || true
        return 0
    fi

    ensure_thumb "$full"
    generate_autotheme "$full" || true
    apply_gtk_dark

    echo "$full" > "$WALL_STATE"

    # keep the Limine boot menu in sync (best effort; needs the sudoers rule)
    "$LIMINE_SYNC" >/dev/null 2>&1 || true
}

# ----------------------
# list-json: every image/video in the assets dir, sorted by name.
# Videos carry their thumbnail path ("" when not generated yet).
# ----------------------
list_json() {
    if [ ! -d "$ASSETS_DIR" ]; then
        echo '[]'
        return 0
    fi
    find "$ASSETS_DIR" -maxdepth 1 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
        -o -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.webm' \) \
        -print0 \
    | sort -z \
    | while IFS= read -r -d '' f; do
        local base ext isvid thumb
        base="$(basename "$f")"
        ext="$(printf '%s' "${base##*.}" | tr '[:upper:]' '[:lower:]')"
        isvid=false
        thumb=""
        if [ "$ext" = "mp4" ]; then
            isvid=true
            thumb="$(thumb_for "$f")"
            [ -f "$thumb" ] || thumb=""
        fi
        jq -n --arg id "$base" --arg name "$base" --arg path "$f" \
            --argjson isVideo "$isvid" --arg thumb "$thumb" \
            '{id: $id, name: $name, path: $path, isVideo: $isVideo, thumb: $thumb}'
    done | jq -s 'sort_by(.name | ascii_downcase)'
}

# ----------------------
# ensure-thumbs: generate every missing video thumbnail
# ----------------------
ensure_thumbs() {
    [ -d "$ASSETS_DIR" ] || return 0
    find "$ASSETS_DIR" -maxdepth 1 -type f -iname '*.mp4' -print0 \
    | while IFS= read -r -d '' f; do
        ensure_thumb "$f"
    done
}

command="${1:-}"
case "$command" in
    apply)
        if [ -z "${2:-}" ]; then
            usage
            exit 1
        fi
        apply_wallpaper "$2"
        ;;
    list-json)
        list_json
        ;;
    ensure-thumbs)
        ensure_thumbs
        ;;
    *)
        usage
        exit 1
        ;;
esac
