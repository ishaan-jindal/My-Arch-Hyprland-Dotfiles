#!/bin/bash
# Desktop theme switcher.
#
# Usage: theme_toggle.sh apply <theme>
#
# Applies, for the given theme from `hypr/themes/themes.json`:
#   - wallpaper (awww for images, mpvpaper for videos) + `wallpapers/current` symlink
#   - GTK theme / icon theme / cursor / font (gtk-3.0 + gtk-4.0 + gsettings)
#   - state files (~/.cache/theme_state, ~/.cache/wallpaper_state_<theme>)
#   - best-effort Limine boot menu sync (needs the sudoers rule)
#
# The Quickshell shell watches ~/.cache/theme_state and re-themes itself live;
# its launcher themes page drives this script (Super + Shift + T).
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/wallpaper.sh
. "$SCRIPT_DIR/lib/wallpaper.sh"

CONFIG="$HOME/.config/hypr/themes/themes.json"
BASE="$HOME/.config/hypr/themes"

THEME_STATE="$HOME/.cache/theme_state"
WALL_STATE_PREFIX="$HOME/.cache/wallpaper_state_"

current_wall="$BASE/wallpapers/current"
gtk3_ini="$HOME/.config/gtk-3.0/settings.ini"
gtk4_ini="$HOME/.config/gtk-4.0/settings.ini"

notify_err() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "$1" "$2"
    else
        echo "ERROR: $1: $2" >&2
    fi
}

usage() {
    echo "usage: $(basename "$0") apply <theme>" >&2
    echo "themes: $(jq -r '.themes | keys | join(", ")' "$CONFIG" 2>/dev/null)" >&2
}

# ----------------------
# GTK / GNOME sync (notifications + file picker)
# Writes gtk-3.0 + gtk-4.0 settings.ini and mirrors to gsettings/dconf.
# All themes use prefer-dark per user choice.
# ----------------------
apply_gtk() {
    local gtk_theme="$1"
    local icon_theme="$2"
    local cursor_theme cursor_size font_name color_scheme

    cursor_theme=$(jq -r '.defaults["cursor-theme"] // "Bibata-Modern-Classic"' "$CONFIG")
    cursor_size=$(jq -r '.defaults["cursor-size"] // 24' "$CONFIG")
    font_name=$(jq -r '.defaults["font-name"] // "JetBrainsMono Nerd Font Mono 12"' "$CONFIG")
    color_scheme=$(jq -r '.defaults["color-scheme"] // "prefer-dark"' "$CONFIG")

    [ -z "$gtk_theme" ] || [ "$gtk_theme" = "null" ] && gtk_theme="Orchis-Dark"
    [ -z "$icon_theme" ] || [ "$icon_theme" = "null" ] && icon_theme="Papirus-Dark"

    mkdir -p "$(dirname "$gtk3_ini")" "$(dirname "$gtk4_ini")"

    for ini in "$gtk3_ini" "$gtk4_ini"; do
        cat > "$ini" <<EOF
[Settings]
gtk-theme-name=$gtk_theme
gtk-icon-theme-name=$icon_theme
gtk-font-name=$font_name
gtk-cursor-theme-name=$cursor_theme
gtk-cursor-theme-size=$cursor_size
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=0
gtk-menu-images=0
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintslight
gtk-xft-rgba=none
gtk-application-prefer-dark-theme=1
EOF
    done

    if command -v gsettings >/dev/null 2>&1; then
        gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface icon-theme "$icon_theme" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface cursor-theme "$cursor_theme" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface cursor-size "$cursor_size" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface font-name "$font_name" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface color-scheme "$color_scheme" 2>/dev/null || true
        gsettings set org.gnome.desktop.wm.preferences theme "$gtk_theme" 2>/dev/null || true
    fi
}

# ----------------------
# pick wallpaper for a theme
# ----------------------
get_wallpaper() {
    local theme="$1"

    # try saved
    local state="${WALL_STATE_PREFIX}${theme}"
    if [ -f "$state" ]; then
        local saved
        saved=$(cat "$state")
        [ -n "$saved" ] && [ -f "$saved" ] && echo "$saved" && return
    fi

    # fallback: first matching tag
    jq -r --arg theme "$theme" '
    .themes[$theme].tags as $tags |
    select($tags != null) |
    .wallpapers[] |
    select(any(.tags[]; . as $t | $tags | index($t))) |
    .path
    ' "$CONFIG" | head -n1 | while IFS= read -r path; do
        [ -n "$path" ] && [ "$path" != "null" ] && echo "$BASE/$path"
    done
}

# ----------------------
# apply theme
# ----------------------
apply_theme() {
    local theme="$1"

    if ! jq -e --arg theme "$theme" '.themes[$theme]' "$CONFIG" >/dev/null; then
        notify_err "Theme Error" "Unknown theme: $theme"
        return 1
    fi

    local wall
    wall=$(get_wallpaper "$theme")

    if [ -z "$wall" ]; then
        notify_err "Theme Error" "No wallpaper found for theme: $theme"
        return 1
    fi

    set_wallpaper_file "$wall"

    # Resolve the GTK theme + icon theme for this theme
    local resolved
    resolved=$(jq -r --arg theme "$theme" '
    . as $root |
    $root.themes[$theme].components as $c |
    [ ($c.gtk // $theme), ($c.icon // $theme) ] as [$gk, $ic] |
    [
      ($root.components.gtk[$gk] // $gk),
      ($root.components.icon[$ic] // $ic)
    ] | join("\u001f")
    ' "$CONFIG")

    local gtk_theme icon_theme
    IFS=$'\037' read -r gtk_theme icon_theme <<< "$resolved"

    mkdir -p "$(dirname "$current_wall")"
    rm -f "$current_wall"
    ln -s "$wall" "$current_wall"

    apply_gtk "$gtk_theme" "$icon_theme"

    echo "$theme" > "$THEME_STATE"
    echo "$wall" > "${WALL_STATE_PREFIX}${theme}"

    # keep the Limine boot menu in sync (best effort; needs the sudoers rule)
    "$HOME/dotfiles/limine/scripts/limine-sync" >/dev/null 2>&1 || true
}

# ----------------------
# CLI entry (used by the Quickshell launcher / Super + Shift + T)
#   theme_toggle.sh apply <theme>
# ----------------------
command="${1:-}"
case "$command" in
    apply)
        if [ -z "${2:-}" ]; then
            usage
            exit 1
        fi
        apply_theme "$2"
        ;;
    *)
        usage
        exit 1
        ;;
esac
