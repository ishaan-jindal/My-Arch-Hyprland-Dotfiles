# My Arch Hyprland Dotfiles

Opinionated Hyprland desktop dotfiles for Arch Linux, managed with **GNU Stow**.

The desktop shell is a full **Quickshell** setup — bar, launcher, session
menu, notification daemon, control centre and OSDs — auto-themed from the
current wallpaper via `matugen` (dark-only Material You).

This repository includes:

- Hyprland + Hyprlock configuration
- Quickshell shell (bar, launcher, session menu, notifications, control
  centre, OSDs) with wallpaper-driven autotheme
- Wallpaper switcher (`Super + T`) — the desktop palette follows the
  wallpaper, no theme configs to maintain
- A Neovim configuration (Lua-based)
- An install bootstrap script for core packages

---

## Documentation Index

- [Quick Start](docs/QUICKSTART.md)
- [Themes & Wallpaper Workflow](docs/THEMES.md)
- [Keybindings Reference](docs/KEYBINDS.md)
- [Quickshell Shell](docs/QUICKSHELL.md)

---

## Repository Layout

```text
.
├── hypr/       # Hyprland config, scripts, matugen template, wallpapers
├── quickshell/ # Quickshell shell (bar, launcher, session, notifications, OSD)
├── nvim/       # Neovim config
├── fish/       # Fish shell config
├── ghostty/    # Ghostty terminal config
├── gtk/        # GTK seed settings (overwritten by the wallpaper script)
├── xdg-portal/ # Portal preferences (gtk file picker + hyprland screencast)
├── limine/     # Boot menu theme sync scripts + assets
├── docs/       # Quick start, themes, keybindings, quickshell
├── install.sh  # Arch bootstrap script
└── README.md
```

---

## Included Features

- **Desktop shell** via Quickshell:
  - top bar (workspaces, clock, power profile, network, audio, CPU, memory,
    temperature, backlight, battery, system tray)
  - app launcher (apps + clipboard history)
  - slide-down wallpaper picker with live previews (image thumbnails)
  - session menu (`wlogout`-style), control centre with quick toggles
    (Wi-Fi / Bluetooth / DND / night light), system/display/power/sound
    sections, month calendar, MPRIS media, and transient notification popups
  - Wi-Fi panel (scan, connect, password prompt) and Bluetooth panel
    (scan, pair, connect, forget) — no `nm-applet`/`nmtui`/`blueman` needed
  - notification popups
  - volume/brightness/mic OSDs
  - `Super + K` keybind cheatsheet
- **Autotheme**: picking a wallpaper regenerates the shell palette from it
  (`matugen`, dark-only) — drop a file in the assets dir and it just works
- **Theme persistence** across reboots using cache files in `~/.cache`
- **Live re-theming**: the shell watches `~/.cache/autotheme.json`
- **Night light toggle** via `hyprsunset`

---

## Quick Usage

After setup and stowing:

- `Super + R` → app launcher
- `Super + L` → session menu (lock / logout / …)
- `Super + C` → control centre
- `Super + V` → clipboard history
- `Super + T` → wallpaper picker (desktop re-themes itself from the pick)
- `Super + K` → show all keybinds
- `Super + N` → toggle night light

See full tables and setup steps in [`docs/`](docs).

---

## Notes

- This setup assumes an Arch-based system.
- Quickshell is the only shell: Waybar, Wofi, Wlogout and Swaync are no
  longer used or installed.
- Theme scripts rely on assets being symlinked under `~/.config` via Stow.
- If you maintain local changes, keep them in your fork/branch and restow
  when needed.
