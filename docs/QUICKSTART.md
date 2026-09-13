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
sudo pacman -S hyprland hyprlock hyprshot hyprsunset waybar ghostty wofi wlogout swaync \
  awww jq libnotify wl-clipboard cliphist brightnessctl playerctl \
  network-manager-applet stow neovim ripgrep fd
yay -S mpvpaper
# Optional browser bound to Super+B:
# yay -S zen-browser-bin
```

## 3) Back up existing configs (recommended)

```bash
mkdir -p ~/.config-backup
mv ~/.config/hypr ~/.config-backup/hypr 2>/dev/null || true
mv ~/.config/waybar ~/.config-backup/waybar 2>/dev/null || true
mv ~/.config/wofi ~/.config-backup/wofi 2>/dev/null || true
mv ~/.config/wlogout ~/.config-backup/wlogout 2>/dev/null || true
mv ~/.config/nvim ~/.config-backup/nvim 2>/dev/null || true
mv ~/.config/gtk-3.0 ~/.config-backup/gtk-3.0 2>/dev/null || true
mv ~/.config/gtk-4.0 ~/.config-backup/gtk-4.0 2>/dev/null || true
mv ~/.config/fish ~/.config-backup/fish 2>/dev/null || true
mv ~/.config/ghostty ~/.config-backup/ghostty 2>/dev/null || true
mv ~/.config/swaync ~/.config-backup/swaync 2>/dev/null || true
mv ~/.config/xdg-desktop-portal ~/.config-backup/xdg-desktop-portal 2>/dev/null || true
```

## 4) Stow dotfiles

```bash
stow hypr nvim waybar wlogout wofi gtk xdg-portal fish ghostty
```

This creates symlinks into `~/.config`. Never use `stow *` — it would try to
stow `docs/` and other non-config dirs.

## 5) Start Hyprland and verify

At minimum, verify:

- `waybar` autostarts
- `nm-applet` appears
- `Super + Shift + T` opens the theme menu
- `Super + T` opens the wallpaper menu

## 6) Optional: Neovim plugins

Open Neovim — plugins install automatically via `lazy.nvim` on first launch.
Use `:Lazy` to manage/update them.

LSP servers install via `:Mason`. Formatters used by `conform.nvim`
(`prettier`, `stylua`, `black`, `gofumpt`, `clang-format`, etc.) must be
installed separately (`:Mason` or `pacman`) — otherwise format-on-save
falls back to LSP.

---

## Troubleshooting

### Theme switcher fails

Check that the stow symlinks exist:

```bash
ls -l ~/.config/waybar ~/.config/wofi ~/.config/wlogout ~/.config/hypr
```

### Wallpaper not changing

Ensure the wallpaper daemons are running (`awww` for images, `mpvpaper` for `.mp4`):

```bash
pgrep -x awww-daemon || awww-daemon
pgrep -x mpvpaper || true  # mpvpaper is started on-demand by the theme scripts
```

### Clipboard history binding fails

Install both:

- `wl-clipboard` (provides `wl-paste` / `wl-copy`)
- `cliphist`
