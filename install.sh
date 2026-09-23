#!/usr/bin/env bash

# Stop on first error
set -e

# --- CONFIGURATION ---
# Keep this list in sync with:
# - hypr/.config/hypr/hyprland.lua (binds: ghostty, quickshell/qs, zen-browser,
#   nemo, hyprshot, cliphist/wl-clipboard, brightnessctl, playerctl)
# - hypr/.config/hypr/scripts/*.sh (awww, mpvpaper, matugen, jq, ffmpeg/ffprobe,
#   notify-send, imagemagick for limine-deploy)
# - quickshell/.config/quickshell (Pipewire audio, UPower battery, NetworkManager
#   Wi-Fi panel, BlueZ Bluetooth panel, platform menu tray)
pacman_packages=(
    "hyprland"
    "hyprlock"
    "hyprshot"
    "hyprsunset"
    "quickshell"
    "upower"
    "ghostty"
    "nemo"
    "awww"
    "matugen"
    "jq"
    "python"
    "ffmpeg"
    "imagemagick"
    "libnotify"
    "wl-clipboard"
    "cliphist"
    "brightnessctl"
    "playerctl"
    "neovim"
    "ripgrep"
    "fd"
    "adw-gtk-theme"
    "orchis-theme"
    "papirus-icon-theme"
    "nwg-look"
    "xdg-desktop-portal-hyprland"
    "xdg-desktop-portal-gtk"
    "polkit-kde-agent"
    "pipewire"
    "wireplumber"
    "qt5-wayland"
    "qt6-wayland"
    "noto-fonts"
    "noto-fonts-cjk"
    "noto-fonts-emoji"
    "ttf-font-awesome"
    "ttf-nerd-fonts-symbols"
    "ttf-jetbrains-mono-nerd"
    "stow"
    "git"
    "fish"
    "base-devel"
)

aur_packages=(
    "mpvpaper"
    # Browser bound to Super+B in hyprland.lua:
    "zen-browser-bin"
    # Optional 1:1 accents — skipped by default, gtk2 build pulls ~400MB+ GNOME/gtk clone.
    # "gruvbox-gtk-theme-git"
    # "catppuccin-gtk-theme-mocha"
)
# Stow packages in this repo (must match top-level dirs with .config/).
stow_packages=(
    "hypr"
    "nvim"
    "quickshell"
    "gtk"
    "xdg-portal"
    "fish"
    "ghostty"
)
# --- END CONFIGURATION ---


# --- HELPER FUNCTIONS ---
install_yay() {
    if ! command -v yay &> /dev/null; then
        echo "yay (AUR helper) not found. Installing..."
        sudo pacman -S --needed base-devel git
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        (cd /tmp/yay && makepkg -si --noconfirm)
        rm -rf /tmp/yay
        echo "yay installed successfully."
    else
        echo "yay is already installed."
    fi
}

# --- MAIN SCRIPT ---
echo "Starting setup..."

# 1. Install Pacman packages
echo "Installing Pacman packages..."
sudo pacman -Syu --needed --noconfirm "${pacman_packages[@]}"

# 2. Install AUR Helper (yay)
install_yay

# 3. Install AUR packages (skip when every entry is commented out)
# Filter out comment placeholders: bash keeps them out already, but guard empty array
# for `set -u` safety and to avoid `yay -S` with no targets.
if [ "${#aur_packages[@]}" -gt 0 ]; then
    echo "Installing AUR packages..."
    yay -S --needed --noconfirm "${aur_packages[@]}"
else
    echo "No AUR packages configured, skipping."
fi

# 4. Other setup commands
echo "Running post-install commands..."

# Change default shell to Fish
FISH_PATH="$(command -v fish)"
if [ -z "$FISH_PATH" ]; then
    echo "WARNING: fish not found after install, skipping chsh."
elif [ "$SHELL" != "$FISH_PATH" ]; then
    echo "Changing default shell to Fish ($FISH_PATH) for $(whoami)..."
    if grep -qx "$FISH_PATH" /etc/shells 2>/dev/null; then
        chsh -s "$FISH_PATH"
    else
        echo "WARNING: $FISH_PATH not in /etc/shells, skipping chsh."
        echo "Add it with: echo $FISH_PATH | sudo tee -a /etc/shells && chsh -s $FISH_PATH"
    fi
else
    echo "Default shell is already Fish."
fi

# Enable Pipewire
systemctl --user enable --now pipewire.service pipewire.socket pipewire-pulse.service

echo "-----------------------------------"
echo "Setup complete!"
echo "Back up existing configs first (see docs/QUICKSTART.md step 3), then run:"
echo "  stow ${stow_packages[*]}"
echo "Then, reboot your system."
echo "-----------------------------------"
