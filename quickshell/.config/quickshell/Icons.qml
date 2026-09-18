pragma Singleton

import QtQuick
import Quickshell

// Nerd Font glyph table.
// Codepoints were extracted 1:1 from the Waybar theme configs
// (hypr/.config/hypr/themes/waybar/base/config.jsonc) so the bar looks
// identical to the old setup.
Singleton {
  id: root

  // Workspaces
  readonly property string wsActive: "\uf192"
  readonly property string wsDefault: "\uf4aa"

  // System monitors (chunky MDI glyphs; the thin FA variants render small
  // in Qt at bar sizes. Note: these are supplementary-plane codepoints, so
  // they need surrogate-pair escapes, not \uXXXX.)
  readonly property string cpu: "\udb80\udf5b"
  readonly property string mem: "\udb81\ude1a"
  readonly property string tempLow: "\uf2cb"
  readonly property string tempMid: "\uf2c9"
  readonly property string tempHigh: "\uf2c7"

  // Backlight (9 step icon set from Waybar)
  readonly property var brightness: [
    "\ue38d", "\ue3d3", "\ue3d1", "\ue3cf", "\ue3ce",
    "\ue3cd", "\ue3ca", "\ue3c8", "\ue39b"
  ]

  // Battery: full MDI scale, ascending empty -> full (matches the old
  // Waybar format-icons order). Index with Math.floor(pct / 10), 0..10.
  // 0 = outline (0-9%), 1..9 = 10%..90%, 10 = full (100%).
  readonly property var battery: [
    "\udb80\udc8e", "\udb80\udc7a", "\udb80\udc7b", "\udb80\udc7c", "\udb80\udc7d",
    "\udb80\udc7e", "\udb80\udc7f", "\udb80\udc80", "\udb80\udc81", "\udb80\udc82",
    "\udb80\udc79"
  ]
  readonly property string battCharging: "\udb80\udc84"

  // Microphone
  readonly property string mic: "\uf130"
  readonly property string micOff: "\uf131"

  // Network: nf-md-wifi_strength_1..4 (see Nerd Fonts cheat sheet), picked
  // by signal strength via wifiIcon(). The plain wedge doubles as the
  // control-centre toggle glyph.
  readonly property string wifi: "\udb82\udd28"
  readonly property var wifiSteps: [
    "\udb82\udd1f", "\udb82\udd22", "\udb82\udd25", "\udb82\udd28"
  ]

  function wifiIcon(strength) {
    const idx = Math.max(0, Math.min(3, Math.floor(strength * 4)));
    return wifiSteps[idx];
  }
  // mdi-ethernet (U+F796, the old FA ethernet glyph, is not in any Nerd Font)
  readonly property string eth: "\udb80\ude00"
  readonly property string warning: "\u26a0"

  // Audio (MDI volume set; bolder than the FA speakers)
  readonly property string audioMuted: "\udb81\udf5f"
  readonly property string volLow: "\udb81\udd7f"
  readonly property string volMid: "\udb81\udd80"
  readonly property string volHigh: "\udb81\udd7e"
  readonly property string bluetooth: "\uf293"
  // Bluetooth state pair (verified in JetBrainsMono Nerd Font Mono):
  // connected = symbol with radiating waves, off = slashed symbol.
  readonly property string bluetoothConnected: "\udb80\udcb0"
  readonly property string bluetoothOff: "\udb80\udcb2"

  // Control center / notifications
  readonly property string bell: "\uf0f3"
  readonly property string bellSlash: "\uf1f6"
  readonly property string moon: "\uf186"

  // Media
  readonly property string play: "\uf04b"
  readonly property string pause: "\uf04c"
  readonly property string next: "\uf051"
  readonly property string prev: "\uf048"

  // Session
  readonly property string lock: "\uf023"
  readonly property string logout: "\uf08b"
  readonly property string power: "\uf011"
  readonly property string reboot: "\uf021"
  readonly property string snowflake: "\uf2dc"

  // Launcher pages
  readonly property string apps: "\uf009"
  // mdi-palette (U+F53F was unassigned in every Nerd Font and rendered as tofu)
  readonly property string palette: "\udb80\udfe1"
  readonly property string image: "\uf03e"
  readonly property string clipboard: "\uf0ea"

  // Misc
  readonly property string search: "\uf002"
  readonly property string close: "\uf00d"
}
