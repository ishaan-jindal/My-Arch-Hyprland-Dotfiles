# Themes and Wallpaper Workflow

The desktop theme system is handled by:

- `hypr/.config/hypr/themes/themes.json` (single source of truth)
- `hypr/.config/hypr/scripts/theme_toggle.sh apply <theme>`
- `hypr/.config/hypr/scripts/wallpaper_switch.sh apply <wallpaper-id>`

The Quickshell shell renders the themes itself: `Theme.qml` reads
`themes.json` plus `~/.cache/theme_state` and re-colors the bar, launcher,
control centre, session menu, notifications and OSDs live.

## Available themes

| Theme | Look | GTK theme | Accent |
| ----- | ---- | --------- | ------ |
| obsidian | minimal monochrome | `Orchis-Dark` | white |
| crimson | sharp red | `Orchis-Dark` | `#ff2a3d` |
| aether | clean blue / glassy | `adw-gtk3-dark` | `#7aa2f7` |
| ember | warm gruvbox | `Dracula` | `#e0af68` |
| drift | ambient pastel | `adw-gtk3-dark` | `#7aa2a9` / `#c792ea` |

All themes use `Papirus-Dark` icons, `Bibata-Modern-Classic` cursor,
`prefer-dark` color scheme and the JetBrainsMono Nerd Font.

The palettes live in `quickshell/.config/quickshell/Theme.qml`
(`palettes` object) — they were ported 1:1 from the old per-theme Waybar
stylesheets, which have since been removed.

## How theme switching works

`Super + Shift + T` opens the Quickshell launcher on the **Themes** page.
Selecting a theme runs `theme_toggle.sh apply <theme>`, which:

1. Applies the theme's wallpaper (last used for that theme, else the first
   wallpaper tagged for it) via `awww` (images) or `mpvpaper` (videos).
2. Updates `~/.config/hypr/themes/wallpapers/current`.
3. Syncs GTK: `gtk-3.0/settings.ini`, `gtk-4.0/settings.ini` and
   `gsettings` (theme, icons, cursor, font, color-scheme).
4. Writes `~/.cache/theme_state` and `~/.cache/wallpaper_state_<theme>`.
5. Syncs the Limine boot menu (best effort, needs the sudoers rule).

The Quickshell shell watches `~/.cache/theme_state`, so the bar and every
popup re-theme live — no restart, no manual reload. Color changes
**cross-fade** (320 ms, `Theme.qml` palette blending), and the wallpaper is
applied with the same `awww -t wipe` transition as the wallpaper picker
(both scripts share `hypr/scripts/lib/wallpaper.sh`). The GTK file
picker picks the theme up via `xdg-desktop-portal-gtk` + `portals.conf`
(`FileChooser=gtk`) on next open.

## State files

- `~/.cache/theme_state` — active theme name (read by Quickshell)
- `~/.cache/wallpaper_state_<theme>` — last wallpaper per theme

## Wallpaper switching

`Super + T` opens the Quickshell launcher on the **Wallpapers** page, listing
wallpapers for the **current** theme only.

- Matching: `wallpapers[].tags` intersects `themes.<name>.tags` in `themes.json`
- Formats: `.jpg`, `.jpeg`, `.png` (via `awww`), `.mp4` (via `mpvpaper`)
- Selection runs `wallpaper_switch.sh apply <id>` and updates the state files

Both scripts are CLI-only now (`apply <arg>`); the pickers live in
Quickshell. Running them without arguments prints usage.

## Adding a new theme

1. Add the palette to `Theme.qml` (`palettes` object) — copy an existing
   entry and adjust `bg`/`border`/`fg`/`muted`/`hover`/`accent`/
   `accentSoft`/`critical`, `radius`, `fontFamily`, `fontSize`.
   Colors are `#AARRGGBB` strings (alpha first).
2. Add wallpapers under `hypr/.config/hypr/themes/wallpapers/assets/` with
   `tags` containing the new theme name. Tag by content and mood against the
   theme tag pools (`obsidian/dark/minimal`, `crimson/red/dark`,
   `aether/light/blue/clean`, `ember/warm/gold`, `drift/calm/ambient`) —
   a wallpaper matches every theme sharing at least one tag.
   For `.mp4` wallpapers also generate the picker thumbnail (middle frame,
   512px wide) so videos preview instead of showing a play placeholder:

   ```bash
   dur=$(ffprobe -v error -show_entries format=duration \
     -of default=noprint_wrappers=1:nokey=1 file.mp4)
   ffmpeg -y -ss $(python3 -c "print($dur/2)") -i file.mp4 -frames:v 1 \
     -vf scale=512:-1 -q:v 3 \
     hypr/.config/hypr/themes/wallpapers/thumbs/<id>.jpg
   ```
3. Add the theme to `hypr/.config/hypr/themes/themes.json`:

```json
"mytheme": {
  "tags": ["mytheme", "dark"],
  "components": { "gtk": "mytheme", "icon": "mytheme" }
}
```

plus `components.gtk.mytheme` / `components.icon.mytheme` entries.

No symlinks, no per-app stylesheets: the palette is the theme.
