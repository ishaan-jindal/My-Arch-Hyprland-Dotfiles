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
# mean_saturation <image> -> 0..1 (1 when unmeasurable, i.e. assume color)
# ----------------------
mean_saturation() {
    magick "$1" -resize 64x64 -colorspace HSL -channel S -separate +channel \
        -format "%[fx:mean]" info: 2>/dev/null || echo 1
}

# ----------------------
# is_monochrome <image>
# True grayscale has no hue for matugen to work with — it falls back to a
# hardcoded blue (#4285f4), painting grey wallpapers blue. Catch that case
# here so they get a neutral theme instead.
# ----------------------
is_monochrome() {
    local s
    s="$(mean_saturation "$1")"
    python3 -c "import sys; sys.exit(0 if float('$s') < 0.012 else 1)" 2>/dev/null
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
  "bgSolid": "#f20a0a0c",
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
# Runs matugen once (dark-only) through an isolated temp config so the
# user's own ~/.config/matugen/config.toml (if any) can never set the
# wallpaper or inject templates. Grayscale images skip matugen (it would
# fall back to hardcoded blue) and get the neutral theme; matugen
# missing/failing falls back to the static palette.
# One-shot cost (~200-400ms), zero idle cost.
# ----------------------
generate_autotheme() {
    local wall="$1" src="$1" frame=""

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

    # Grayscale has no hue: matugen would fall back to hardcoded blue, so
    # use the neutral theme directly (not an error, no notification).
    if is_monochrome "$src"; then
        [ -n "$frame" ] && rm -f "$frame"
        write_fallback_autotheme "$wall"
        return 0
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
EOF
        mkdir -p "$(dirname "$AUTOTHEME_JSON")"
        if matugen image "$src" --mode dark --config "$tmpcfg" >/dev/null 2>&1 \
            && autotheme_valid; then
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
        rm -f "$tmpcfg"
    fi

    [ -n "$frame" ] && rm -f "$frame"

    if [ "$ok" -ne 0 ]; then
        write_fallback_autotheme "$wall"
        notify_err "Autotheme" "matugen failed, using fallback dark palette"
        return 1
    fi
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
