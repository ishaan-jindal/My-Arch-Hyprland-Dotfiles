---@diagnostic disable: undefined-global

local mainMod = "SUPER"
local terminal = "ghostty"
local menu = "qs ipc call shell openLauncher apps"
local browser = "zen-browser"


------------------
---- MONITORS ----
------------------

hl.monitor({
  output   = "",
  mode     = "1920x1080@144",
  position = "auto",
  scale    = 1,
})


------------------
-- ENVIRONMENT ---
------------------

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("GDK_BACKEND", "wayland,x11")


------------------
--- AUTOSTART ----
------------------

hl.on("hyprland.start", function()
  hl.exec_cmd("quickshell")
  hl.exec_cmd("wl-paste --type text --watch cliphist store")
  hl.exec_cmd("wl-paste --type image --watch cliphist store")
  hl.exec_cmd("sleep 0.5 && ~/.config/hypr/scripts/restore_wallpaper.sh")
end)


------------------
-- LOOK & FEEL ---
------------------

hl.config({
  general = {
    gaps_in                 = 5,
    gaps_out                = 15,
    border_size             = 0,

    ["col.active_border"]   = "rgba(FFCC00ee)",
    ["col.inactive_border"] = "rgba(595959aa)",

    resize_on_border        = true,
    allow_tearing           = true,
    layout                  = "dwindle",
  },

  decoration = {
    rounding         = 10,
    rounding_power   = 2,

    active_opacity   = 1.0,
    inactive_opacity = 1.0,

    shadow           = {
      enabled      = true,
      range        = 4,
      render_power = 3,
      color        = "rgba(1a1a1aee)",
    },

    blur             = {
      enabled  = true,
      size     = 3,
      passes   = 1,
      vibrancy = 0.1696,
    },
  },

  dwindle = {
    preserve_split = true,
  },

  master = {
    new_status = "master",
  },

  misc = {
    force_default_wallpaper = 0,
    disable_hyprland_logo   = true,
  },

  input = {
    kb_layout    = "us",
    follow_mouse = 1,
    sensitivity  = 0,

    touchpad     = {
      natural_scroll = true,
    },
  },
})


------------------
--- ANIMATIONS ---
------------------

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1.0 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "easeOutQuint" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 0.4, bezier = "quick", style = "fade" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 0.4, bezier = "quick", style = "slidefade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 0.4, bezier = "quick", style = "slidefade" })


------------------
--- PERIPHERALS --
------------------

hl.device({
  name        = "epic-mouse-v1",
  sensitivity = -0.5,
})


------------------
--- GESTURES -----
------------------

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "vertical", action = "special", workspace_name = "magic" })


------------------
-- KEYBINDINGS ---
------------------

-- Apps
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("qs ipc call shell toggleSession"))

-- Window actions
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + A", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pin({ action = "toggle" }))

-- Layout
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))

-- Focus movement
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "d" }))

-- Workspaces (focus)
hl.bind(mainMod .. " + 1", hl.dsp.focus({ workspace = 1 }))
hl.bind(mainMod .. " + 2", hl.dsp.focus({ workspace = 2 }))
hl.bind(mainMod .. " + 3", hl.dsp.focus({ workspace = 3 }))
hl.bind(mainMod .. " + 4", hl.dsp.focus({ workspace = 4 }))
hl.bind(mainMod .. " + 5", hl.dsp.focus({ workspace = 5 }))
hl.bind(mainMod .. " + 6", hl.dsp.focus({ workspace = 6 }))
hl.bind(mainMod .. " + 7", hl.dsp.focus({ workspace = 7 }))
hl.bind(mainMod .. " + 8", hl.dsp.focus({ workspace = 8 }))
hl.bind(mainMod .. " + 9", hl.dsp.focus({ workspace = 9 }))
hl.bind(mainMod .. " + 0", hl.dsp.focus({ workspace = 10 }))

-- Workspaces (move window)
hl.bind(mainMod .. " + SHIFT + 1", hl.dsp.window.move({ workspace = 1 }))
hl.bind(mainMod .. " + SHIFT + 2", hl.dsp.window.move({ workspace = 2 }))
hl.bind(mainMod .. " + SHIFT + 3", hl.dsp.window.move({ workspace = 3 }))
hl.bind(mainMod .. " + SHIFT + 4", hl.dsp.window.move({ workspace = 4 }))
hl.bind(mainMod .. " + SHIFT + 5", hl.dsp.window.move({ workspace = 5 }))
hl.bind(mainMod .. " + SHIFT + 6", hl.dsp.window.move({ workspace = 6 }))
hl.bind(mainMod .. " + SHIFT + 7", hl.dsp.window.move({ workspace = 7 }))
hl.bind(mainMod .. " + SHIFT + 8", hl.dsp.window.move({ workspace = 8 }))
hl.bind(mainMod .. " + SHIFT + 9", hl.dsp.window.move({ workspace = 9 }))
hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))

-- Special workspace
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Mouse workspace scrolling
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Mouse window drag/resize
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Screenshot
hl.bind("Print", hl.dsp.exec_cmd("hyprshot -m region -o ~/Pictures/"))

-- Clipboard
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("qs ipc call shell openLauncher clipboard"))

-- Wallpaper picker (slide-down widget, auto-themes the desktop)
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("qs ipc call shell openPicker wallpapers"))

-- Quickshell shell control
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("qs ipc call shell toggleCenter"))
hl.bind(mainMod .. " + K", hl.dsp.exec_cmd("qs ipc call shell toggleKeybinds"))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.exec_cmd("killall quickshell"))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("quickshell"))

-- Night light
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("~/.config/hypr/scripts/night_light_toggle.sh"))

-- Zoom (built-in cursor:zoom_factor toggle, 2x default)
hl.bind(mainMod .. " + Z", hl.dsp.exec_cmd("~/.config/hypr/scripts/zoom_toggle.sh"))

-- File manager
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("nemo"))

-- Android emulator
hl.bind(mainMod .. " + M",
  hl.dsp.exec_cmd("~/Android/Sdk/emulator/emulator -avd flutter_emulator -writable-system -no-snapshot"))

-- Volume (repeating + locked)
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 1%+"),
  { repeating = true, locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-"),
  { repeating = true, locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })

-- Brightness (repeating + locked)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -n2 set 1%+"), { repeating = true, locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -n2 set 1%-"), { repeating = true, locked = true })

-- Media (locked)
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- Misc
hl.bind("CTRL + RETURN", hl.dsp.exec_cmd("echo"))


----------------------------
-- WINDOW RULES ------------
----------------------------

hl.window_rule({
  match          = { class = ".*" },
  suppress_event = "maximize",
})

hl.window_rule({
  match    = { class = "^$", title = "^$", xwayland = true },
  no_focus = true,
})

hl.window_rule({
  match = { title = "^(Emulator|Android Emulator).*" },
  float = true,
})

hl.window_rule({
  match  = { class = "^spotify$" },
  float  = true,
  center = true,
  size   = { 900, 600 },
})
