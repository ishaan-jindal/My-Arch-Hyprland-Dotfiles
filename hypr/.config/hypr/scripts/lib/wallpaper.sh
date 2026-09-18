#!/bin/bash
# Shared wallpaper helpers, sourced by wallpaper_switch.sh and restore_wallpaper.sh.
#
# Keeps both entry points identical so a wallpaper switch always animates:
#   - images: `awww` with a random pick of `wave` / `wipe` each time
#   - videos: `mpvpaper` (killed/restarted, no cross-fade)
#
# restore_wallpaper.sh intentionally does NOT use this (instant paint on login).

# set_wallpaper_file <absolute path to image or video>
set_wallpaper_file() {
    local full="$1"

    pkill mpvpaper >/dev/null 2>&1 || true

    if [[ "$full" == *.mp4 ]]; then
        pkill awww-daemon >/dev/null 2>&1 || true
        mpvpaper -o "loop --no-audio --hwdec=auto --vo=gpu --profile=fast" "*" "$full" &
    else
        if ! pgrep -x awww-daemon >/dev/null; then
            awww-daemon & sleep 0.3
        fi
        local transitions=(wave wipe)
        awww img "$full" -t "${transitions[RANDOM % ${#transitions[@]}]}"
    fi
}
