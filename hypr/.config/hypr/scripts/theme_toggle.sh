#!/bin/bash

CONFIG="$HOME/.config/hypr/themes/themes.json"
BASE="$HOME/.config/hypr/themes"

THEME_STATE="$HOME/.cache/theme_state"
WALL_STATE_PREFIX="$HOME/.cache/wallpaper_state_"

# symlinks
waybar_config="$HOME/.config/waybar/config.jsonc"
waybar_style="$HOME/.config/waybar/style.css"
wofi_style="$HOME/.config/wofi/style.css"
wlogout_style="$HOME/.config/wlogout/style.css"
current_wall="$HOME/.config/hypr/wallpapers/current"
swaync_config="$HOME/.config/swaync/config.json"
swaync_style="$HOME/.config/swaync/style.css"
gtk3_ini="$HOME/.config/gtk-3.0/settings.ini"
gtk4_ini="$HOME/.config/gtk-4.0/settings.ini"

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
# swaync sync (replaces dunst)
# ----------------------
apply_swaync() {
    local src_dir="$1"
    [ -z "$src_dir" ] || [ "$src_dir" = "null" ] && return 0
    [ -d "$src_dir" ] || { echo "Swaync theme missing: $src_dir"; return 0; }

    mkdir -p "$(dirname "$swaync_config")"
    rm -f "$swaync_config" "$swaync_style"
    [ -f "$src_dir/config.json" ] && ln -s "$src_dir/config.json" "$swaync_config"
    [ -f "$src_dir/style.css" ] && ln -s "$src_dir/style.css" "$swaync_style"

    if pgrep -x swaync >/dev/null 2>&1; then
        swaync-client --reload-config >/dev/null 2>&1 || { pkill -x swaync; swaync >/dev/null 2>&1 & }
    else
        pkill -x dunst >/dev/null 2>&1 || true
        swaync >/dev/null 2>&1 &
    fi
}

# ----------------------
# wallpaper setter
# ----------------------
set_wallpaper() {
    local file="$1"

    pkill mpvpaper >/dev/null 2>&1

    if [[ "$file" =~ \.mp4$ ]]; then
        pkill awww-daemon >/dev/null 2>&1
        mpvpaper -o "loop --no-audio --hwdec=auto --vo=gpu --profile=fast" "*" "$file" &
    else
        if ! pgrep -x "awww-daemon" >/dev/null; then
            awww-daemon & sleep 0.3
        fi
        awww img "$file" --transition-type none
    fi
}

# ----------------------
# pick wallpaper
# ----------------------
get_wallpaper() {
    local theme="$1"

    # try saved
    local state="${WALL_STATE_PREFIX}${theme}"
    if [ -f "$state" ]; then
        local saved=$(cat "$state")
        [ -f "$saved" ] && echo "$saved" && return
    fi

    # fallback: first matching tag
    jq -r --arg theme "$theme" '
    .themes[$theme].tags as $tags |
    .wallpapers[] |
    select(any(.tags[]; . as $t | $tags | index($t))) |
    .path
    ' "$CONFIG" | head -n1 | while read -r path; do
        echo "$BASE/$path"
    done
}

# ----------------------
# apply theme
# ----------------------
apply_theme() {
    local theme="$1"

    wall=$(get_wallpaper "$theme")

    if [ -z "$wall" ]; then
      notify-send "Theme Error" "No wallpaper found for theme: $theme"
      exit 1
    fi

    set_wallpaper "$wall"

    waybar_key=$(jq -r ".themes[\"$theme\"].components.waybar" "$CONFIG")
    wofi_key=$(jq -r ".themes[\"$theme\"].components.wofi" "$CONFIG")
    wlogout_key=$(jq -r ".themes[\"$theme\"].components.wlogout" "$CONFIG")
    gtk_key=$(jq -r ".themes[\"$theme\"].components.gtk // \"$theme\"" "$CONFIG")
    swaync_key=$(jq -r ".themes[\"$theme\"].components.swaync // \"$theme\"" "$CONFIG")
    icon_key=$(jq -r ".themes[\"$theme\"].components.icon // \"$theme\"" "$CONFIG")

    waybar_path="$BASE/$(jq -r ".components.waybar[\"$waybar_key\"]" "$CONFIG")"
    wofi_path="$BASE/$(jq -r ".components.wofi[\"$wofi_key\"]" "$CONFIG")"
    wlogout_path="$BASE/$(jq -r ".components.wlogout[\"$wlogout_key\"]" "$CONFIG")"
    gtk_theme=$(jq -r ".components.gtk[\"$gtk_key\"] // \"$gtk_key\"" "$CONFIG")
    icon_theme=$(jq -r ".components.icon[\"$icon_key\"] // \"$icon_key\"" "$CONFIG")
    swaync_dir="$BASE/$(jq -r ".components.swaync[\"$swaync_key\"]" "$CONFIG")"

    rm -f "$waybar_config" "$waybar_style" "$wofi_style" "$wlogout_style" "$current_wall"

    [ ! -f "$waybar_path/config.jsonc" ] && echo "Waybar config missing: $waybar_path"
    [ ! -f "$wofi_path" ] && echo "Wofi missing: $wofi_path"
    [ ! -f "$wlogout_path" ] && echo "Wlogout missing: $wlogout_path"

    ln -s "$waybar_path/config.jsonc" "$waybar_config"
    ln -s "$waybar_path/style.css" "$waybar_style"
    ln -s "$wofi_path" "$wofi_style"
    ln -s "$wlogout_path" "$wlogout_style"
    ln -s "$wall" "$current_wall"

    killall -q waybar
    while pgrep -x waybar >/dev/null; do sleep 0.1; done
    waybar &

    apply_gtk "$gtk_theme" "$icon_theme"
    apply_swaync "$swaync_dir"

    echo "$theme" > "$THEME_STATE"
    echo "$wall" > "${WALL_STATE_PREFIX}${theme}"
}

# ----------------------
# menu
# ----------------------
themes=$(jq -r '.themes | keys[]' "$CONFIG")

selected=$(echo "$themes" | wofi --dmenu -p "Theme")

[ -z "$selected" ] && exit 0

apply_theme "$selected"

