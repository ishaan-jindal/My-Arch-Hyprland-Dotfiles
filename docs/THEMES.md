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
Selecting one runs `wallpaper_switch.sh apply <path>`, which:

1. Paints the wallpaper via `awww` (images, random `wave`/`wipe`
   transition each time) or `mpvpaper` (videos).
2. Updates `~/.config/hypr/themes/wallpapers/current` and
   `~/.cache/wallpaper_state` (single file, just a path).
3. Runs `matugen image <file> --mode dark` once through an isolated temp
   config (your own `~/.config/matugen/config.toml`, if any, is never
   touched and matugen never sets the wallpaper itself). Videos are sampled
   via a middle frame extracted with `ffmpeg`. Cost is one ~200-400 ms run
   per switch; nothing runs in the background afterwards.
4. Writes `~/.cache/autotheme.json` — `bg/bgSolid/border/fg/bright/muted/
   hover/accent/accentSoft/critical` mapped from the Material You dark
   palette (`accent` = primary, `accentSoft` = tertiary for a second hue),
   `radius`/`fontFamily`/`fontSize` fixed. Grayscale images skip matugen
   (it would fall back to hardcoded blue) and get a neutral monochrome
   theme instead. If matugen is missing or fails, a static dark fallback
   is written so the shell never breaks.
5. Syncs the fixed dark GTK furniture (`Orchis-Dark`, `Papirus-Dark`,
   `Bibata-Modern-Classic`, `prefer-dark`) and the Limine boot menu (best
   effort, needs the sudoers rule). Note: the root-owned copy must match
   the repo — after pulling a `limine-deploy` change, reinstall it:

   ```bash
   sudo install -m755 ~/dotfiles/limine/scripts/limine-deploy /usr/local/bin/limine-deploy
   sudo /usr/local/bin/limine-deploy
   ```

The Quickshell shell watches `~/.cache/autotheme.json`, so the bar and every
popup re-theme live — no restart, no manual reload. Color changes
**cross-fade** (320 ms, `Theme.qml` palette blending). Re-selecting the same
wallpaper skips the matugen run when the generated file is still valid.

## Adding a wallpaper

Drop the file into `hypr/.config/hypr/themes/wallpapers/assets/`. That is
all — it appears in the picker on next open. Accepted formats: `.jpg`,
`.jpeg`, `.png` (via `awww`), `.mp4` (via `mpvpaper`).

Video thumbnails (`wallpapers/thumbs/<name>.jpg`, middle frame at 512px)
generate automatically on first apply; `thumbs/` is a gitignored cache.
`wallpaper_switch.sh ensure-thumbs` backfills them all at once.

## State files

- `~/.cache/wallpaper_state` — absolute path of the current wallpaper
- `~/.cache/autotheme.json` — generated dark palette (read by Quickshell
  and `limine-deploy`)

The script is CLI-friendly too:

```bash
~/.config/hypr/scripts/wallpaper_switch.sh apply ~/Pictures/mine.png
~/.config/hypr/scripts/wallpaper_switch.sh list-json | jq '.[].name'
```
