#!/bin/bash
# Shared autotheme helpers, sourced by wallpaper_switch.sh and restore_wallpaper.sh.
#
# Fully dynamic pipeline, no theme configs:
#   wallpaper file -> matugen (dark-only Material You) -> ~/.cache/autotheme.json
#   -> Quickshell Theme.qml (watches the file) + fixed dark GTK + Limine sync.
#
# ASSETS_DIR..FONT_NAME below are the lib's interface, consumed by the
# sourcing scripts (wallpaper_switch.sh, restore_wallpaper.sh).
# shellcheck disable=SC2034

ASSETS_DIR="$HOME/.config/hypr/themes/wallpapers/assets"
THUMBS_DIR="$HOME/.config/hypr/themes/wallpapers/thumbs"
CURRENT_LINK="$HOME/.config/hypr/themes/wallpapers/current"
WALL_STATE="$HOME/.cache/wallpaper_state"
AUTOTHEME_JSON="$HOME/.cache/autotheme.json"
AUTOTHEME_TEMPLATE="$HOME/.config/hypr/scripts/templates/autotheme.json"
GHOSTTY_TEMPLATE="$HOME/.config/hypr/scripts/templates/ghostty-theme"
GHOSTTY_THEME="$HOME/.config/ghostty/themes/autotheme"
HYPLOCK_TEMPLATE="$HOME/.config/hypr/hyprlock.conf.template"
HYPLOCK_CONF="$HOME/.config/hypr/hyprlock.conf"
GTK3_TEMPLATE="$HOME/.config/hypr/scripts/templates/gtk3.css"
GTK3_CSS="$HOME/.config/gtk-3.0/gtk.css"
GTK4_TEMPLATE="$HOME/.config/hypr/scripts/templates/gtk4.css"
GTK4_CSS="$HOME/.config/gtk-4.0/gtk.css"
VIBRANT_PY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/vibrant.py"

# Fixed dark desktop furniture (the generated palette only themes the shell).

# Fixed dark desktop furniture (the generated palette only themes the shell).
GTK_THEME="Orchis-Dark"
ICON_THEME="Papirus-Dark"
CURSOR_THEME="Bibata-Modern-Classic"
CURSOR_SIZE=24
FONT_NAME="JetBrainsMono Nerd Font Mono 12"

notify_err() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "$1" "$2"
    else
        echo "ERROR: $1: $2" >&2
    fi
}

# ----------------------
# resolve_wallpaper <name-or-path> -> absolute path
# ----------------------
resolve_wallpaper() {
    local arg="$1" cand=""
    if [ -f "$arg" ]; then
        cand="$arg"
    elif [ -f "$ASSETS_DIR/$arg" ]; then
        cand="$ASSETS_DIR/$arg"
    else
        return 1
    fi
    if command -v realpath >/dev/null 2>&1; then
        realpath "$cand"
    else
        readlink -f "$cand"
    fi
}

# ----------------------
# is_video <path>
# ----------------------
is_video() {
    case "${1,,}" in
        *.mp4 | *.mkv | *.webm) return 0 ;;
        *) return 1 ;;
    esac
}

# ----------------------
# thumb_for <wallpaper-path> -> thumbnail path (videos only)
# ----------------------
thumb_for() {
    local base
    base="$(basename "$1")"
    printf '%s/%s.jpg' "$THUMBS_DIR" "${base%.*}"
}

# ----------------------
# ensure_thumb <wallpaper-path>
# Images need nothing (the picker loads them directly); videos get a
# middle-frame thumbnail so they preview instead of a play placeholder.
# ----------------------
ensure_thumb() {
    local wall="$1"
    is_video "$wall" || return 0

    local thumb
    thumb="$(thumb_for "$wall")"
    [ -f "$thumb" ] && return 0

    mkdir -p "$THUMBS_DIR"

    local dur="0" mid="5"
    if command -v ffprobe >/dev/null 2>&1; then
        dur=$(ffprobe -v error -show_entries format=duration \
            -of default=noprint_wrappers=1:nokey=1 "$wall" 2>/dev/null || echo 0)
    fi
    mid=$(python3 -c "d=float('${dur}'.strip() or 0); print(d/2 if d>0 else 5)" 2>/dev/null || echo 5)

    ffmpeg -v error -y -ss "$mid" -i "$wall" -frames:v 1 \
        -vf scale=512:-1 -q:v 3 "$thumb" 2>/dev/null || rm -f "$thumb"
}

# ----------------------
# autotheme_valid — the shell reads this file live, never write garbage
# ----------------------
autotheme_valid() {
    [ -f "$AUTOTHEME_JSON" ] || return 1
    jq -e '
        [.bg, .bgSolid, .border, .fg, .bright, .muted,
         .hover, .accent, .accentSoft, .critical]
        | all(test("^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$"))
    ' "$AUTOTHEME_JSON" >/dev/null 2>&1
}

# ----------------------
# strip6 <#RRGGBB|#AARRGGBB> -> RRGGBB
# ----------------------
strip6() {
    local h="${1#\#}"
    if [ "${#h}" -eq 8 ]; then
        h="${h:2}"
    fi
    if [[ "$h" =~ ^[0-9a-fA-F]{6}$ ]]; then
        printf '%s' "$h"
        return 0
    fi
    return 1
}

# ----------------------
# set_hypr_borders — window borders follow the generated accent, live.
# The Lua config rejects `hyprctl keyword`, so this goes through
# `hyprctl eval`. No-op when Hyprland isn't running or theme is invalid.
# ----------------------
set_hypr_borders() {
    command -v hyprctl >/dev/null 2>&1 || return 0
    autotheme_valid || return 0
    local acc inact
    acc="$(jq -r '.accent' "$AUTOTHEME_JSON")"
    inact="$(jq -r '.border' "$AUTOTHEME_JSON")"
    acc="$(strip6 "$acc")" || return 0
    inact="$(strip6 "$inact")" || inact="3a3f4b"
    hyprctl eval "hl.config({ general = { [\"col.active_border\"] = \"rgba(${acc}ee)\", [\"col.inactive_border\"] = \"rgba(${inact}aa)\" } })" >/dev/null 2>&1 || true
}

# ----------------------
# render_template_fallback <template> <output>
# Same matugen tokens, neutral values — single skeleton, no duplication.
# Fails if any token is left unsubstituted.
# ----------------------
render_template_fallback() {
    local args=(
        -e 's|{{image}}||g'
        -e 's|{{ image }}||g'
        -e 's|{{ colors.primary.dark.hex }}|#ffffff|g'
        -e 's|{{ colors.on_primary.dark.hex }}|#0a0a0c|g'
        -e 's|{{ colors.secondary.dark.hex }}|#8b8f98|g'
        -e 's|{{ colors.surface.dark.hex }}|#0a0a0c|g'
        -e 's|{{ colors.on_surface.dark.hex }}|#e6e6e6|g'
        -e 's|{{ colors.primary.dark.red }}|255|g'
        -e 's|{{ colors.primary.dark.green }}|255|g'
        -e 's|{{ colors.primary.dark.blue }}|255|g'
        -e 's|{{ colors.tertiary.dark.red }}|139|g'
        -e 's|{{ colors.tertiary.dark.green }}|143|g'
        -e 's|{{ colors.tertiary.dark.blue }}|152|g'
        -e 's|{{ vibrant.hex }}|#ffffff|g'
        -e 's|{{ vibrant_soft.hex }}|#8b8f98|g'
        -e 's|{{ vibrant_on.hex }}|#0a0a0c|g'
        -e 's|{{ vibrant.red }}|255|g'
        -e 's|{{ vibrant.green }}|255|g'
        -e 's|{{ vibrant.blue }}|255|g'
        -e 's|{{ vibrant_soft.red }}|139|g'
        -e 's|{{ vibrant_soft.green }}|143|g'
        -e 's|{{ vibrant_soft.blue }}|152|g'
    )
    # terminal palette (neutral floor, mirrors write_ghostty_theme_neutral)
    local terms=(0a0a0c ff5f5f 8b8f98 b8bcc4 ffffff 6e737d a7adb8 e6e6e6
        3a3f4b ff8a8a a7adb8 d4d8df ffffff 8b8f98 c2c7d1 ffffff)
    local i
    for i in "${!terms[@]}"; do
        args+=(-e "s|{{ term$i.hex }}|#${terms[$i]}|g")
    done
    sed "${args[@]}" "$1" > "$2" || return 1
    ! grep -q '{{' "$2" 2>/dev/null
}

# ----------------------
# write_all_fallbacks — neutral versions of every generated file
# ----------------------
write_all_fallbacks() {
    local wall="$1"
    write_fallback_autotheme "$wall"
    write_ghostty_theme_neutral
    render_template_fallback "$HYPLOCK_TEMPLATE" "$HYPLOCK_CONF" || true
    render_template_fallback "$GTK3_TEMPLATE" "$GTK3_CSS" || true
    render_template_fallback "$GTK4_TEMPLATE" "$GTK4_CSS" || true
    reload_ghostty
}

# ----------------------
# reload_ghostty — ghostty reloads its config (and theme file) on SIGUSR2
# ----------------------
reload_ghostty() {
    pkill -SIGUSR2 ghostty 2>/dev/null || true
}

# ----------------------
# write_ghostty_theme_neutral — static terminal theme matching the
# neutral fallback palette (grayscale wallpapers, matugen missing/failed)
# ----------------------
write_ghostty_theme_neutral() {
    mkdir -p "$(dirname "$GHOSTTY_THEME")"
    cat > "$GHOSTTY_THEME" <<EOF
# Generated by wallpaper_switch.sh (neutral fallback) — do not edit.
background = #0a0a0c
foreground = #e6e6e6
cursor-color = #ffffff
cursor-text = #0a0a0c
selection-background = #3a3f4b
selection-foreground = #ffffff
palette = 0=#0a0a0c
palette = 1=#ff5f5f
palette = 2=#8b8f98
palette = 3=#b8bcc4
palette = 4=#ffffff
palette = 5=#6e737d
palette = 6=#a7adb8
palette = 7=#e6e6e6
palette = 8=#3a3f4b
palette = 9=#ff8a8a
palette = 10=#a7adb8
palette = 11=#d4d8df
palette = 12=#ffffff
palette = 13=#8b8f98
palette = 14=#c2c7d1
palette = 15=#ffffff
EOF
}

# ----------------------
# write_fallback_autotheme <wallpaper-path>
# Static dark palette so the shell never breaks when matugen is
# missing or fails. Not a selectable theme, just an emergency floor.
# ----------------------
write_fallback_autotheme() {
    mkdir -p "$(dirname "$AUTOTHEME_JSON")"
    cat > "$AUTOTHEME_JSON" <<EOF
{
  "wallpaper": "$1",
  "mode": "dark",
  "source": "#8b8f98",
  "bg": "#c70a0a0c",
  "bgSolid": "#b80a0a0c",
  "border": "#1c1f26",
  "fg": "#e6e6e6",
  "bright": "#ffffff",
  "muted": "#8b8f98",
  "hover": "#3a3f4b",
  "accent": "#ffffff",
  "accentSoft": "#8b8f98",
  "critical": "#ff5f5f",
  "radius": 10,
  "fontFamily": "JetBrainsMono Nerd Font Mono",
  "fontSize": 13
}
EOF
}

# ----------------------
# generate_autotheme <wallpaper-path>
# Two-stage, one-shot (~300-500ms), zero idle cost:
#   1. vibrant.py extracts the wallpaper's own most-vivid hues (M3 dark
#      roles are pastel by spec and wash saturated images out).
#   2. matugen renders every generated file through an isolated temp
#      config (user config never touched, wallpaper never set by matugen),
#      with the vibrant hues injected via --import-json.
# Grayscale images (extractor exit 2) and matugen missing/failing fall
# back to the neutral static theme. Window borders apply live via
# hyprctl on every path.
# ----------------------
generate_autotheme() {
    local wall="$1" src="$1" frame="" vib="" vib_rc=0

    if is_video "$wall"; then
        frame="$(mktemp --suffix=.png)"
        local dur="0" mid="5"
        if command -v ffprobe >/dev/null 2>&1; then
            dur=$(ffprobe -v error -show_entries format=duration \
                -of default=noprint_wrappers=1:nokey=1 "$wall" 2>/dev/null || echo 0)
        fi
        mid=$(python3 -c "d=float('${dur}'.strip() or 0); print(d/2 if d>0 else 5)" 2>/dev/null || echo 5)
        if ffmpeg -v error -y -ss "$mid" -i "$wall" -frames:v 1 "$frame" 2>/dev/null; then
            src="$frame"
        else
            rm -f "$frame"
            frame=""
        fi
    fi

    # Stage 1: vivid hues from the image itself. Exit 2 means grayscale
    # (neutral theme, silent); any other failure is a real error.
    vib="$(mktemp --suffix=.json)"
    python3 "$VIBRANT_PY" "$src" "$vib" 2>/dev/null
    vib_rc=$?
    if [ "$vib_rc" -ne 0 ]; then
        rm -f "$vib"
        [ -n "$frame" ] && rm -f "$frame"
        write_all_fallbacks "$wall"
        set_hypr_borders
        if [ "$vib_rc" -eq 2 ]; then
            return 0
        fi
        notify_err "Autotheme" "Accent extraction failed, using fallback palette"
        return 1
    fi

    local ok=1
    if command -v matugen >/dev/null 2>&1 && [ -f "$AUTOTHEME_TEMPLATE" ]; then
        local tmpcfg
        tmpcfg="$(mktemp)"
        cat > "$tmpcfg" <<EOF
[config]
version_check = false
caching = false
prefer = "saturation"
[config.wallpaper]
set = false
command = "true"
[templates.autotheme]
input_path = "$AUTOTHEME_TEMPLATE"
output_path = "$AUTOTHEME_JSON"
[templates.ghostty]
input_path = "$GHOSTTY_TEMPLATE"
output_path = "$GHOSTTY_THEME"
post_hook = "pkill -SIGUSR2 ghostty"
[templates.hyprlock]
input_path = "$HYPLOCK_TEMPLATE"
output_path = "$HYPLOCK_CONF"
[templates.gtk3]
input_path = "$GTK3_TEMPLATE"
output_path = "$GTK3_CSS"
[templates.gtk4]
input_path = "$GTK4_TEMPLATE"
output_path = "$GTK4_CSS"
EOF
        mkdir -p "$(dirname "$AUTOTHEME_JSON")" "$(dirname "$GHOSTTY_THEME")" \
            "$(dirname "$HYPLOCK_CONF")" "$(dirname "$GTK3_CSS")" "$(dirname "$GTK4_CSS")"
        if matugen image "$src" --mode dark --config "$tmpcfg" \
                --import-json "$vib" >/dev/null 2>&1 \
            && autotheme_valid && [ -f "$GHOSTTY_THEME" ] \
            && [ -f "$HYPLOCK_CONF" ] && [ -f "$GTK3_CSS" ] && [ -f "$GTK4_CSS" ] \
            && ! grep -q '{{' "$HYPLOCK_CONF" "$GTK3_CSS" "$GTK4_CSS" "$GHOSTTY_THEME" \
                "$AUTOTHEME_JSON" 2>/dev/null; then
            # matugen records its actual input in {{image}} — for videos
            # that is the temp frame, so pin the real wallpaper path.
            local fixed
            fixed="$(mktemp)"
            if jq --arg w "$wall" '.wallpaper = $w' "$AUTOTHEME_JSON" > "$fixed" \
                && mv "$fixed" "$AUTOTHEME_JSON" && autotheme_valid; then
                ok=0
            else
                rm -f "$fixed"
            fi
        fi
        rm -f "$tmpcfg" "$vib"
    fi

    [ -n "$frame" ] && rm -f "$frame"

    if [ "$ok" -ne 0 ]; then
        write_all_fallbacks "$wall"
        set_hypr_borders
        notify_err "Autotheme" "matugen failed, using fallback dark palette"
        return 1
    fi
    set_hypr_borders
    return 0
}

# ----------------------
# apply_gtk_dark — fixed dark furniture for GTK apps + file picker
# ----------------------
apply_gtk_dark() {
    local gtk3_ini="$HOME/.config/gtk-3.0/settings.ini"
    local gtk4_ini="$HOME/.config/gtk-4.0/settings.ini"

    mkdir -p "$(dirname "$gtk3_ini")" "$(dirname "$gtk4_ini")"

    for ini in "$gtk3_ini" "$gtk4_ini"; do
        cat > "$ini" <<EOF
[Settings]
gtk-theme-name=$GTK_THEME
gtk-icon-theme-name=$ICON_THEME
gtk-font-name=$FONT_NAME
gtk-cursor-theme-name=$CURSOR_THEME
gtk-cursor-theme-size=$CURSOR_SIZE
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
        gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface cursor-size "$CURSOR_SIZE" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface font-name "$FONT_NAME" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" 2>/dev/null || true
        gsettings set org.gnome.desktop.wm.preferences theme "$GTK_THEME" 2>/dev/null || true
    fi
}
