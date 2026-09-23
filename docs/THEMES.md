# Autotheme and Wallpaper Workflow

There are no themes to configure. The palette is generated from the current
wallpaper, every time, automatically:

- `hypr/.config/hypr/scripts/wallpaper_switch.sh apply <file>`
- `hypr/.config/hypr/scripts/lib/autotheme.sh` (shared helpers)
- `hypr/.config/hypr/scripts/templates/autotheme.json` (matugen template)
- `~/.cache/autotheme.json` (generated output, watched live by Quickshell)

## How it works

`Super + T` opens the wallpaper picker, which lists **every** image/video in
`hypr/.config/hypr/themes/wallpapers/assets/` (live scan, sorted by name).
Selecting one runs `wallpaper_switch.sh apply <path>`, which in a single
~300 ms pass:

1. Paints the wallpaper via `awww` (images, random `wave`/`wipe`
   transition each time) or `mpvpaper` (videos).
2. Updates `~/.config/hypr/themes/wallpapers/current` and
   `~/.cache/wallpaper_state` (single file, just a path).
3. Runs `matugen image <file> --mode dark` once through an isolated temp
   config (your own `~/.config/matugen/config.toml`, if any, is never
   touched and matugen never sets the wallpaper itself). Videos are sampled
   via a middle frame extracted with `ffmpeg`. Because Material You dark
   roles are pastel by spec, a first stage (`lib/vibrant.py`, stdlib +
   ImageMagick) extracts the wallpaper's own most-vivid hues and injects
   them via `--import-json` — surfaces stay harmonious M3, accents stay
   punchy. Cost is one ~300-500 ms run per switch; nothing runs in the
   background afterwards.
4. Renders every themed surface from matugen templates — no per-app configs:
   - `~/.cache/autotheme.json` → Quickshell shell (watches it live,
     cross-fades over 320 ms)
   - `~/.config/ghostty/themes/autotheme` → terminal (live-reloads via
     `SIGUSR2`)
   - `~/.config/hypr/hyprlock.conf` (from `hyprlock.conf.template`) →
     lock-screen input ring + check color on next lock
   - `~/.config/gtk-3.0/gtk.css` + `~/.config/gtk-4.0/gtk.css` → GTK
     selection/accent colors on app restart
5. Applies Hyprland window borders live (`col.active_border` = accent,
   `col.inactive_border` = surface tint) via `hyprctl eval`.
6. Syncs the fixed dark GTK furniture (`Orchis-Dark`, `Papirus-Dark`,
   `Bibata-Modern-Classic`, `prefer-dark`) and the Limine boot menu (best
   effort, needs the sudoers rule). Note: the root-owned copy must match
   the repo — after pulling a `limine-deploy` change, reinstall it:

   ```bash
   sudo install -m755 ~/dotfiles/limine/scripts/limine-deploy /usr/local/bin/limine-deploy
   sudo /usr/local/bin/limine-deploy
   ```

The generated layer is fully derived: `~/.cache/autotheme.json` carries
`bg/bgSolid/border/fg/bright/muted/hover/accent/accentSoft/critical`
(surfaces + text from M3 dark; `accent`/`bright` = extracted vivid hero,
`accentSoft` = second vivid hue for a real second color).
Grayscale images (no vivid cluster) get a neutral monochrome theme instead
of matugen's hardcoded-blue fallback; if matugen is missing or fails, a
static dark fallback is written so the shell never breaks. Fallback paths
render every template from the same skeletons via `render_template_fallback`,
so there is exactly one source of truth per file.

The Quickshell shell watches `~/.cache/autotheme.json`, so the bar and every
popup re-theme live — no restart, no manual reload. Color changes
**cross-fade** (320 ms, `Theme.qml` palette blending). Re-selecting the same
wallpaper skips the matugen run when the generated file is still valid.

## Adding a wallpaper

Drop the file into `hypr/.config/hypr/themes/wallpapers/assets/`. That is
all — it appears in the picker on next open. Accepted formats: `.jpg`,
`.jpeg`, `.png` (via `awww`), `.mp4`, `.mkv`, `.webm` (via `mpvpaper`).

Video thumbnails (`wallpapers/thumbs/<name>.jpg`, middle frame at 512px)
generate automatically on first apply; `thumbs/` is a gitignored cache.
`wallpaper_switch.sh ensure-thumbs` backfills them all at once.

## Ghostty follows too

The same run renders `~/.config/ghostty/themes/autotheme` and ghostty
live-reloads it via `SIGUSR2` — open terminals re-theme with the wallpaper.
Background/foreground/cursor/selection come from M3 roles (lifted tinted
background, never pure black); the 16 ANSI colors are extracted from the
image itself per hue family (missing hues get tinted greys, never dead
grey), so listings and diffs stay colorful yet readable. The repo
`ghostty/config` sets `theme = autotheme`; the generated file is gitignored.
Grayscale/matugen-failure writes a matching neutral terminal theme instead.
Fresh clone before the first apply: ghostty warns once and uses its default
until then.

## State files

- `~/.cache/wallpaper_state` — absolute path of the current wallpaper
- `~/.cache/autotheme.json` — generated dark palette (read by Quickshell
  and `limine-deploy`)

The script is CLI-friendly too:

```bash
~/.config/hypr/scripts/wallpaper_switch.sh apply ~/Pictures/mine.png
~/.config/hypr/scripts/wallpaper_switch.sh list-json | jq '.[].name'
```
