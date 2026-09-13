# My Arch Hyprland Dotfiles

Opinionated Hyprland desktop dotfiles for Arch Linux, managed with **GNU Stow**.

This repository includes a complete desktop setup with:

- Hyprland + Hyprlock configuration
- Theme-aware Waybar / Wofi / Wlogout styling
- Wallpaper and theme switcher scripts
- A Neovim configuration (Lua-based)
- An install bootstrap script for core packages

---

## Documentation Index

- [Quick Start](docs/QUICKSTART.md)
- [Themes & Wallpaper Workflow](docs/THEMES.md)
- [Keybindings Reference](docs/KEYBINDS.md)

---

## Repository Layout

```text
.
├── hypr/       # Hyprland config, scripts, themes, wallpapers
├── waybar/     # Generated symlinks (active theme) — sources live under hypr/.../themes/waybar/
├── wofi/       # Generated symlink (active theme) — sources live under hypr/.../themes/wofi/
├── wlogout/    # Wlogout layout + generated symlink — sources under hypr/.../themes/wlogout/
├── nvim/       # Neovim config
├── fish/       # Fish shell config
├── ghostty/    # Ghostty terminal config
├── gtk/        # GTK seed settings (overwritten by theme_toggle.sh apply_gtk)
├── xdg-portal/ # Portal preferences (gtk file picker + hyprland screencast)
├── docs/       # Quick start, themes, keybindings
├── install.sh  # Arch bootstrap script
└── README.md
```

---

## Included Features

- **Theme switching UI** via `wofi` (`theme_toggle.sh`)
- **Wallpaper switching UI** for active theme (`wallpaper_switch.sh`)
- **Theme persistence** across switches using cache files in `~/.cache`
- **Waybar hot-reload** whenever theme changes
- **Night light toggle** via `hyprsunset`

---

## Quick Usage

After setup and stowing:

- `Super + Shift + T` → choose full desktop theme
- `Super + T` → choose wallpaper for current theme
- `Super + N` → toggle night light

See full tables and setup steps in [`docs/`](docs).

---

## Notes

- This setup assumes an Arch-based system.
- Theme scripts rely on assets being symlinked under `~/.config` via Stow.
- If you maintain local changes, keep them in your fork/branch and restow when needed.
