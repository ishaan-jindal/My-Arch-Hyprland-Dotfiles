# Quick Start

## 1) Clone

```bash
git clone https://github.com/SacredNightmare99/My-Arch-Hyprland-Dotfiles ~/.dotfiles
cd ~/.dotfiles
```

## 2) Install dependencies

Use the bootstrap script:

```bash
bash install.sh
```

Or install manually (example subset):

```bash
sudo pacman -S hyprland hyprlock hyprshot hyprsunset quickshell upower ghostty \
  awww matugen jq ffmpeg imagemagick libnotify wl-clipboard cliphist \
  brightnessctl playerctl stow neovim ripgrep fd
yay -S mpvpaper
# Optional browser bound to Super+B:
# yay -S zen-browser-bin
```

`quickshell` is the desktop shell (bar, launcher, session menu, notifications,
control centre, OSDs). Waybar/Wofi/Wlogout/Swaync are **not** needed.

## 3) Back up existing configs (recommended)

```bash
mkdir -p ~/.config-backup
mv ~/.config/hypr ~/.config-backup/hypr 2>/dev/null || true
mv ~/.config/quickshell ~/.config-backup/quickshell 2>/dev/null || true
mv ~/.config/nvim ~/.config-backup/nvim 2>/dev/null || true
mv ~/.config/gtk-3.0 ~/.config-backup/gtk-3.0 2>/dev/null || true
mv ~/.config/gtk-4.0 ~/.config-backup/gtk-4.0 2>/dev/null || true
mv ~/.config/fish ~/.config-backup/fish 2>/dev/null || true
mv ~/.config/ghostty ~/.config-backup/ghostty 2>/dev/null || true
mv ~/.config/xdg-desktop-portal ~/.config-backup/xdg-desktop-portal 2>/dev/null || true
```

## 4) Stow dotfiles

```bash
stow hypr nvim quickshell gtk xdg-portal fish ghostty
```

This creates symlinks into `~/.config`. Never use `stow *` — it would try to
stow `docs/` and other non-config dirs.

## 5) Start Hyprland and verify

At minimum, verify:

- the Quickshell bar appears at the top (workspaces, clock, status modules)
- `Super + C` shows the control centre, with working Wi-Fi and Bluetooth panels
  (no `nm-applet`/`blueman` tray applets needed)
- `Super + R` opens the app launcher
- `Super + K` shows the keybind cheatsheet
- `Super + T` opens the wallpaper picker and re-themes the bar live from
  the selected wallpaper (matugen, dark-only)

Shell not starting? Run `quickshell` in a terminal and watch for QML errors,
then check `qs ipc call shell diagnostics`.

See [QUICKSHELL.md](QUICKSHELL.md) for the full shell reference,
[THEMES.md](THEMES.md) for the theme pipeline and [KEYBINDS.md](KEYBINDS.md)
for every bind.

## 6) Optional: Neovim plugins

Open Neovim — plugins install automatically via `lazy.nvim` on first launch.
Use `:Lazy` to manage/update them.

LSP servers install via `:Mason`. Formatters used by `conform.nvim`
(`prettier`, `stylua`, `black`, `gofumpt`, `clang-format`, etc.) must be
installed separately (`:Mason` or `pacman`) — otherwise format-on-save
falls back to LSP.

---

## Troubleshooting

### Quickshell fails to start

```bash
pgrep -x quickshell || quickshell   # run in the foreground to see errors
qs ipc call shell diagnostics       # JSON state dump
```

Check that the stow symlinks exist:

```bash
ls -l ~/.config/quickshell/shell.qml ~/.config/hypr/themes/wallpapers/assets | head
```

### Theme doesn't change

Make sure matugen runs and the state files are writable:

```bash
matugen image ~/.config/hypr/themes/wallpapers/assets/red.jpg --mode dark --show-colors | head
cat ~/.cache/wallpaper_state
jq . ~/.cache/autotheme.json | head -20
~/.config/hypr/scripts/wallpaper_switch.sh apply red.jpg
```

### Wallpaper not changing

Ensure the wallpaper daemons are running (`awww` for images, `mpvpaper` for `.mp4`):

```bash
pgrep -x awww-daemon || awww-daemon
pgrep -x mpvpaper || true  # mpvpaper is started on-demand by the theme scripts
```

### Clipboard history empty/broken

Install both:

- `wl-clipboard` (provides `wl-paste` / `wl-copy`)
- `cliphist`

The watchers are started by `hyprland.lua` on login; the launcher clipboard
page is `Super + V`.
