#!/bin/bash
# Repaint the last wallpaper on login (instant, no transition) and make sure
# a valid autotheme exists for it.
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/autotheme.sh
. "$SCRIPT_DIR/lib/autotheme.sh"

wall=$(cat "$WALL_STATE" 2>/dev/null || true)
[ -z "${wall:-}" ] && exit 0
[ -f "$wall" ] || exit 0

# kill existing
pkill mpvpaper >/dev/null 2>&1 || true
pkill awww-daemon >/dev/null 2>&1 || true

if is_video "$wall"; then
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

# the cache survives reboots, but regenerate if it was wiped, corrupted,
# or any generated file is missing (fresh clone, new template added)
if ! autotheme_valid || [ ! -f "$GHOSTTY_THEME" ] || [ ! -f "$HYPLOCK_CONF" ] \
    || [ ! -f "$GTK3_CSS" ] || [ ! -f "$GTK4_CSS" ]; then
    ensure_thumb "$wall"
    generate_autotheme "$wall" || true
fi

set_hypr_borders
