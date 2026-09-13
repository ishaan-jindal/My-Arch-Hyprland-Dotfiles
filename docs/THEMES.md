# Themes and Wallpaper Workflow

The desktop theme system is handled by:

- `hypr/.config/hypr/scripts/theme_toggle.sh`
- `hypr/.config/hypr/scripts/wallpaper_switch.sh`
- `hypr/.config/hypr/themes/themes.json` (single source of truth)

## Available themes

- obsidian (minimal monochrome) -> GTK `Orchis-Dark`
- crimson (sharp red) -> GTK `Orchis-Dark` + red swaync accent
- aether (clean blue) -> GTK `adw-gtk3-dark`
- ember (warm gruvbox) -> GTK `Dracula`
- drift (ambient pastel) -> GTK `adw-gtk3-dark`
- windows (fluent) -> GTK `adw-gtk3-dark`

All themes use `Papirus-Dark` icons, `Bibata-Modern-Classic` cursor, `prefer-dark` color-scheme.
`Orchis-*-Red/Blue` variants are not in the current `extra/orchis-theme` build, so red/blue
accents live in swaync/waybar/wofi CSS until the AUR `gruvbox/catppuccin` themes are added.

## How theme switching works

When you run **theme toggle** (`Super + Shift + T`):

1. A `wofi` menu is shown.
2. Selected theme resources are mapped:
   - Waybar config and style
   - Wofi style
   - Wlogout style
   - Wallpaper directory
   - GTK theme (`gtk-3.0/settings.ini` + `gtk-4.0/settings.ini` + `gsettings`)
   - Swaync config and style (`~/.config/swaync/`)
3. Symlinks are updated:
   - `~/.config/waybar/config.jsonc`
   - `~/.config/waybar/style.css`
   - `~/.config/wofi/style.css`
   - `~/.config/wlogout/style.css`
   - `~/.config/hypr/themes/wallpapers/current`
   - `~/.config/swaync/config.json`
   - `~/.config/swaync/style.css`
4. `waybar` is restarted, `swaync` is reloaded (or started, `dunst` killed).
5. GTK file picker picks up the theme via `xdg-desktop-portal-gtk` + `portals.conf`
   (`FileChooser=gtk`) on next open — no reboot needed.
6. Theme and wallpaper state are saved in `~/.cache`.

## State files

The scripts track state in:

- `~/.cache/theme_state`
- `~/.cache/wallpaper_state_<theme>` (one per theme, e.g. `wallpaper_state_obsidian`)

This preserves your last selected wallpaper per theme.

## Wallpaper switching

`Super + T` opens wallpaper selection for the **current** theme only.

- Wallpapers are matched by tag in `themes.json` (`wallpapers[].tags` vs `themes.<name>.tags`)
- Accepted formats: `.jpg`, `.jpeg`, `.png` (images via `awww`), `.mp4` (video via `mpvpaper`)

## Adding a new theme

To add theme `mytheme`, create:

- `hypr/.config/hypr/themes/waybar/mytheme/style.css` (+ `config.jsonc`, or symlink
  `../base/config.jsonc` if the shared top-bar layout works for the theme)
- `hypr/.config/hypr/themes/wofi/mytheme/style.css`
- `hypr/.config/hypr/themes/wlogout/mytheme/style.css`
- `hypr/.config/hypr/themes/swaync/mytheme/style.css` (+ `config.json`, or symlink
  `../base/config.json` — all current themes share the same base config)
- Add wallpapers under `hypr/.config/hypr/themes/wallpapers/assets/` with `tags`
  including `mytheme` (or a descriptor your theme's `tags` include)

Then update `hypr/.config/hypr/themes/themes.json`:

- Add `components.gtk/mytheme`, `components.swaync/mytheme`, `components.icon/mytheme`
- Add `themes.mytheme.components` with `waybar/wofi/wlogout/gtk/swaync/icon` keys
