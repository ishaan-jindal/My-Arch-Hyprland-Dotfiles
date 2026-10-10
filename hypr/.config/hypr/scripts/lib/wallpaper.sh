#!/bin/bash
# Shared wallpaper helpers, sourced by wallpaper_switch.sh and restore_wallpaper.sh.
#
# Transition design: a still image always mediates, so no surface is ever
# absent (black gap) and awww's daemon cache never holds a stale image
# (wall1 flash). Both painters overlap briefly; mpvpaper maps on top.
#   - image -> image: awww wave/wipe, as before
#   - anything -> video: awww waves to the video's first-frame bridge still
#     (same wave as image switches), then mpvpaper maps on top — it starts
#     at ~that frame, so the handoff cut is near-invisible
#   - video -> image: the video's bridge still is painted instantly underneath
#     the running video (hidden), mpvpaper drops to reveal it, awww runs the
#     wave/wipe from the bridge
#
# Needs is_video/ensure_thumb/bridge_for/WALL_STATE from lib/autotheme.sh.
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/autotheme.sh"

# start_awww: daemon up, ready to paint.
start_awww() {
    if ! pgrep -x awww-daemon >/dev/null; then
        awww-daemon & sleep 0.3
    fi
}

# set_wallpaper_file <absolute path to image or video>
set_wallpaper_file() {
    local full="$1"
    # Outgoing wallpaper: WALL_STATE still holds it (the caller updates it
    # after we return).
    local prev=""
    [ -f "$WALL_STATE" ] && prev="$(cat "$WALL_STATE")"

    if is_video "$full"; then
        # Same video already playing: restarting it would only flicker.
        if [ "$prev" = "$full" ] && pgrep -x mpvpaper >/dev/null; then
            return 0
        fi
        ensure_thumb "$full"
        start_awww
        if [ -n "$prev" ] && [ -f "$prev" ] && is_video "$prev" \
            && pgrep -x mpvpaper >/dev/null; then
            # From video: stage the old bridge underneath, drop the video
            # to reveal it (one cut), then wave old-bridge -> new-bridge
            # in the open like any image switch.
            ensure_thumb "$prev"
            awww img "$(bridge_for "$prev")" --transition-type none || true
            pkill mpvpaper >/dev/null 2>&1 || true
        fi
        # The wave runs to completion BEFORE the video maps over it —
        # mapping mid-wave would hide the effect. awww waves use the
        # default 3 s duration, same as image switches.
        local transitions=(wave wipe)
        awww img "$(bridge_for "$full")" \
            -t "${transitions[RANDOM % ${#transitions[@]}]}" || true
        sleep 3.2
        pkill mpvpaper >/dev/null 2>&1 || true
        mpvpaper -o "--loop=inf --no-audio --hwdec=auto --vo=gpu --profile=fast" "*" "$full" &
        sleep 0.4
        pkill awww-daemon >/dev/null 2>&1 || true
        return 0
    fi

    if [ -n "$prev" ] && [ -f "$prev" ] && is_video "$prev" \
        && pgrep -x mpvpaper >/dev/null; then
        ensure_thumb "$prev"
        start_awww
        awww img "$(bridge_for "$prev")" --transition-type none || true
        pkill mpvpaper >/dev/null 2>&1 || true
    else
        start_awww
    fi
    local transitions=(wave wipe)
    awww img "$full" -t "${transitions[RANDOM % ${#transitions[@]}]}"
}
