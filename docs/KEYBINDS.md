# Keybindings Reference

Main modifier: `SUPER`

## Launcher and session

- `Super + Return` → terminal (`ghostty`)
- `Super + R` → app launcher (Quickshell; `Esc` closes, `Enter` runs)
- `Super + B` → browser (`zen-browser`)
- `Super + E` → file manager (`nemo`)
- `Super + L` → session menu (Quickshell)

  Session menu keys: `l` lock · `h` hibernate · `e` logout · `s` shutdown ·
  `u` suspend · `r` reboot
- `Super + Q` → close active window

## Quickshell shell

- `Super + C` → control centre (Wi-Fi/Bluetooth/DND/night toggles, system,
  display, power, sound sections, calendar, media, notifications — bar
  widgets deep-link straight to their section)
- `Super + V` → clipboard history
- `Super + T` → wallpaper picker (current theme)
- `Super + Shift + T` → theme picker
- `Super + K` → keybind cheatsheet
- `Super + Shift + K` → stop Quickshell
- `Super + Shift + W` → start Quickshell

Launcher: type to filter · `↑ ↓` select · `Enter` run · `Tab` switch
apps/clipboard · `Esc` close.

Picker: `← → ↑ ↓` navigate · `Enter` apply · `Tab` switch themes/wallpapers ·
`Esc` close.

Control centre: `Tab` moves focus, `Space`/`Enter` activate, `← →` adjust the
volume slider / calendar day, `PgUp`/`PgDn` change month, `Esc` backs out
and closes. The Wi-Fi and Bluetooth views use
`↑ ↓` + `Enter`, `s` to scan, and `Del`/`f` to forget a device.

## Window controls

- `Super + A` → toggle floating
- `Super + F` → fullscreen
- `Super + P` → pin window
- `Super + J` → toggle split direction
- `Super + Left/Right/Up/Down` → move focus
- `Super + drag` → move window
- `Super + right-drag` → resize window

## Workspaces

- `Super + 1..0` → switch workspace 1..10
- `Super + Shift + 1..0` → move active window to workspace 1..10
- `Super + S` → toggle special workspace (`magic`)
- `Super + Shift + S` → move active window to special workspace
- `Super + mouse wheel` → cycle workspaces
- `3-finger swipe` → switch workspaces / special workspace

## Clipboard and screenshots

- `Super + V` → clipboard history (`cliphist` + Quickshell launcher)
- `Print` → region screenshot (`hyprshot`)

## Audio / brightness media keys

- `XF86AudioRaiseVolume` / `XF86AudioLowerVolume`
- `XF86AudioMute`
- `XF86AudioMicMute`
- `XF86AudioNext`, `XF86AudioPrev`, `XF86AudioPlay`, `XF86AudioPause`
- `XF86MonBrightnessUp` / `XF86MonBrightnessDown`

## Other

- `Super + N` → toggle night light (`hyprsunset`)
- `Super + Z` → toggle cursor zoom (2x, `zoom_toggle.sh`)
- `Super + M` → launch Android emulator command from config
