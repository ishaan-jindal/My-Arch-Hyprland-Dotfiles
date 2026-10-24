#!/bin/bash
# Cycle wallpapers at random on an interval. Single-instance via flock so
# Hyprland restarts never stack duplicate loops.
#   wallpaper_cycle.sh          # run the loop (autostarted)
#   wallpaper_cycle.sh toggle   # toggle the loop on/off (Super+Shift+T)
# Interval: WALLPAPER_CYCLE_INTERVAL seconds (default 600).
set -u

INTERVAL="${WALLPAPER_CYCLE_INTERVAL:-600}"
LOCK="$HOME/.cache/wallpaper_cycle.lock"
SWITCH="$HOME/.config/hypr/scripts/wallpaper_switch.sh"

note() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Wallpaper" "$1"
    else
        echo "$1"
    fi
}

# __loop carries its own argv marker so toggle's pgrep/pkill can never
# match the toggle process itself.
toggle_cycle() {
    if pgrep -f "wallpaper_cycle\.sh __loop" >/dev/null; then
        pkill -f "wallpaper_cycle\.sh __loop"
        note "Auto-cycle off"
    else
        setsid "$0" __loop >/dev/null 2>&1 < /dev/null &
        note "Auto-cycle on (every $((INTERVAL / 60)) min)"
    fi
}

case "${1:-start}" in
    __loop)
        exec 9>"$LOCK"
        flock -n 9 || exit 0
        # 9>&- keeps children (sleep, the switcher and everything it
        # spawns) from inheriting the lock fd: killing the loop always
        # frees the lock at once, never wedged by an orphaned child.
        while true; do
            sleep "$INTERVAL" 9>&-
            "$SWITCH" random 9>&- || true
        done
        ;;
    start)
        exec "$0" __loop
        ;;
    toggle)
        toggle_cycle
        ;;
    *)
        echo "usage: $(basename "$0") [start|toggle]" >&2
        exit 1
        ;;
esac
