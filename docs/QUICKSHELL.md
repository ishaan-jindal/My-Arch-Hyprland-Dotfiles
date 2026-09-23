# Quickshell Shell

The desktop shell for this setup: bar, launcher, session menu, notification
daemon, control centre and OSDs — all implemented in Quickshell (v0.3.x).

- Package: `quickshell` (+ `upower`)
- Config: `quickshell/.config/quickshell/` → stowed to `~/.config/quickshell/`
- Entry point: `shell.qml`

Waybar, Wofi, Wlogout and Swaync have been removed from the repo and the
package list; Quickshell owns every one of those responsibilities.

## Components

| Responsibility | Implementation |
| -------------- | -------------- |
| Bar | `components/Bar.qml` (one `PanelWindow` per screen) |
| Launcher | `popups/Launcher.qml` (apps + clipboard pages) |
| Wallpaper picker | `popups/Picker.qml` (slide-down, live scan of assets dir) |
| Wi-Fi panel | `components/WifiPanel.qml` (control centre view: scan, connect, PSK prompt) |
| Bluetooth panel | `components/BluetoothPanel.qml` (control centre view: scan, pair, connect, forget) |
| Calendar | `components/Calendar.qml` (control centre) |
| Session menu | `popups/SessionMenu.qml` (lock/hibernate/logout/shutdown/suspend/reboot) |
| Notifications | `popups/NotificationPopups.qml` + `popups/ControlCenter.qml` |
| Control centre | `popups/ControlCenter.qml` (center-top popout: toggles, system/display/power/sound sections, calendar, media) |
| Volume/brightness/mic OSD | `popups/Osd.qml` |
| Keybind cheatsheet | `popups/KeybindCheatsheet.qml` (`Super + K`) |

## Running it

```bash
quickshell          # or: qs   (default config: ~/.config/quickshell/shell.qml)
killall quickshell  # stop
```

Autostart and all binds live in `hypr/.config/hypr/hyprland.lua`
(`hl.on("hyprland.start")` + the `Super + …` bind block). Keybinds:

| Bind | Action |
| ---- | ------ |
| `Super + R` | Launcher (apps) |
| `Super + V` | Launcher → clipboard history |
| `Super + T` | Wallpaper picker (auto-themes the desktop) |
| `Super + L` | Session menu |
| `Super + C` | Control centre |
| `Super + K` | Keybind cheatsheet |
| `Super + Shift + K` | Stop Quickshell |
| `Super + Shift + W` | Start Quickshell |

Launcher keys: `Enter` run · `↑ ↓` navigate · `Esc` close.
Session menu keys: `l` lock · `h` hibernate · `e` logout · `s` shutdown ·
`u` suspend · `r` reboot · `Esc` close.
Cheatsheet: `Super + K` or `Esc` to close.

IPC (used by the binds; handy for scripting):

```bash
qs ipc show                          # list targets/functions
qs ipc call shell toggleLauncher
qs ipc call shell openLauncher apps
qs ipc call shell openLauncher clipboard
qs ipc call shell openPicker wallpapers
qs ipc call shell toggleSession
qs ipc call shell toggleCenter
qs ipc call shell openCenterView wifi
qs ipc call shell openCenterView bluetooth
qs ipc call shell openCenterSection audio   # system | display | power | audio | calendar
qs ipc call shell toggleKeybinds
qs ipc call shell closeAll
qs ipc call shell toggleDnd
qs ipc call shell diagnostics        # JSON state dump (debugging)
```

## Keyboard

Everything is reachable and usable without a mouse:

| Widget | Keys |
| ------ | ---- |
| Launcher | type to filter · `↑ ↓` select · `Enter` run · `Tab` switch apps/clipboard · `Esc` close |
| Picker (wallpapers) | type to filter · `↓` to grid · `← → ↑ ↓` navigate · `Enter`/`Space` apply · `Esc` clear/close |
| Control centre | `Tab`/`Shift+Tab` cycle toggles → calendar → volume · `Space`/`Enter` activate · `← →` (±1% volume, day in calendar) · `↑ ↓` week · `PgUp`/`PgDn` month · `Home` today · `Esc` back, then close |
| Wi-Fi panel | `↑ ↓` select · `Enter` connect/disconnect (PSK prompt has its own input) · `s` rescan · `Esc` back |
| Bluetooth panel | `↑ ↓` select · `Enter` connect/pair · `Del`/`f` forget · `s` scan · `Esc` back |
| Session menu | `← → ↑ ↓` select · `Enter`/`Space` run · `l h e s u r` direct keys · `Esc` close |
| Cheatsheet | `Super + K` / `Esc` close |

## File map

```text
quickshell/.config/quickshell/
├── shell.qml                 # entry point: window instances + IPC handlers
├── qmldir                    # singleton declarations
├── Theme.qml                 # ~/.cache/autotheme.json → palette (matugen)
├── Icons.qml                 # Nerd Font glyphs (lifted from the old Waybar config)
├── Sys.qml                   # CPU/mem/temp/brightness/profile/night light/audio/battery
├── ShellState.qml            # popup + OSD state, persisted dnd/night-light flags
├── Notify.qml                # NotificationServer
├── components/               # bar + one file per module
│   ├── Bar.qml               #   PanelWindow per screen, 3 islands
│   ├── BarModule.qml         #   shared module base (padding/click handling)
│   ├── Workspaces.qml        #   Hyprland workspaces for the bar's monitor
│   ├── Calendar.qml          #   month calendar (control centre)
│   ├── Bluetooth.qml         #   bluetooth status widget → bluetooth view
│   ├── WifiPanel.qml         #   Wi-Fi view: scan/connect/PSK
│   ├── BluetoothPanel.qml    #   Bluetooth view: scan/pair/connect/forget
│   ├── QuickToggle.qml       #   control-centre toggle pill (cardWidth injected)
│   ├── BarSlider.qml         #   control-centre slider with keyboard nudge
│   ├── SectionCard.qml       #   linkable section card (contentWidth injected)
│   ├── StatRow.qml           #   label/value/mini-bar row (system section)
│   └── Clock/Tray/Bluetooth/NetWidget/Audio/Cpu/Memory/Temperature/Backlight/Battery.qml
└── popups/
    ├── Launcher.qml          # apps + clipboard pages
    ├── Picker.qml            # slide-down wallpaper picker
    ├── SessionMenu.qml       # lock / logout / power actions
    ├── ControlCenter.qml     # toggles, calendar, audio, media, notifications
    ├── NotificationPopups.qml
    ├── KeybindCheatsheet.qml # Super + K
    └── Osd.qml               # volume / brightness / mic OSD
```

## Theming

`Theme.qml` reads the matugen-generated `~/.cache/autotheme.json` (see
[THEMES.md](THEMES.md)):

- `~/.config/hypr/themes/wallpapers/assets/` → live-scanned wallpaper list
- `~/.cache/wallpaper_state` → current wallpaper path
- `~/.cache/autotheme.json` → dark palette for the current wallpaper

The file is watched, so applying a wallpaper (`Super + T` or
`wallpaper_switch.sh apply <file>`) re-themes the entire shell live: every
color cross-fades over ~320 ms via the palette blending in `Theme.qml`, and
the wallpaper animates in with a random `wave`/`wipe` `awww` transition. Dropping a new file
into the assets dir is enough — no registry, no tags, no config edits.

## Widget behaviour

| Module | Left click | Middle | Right |
| ------ | ---------- | ------ | ----- |
| Workspaces | switch workspace (scroll cycles) | – | – |
| Clock | calendar section | – | – |
| Network | wi-fi view | – | – |
| Bluetooth | bluetooth view | – | – |
| Audio | sound section | mute | `pavucontrol` |
| CPU / Memory / Temperature | system section | – | – |
| Backlight | display section | – | night light toggle |
| Battery | power section | – | – |
| Tray | activate | secondary activate | platform menu |

The OSD appears automatically on volume/mute/brightness/microphone changes
from any source (`wpctl`, media keys, `pavucontrol`, the control centre
slider).

## Frosted glass + motion

Popups (control centre, launcher, picker, session, cheatsheet, OSD,
notifications) use compositor-side frosted glass: every popup PanelWindow
sets `WlrLayershell.namespace: "quickshell-popup"` and `hyprland.lua` adds

```lua
hl.layer_rule({ match = { namespace = "^quickshell-popup$" }, blur = true, ignore_alpha = 0.5 })
hl.layer_rule({ match = { namespace = "^quickshell-bar$" },     blur = true, ignore_alpha = 0.5 })
```

so Hyprland blurs what sits behind the near-opaque cards and bar islands
(dim scrims at alpha 0.4 and empty regions stay unblurred). The blur costs
nothing in the shell — it is the compositor's existing blur pipeline.

Popup animations share one motion vocabulary defined in `Theme.qml`
(`popupDuration` 300 ms `OutQuint` slide+fade+scale, `viewDuration` 220 ms
for Wi-Fi/Bluetooth view cross-fades, `scrollDuration` 320 ms for
programmatic scrolls, `hoverDuration` 150 ms for every hover/active color
ease). Scrolling uses softer `flickDeceleration`/`maximumFlickVelocity`
for a longer glide.

## Data sources

- Workspaces/windows: Hyprland IPC (`Quickshell.Hyprland`)
- Audio: Pipewire (`Quickshell.Services.Pipewire`)
- Battery: UPower (`Quickshell.Services.UPower`) — note `percentage` is a
  0..1 fraction (normalised in `Sys.qml`)
- Network: NetworkManager (`Quickshell.Networking`)
- Tray: StatusNotifierItem + DBusMenu
- Media: MPRIS (`Quickshell.Services.Mpris`)

## Troubleshooting

- **Popup doesn't open from a bind** — the shell isn't running:
  `pgrep -x quickshell || quickshell`.
- **`qs ipc show` lists no target** — no instance for the default config:
  start it with `quickshell`.
- **Logs** — `quickshell` prints to stderr; the per-session log is
  `/run/user/$UID/quickshell/by-id/*/log.qslog`.
- **Config reloads automatically** when any file under
  `~/.config/quickshell/` changes (`ShellState`/`Theme` survive reloads).
- **Diagnostics** — `qs ipc call shell diagnostics` dumps theme, cpu/mem/temp,
  brightness, profile, volume, battery, tray item count, notification counts
  and popup visibility as JSON.

## Rollback

The previous Waybar/Wofi/Wlogout/Swaync setup is retired but still in git
history (`git log -- waybar`). To go back, restore the old `waybar/`,
`wofi/`, `wlogout/` packages and the `hypr/.config/hypr/themes/{waybar,wofi,wlogout,swaync}`
trees from the commit before the migration, then revert
`hyprland.lua`, `install.sh` and the theme scripts.
