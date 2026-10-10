#!/bin/bash
# Shared wallpaper helpers, sourced by wallpaper_switch.sh and restore_wallpaper.sh.
#
# Keeps both entry points identical so a wallpaper switch always animates:
#   - images: `awww` with a random pick of `wave` / `wipe` each time
#   - videos + animated GIFs: `mpvpaper` (killed/restarted, no cross-fade).
#     awww only decodes a GIF's first frame, so anything animated goes to
#     mpvpaper, which plays the real frames. `--loop=inf` is required: the
#     bare token `loop` is not an mpv option, mpv reads it as a filename
#     ("Cannot open file 'loop'") and playback stops after one pass.
#
# restore_wallpaper.sh intentionally does NOT use this (instant paint on login).

# set_wallpaper_file <absolute path to image or video>
set_wallpaper_file() {
    local full="$1"

    pkill mpvpaper >/dev/null 2>&1 || true

    case "${full,,}" in
        *.mp4 | *.mkv | *.webm | *.gif)
            pkill awww-daemon >/dev/null 2>&1 || true
            mpvpaper -o "--loop=inf --no-audio --hwdec=auto --vo=gpu --profile=fast" "*" "$full" &
            ;;
        *)
            if ! pgrep -x awww-daemon >/dev/null; then
                awww-daemon & sleep 0.3
            fi
            local transitions=(wave wipe)
            awww img "$full" -t "${transitions[RANDOM % ${#transitions[@]}]}"
            ;;
    esac
}
