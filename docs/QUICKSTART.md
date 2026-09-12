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
sudo pacman -S hyprland hyprlock waybar ghostty wofi wlogout swww wl-clipboard cliphist \
  brightnessctl playerctl network-manager-applet stow neovim ripgrep
```

## 3) Back up existing configs (recommended)

```bash
mkdir -p ~/.config-backup
mv ~/.config/hypr ~/.config-backup/hypr 2>/dev/null || true
mv ~/.config/waybar ~/.config-backup/waybar 2>/dev/null || true
mv ~/.config/wofi ~/.config-backup/wofi 2>/dev/null || true
mv ~/.config/wlogout ~/.config-backup/wlogout 2>/dev/null || true
mv ~/.config/nvim ~/.config-backup/nvim 2>/dev/null || true
```

## 4) Stow dotfiles

```bash
stow hypr nvim waybar wlogout wofi gtk xdg-portal
```

This creates symlinks into `~/.config`.

## 5) Start Hyprland and verify

At minimum, verify:

- `waybar` autostarts
- `nm-applet` appears
- `Super + Shift + T` opens the theme menu
- `Super + T` opens the wallpaper menu

## 6) Optional: Neovim plugins

Open Neovim and install plugins:

```vim
:PlugInstall
```

---

## Troubleshooting

### Theme switcher fails

Check that the stow symlinks exist:

```bash
ls -l ~/.config/waybar ~/.config/wofi ~/.config/wlogout ~/.config/hypr
```

### Wallpaper not changing

Ensure `swww-daemon` is running:

```bash
pgrep -x swww-daemon || swww-daemon
```

### Clipboard history binding fails

Install both:

- `wl-clipboard` (provides `wl-paste` / `wl-copy`)
- `cliphist`
