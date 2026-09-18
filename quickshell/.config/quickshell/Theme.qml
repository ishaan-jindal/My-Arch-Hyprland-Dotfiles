pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Autotheme bridge — fully dynamic, no theme configs.
//
// `wallpaper_switch.sh apply <file>` runs matugen once (dark-only Material
// You) and writes ~/.cache/autotheme.json; this singleton watches that file
// and re-colors the bar, launcher, control centre, session menu,
// notifications and OSDs live. Any image/video dropped into the wallpaper
// assets dir appears in the picker via the scanner below — nothing is
// registered anywhere.
//
// Palette roles: bg, bgSolid, border, fg, bright, muted, hover, accent,
// accentSoft, critical. Colors are "#RRGGBB" or "#AARRGGBB".
Singleton {
  id: root

  readonly property string home: Quickshell.env("HOME") || ""

  // Emergency floor if generation failed or matugen is missing.
  // Not a selectable theme.
  readonly property var fallback: ({
    bg: "#c70a0a0c",
    bgSolid: "#b80a0a0c",
    border: "#1c1f26",
    fg: "#e6e6e6",
    bright: "#ffffff",
    muted: "#8b8f98",
    hover: "#3a3f4b",
    accent: "#ffffff",
    accentSoft: "#8b8f98",
    critical: "#ff5f5f",
    radius: 10,
    fontFamily: "JetBrainsMono Nerd Font Mono",
    fontSize: 13
  })

  // ---------------------------------------------------------------------
  // Generated palette (from ~/.cache/autotheme.json)
  // ---------------------------------------------------------------------
  property string autoText: ""

  FileView {
    id: autoFile
    path: root.home + "/.cache/autotheme.json"
    blockLoading: true
    watchChanges: true
    onFileChanged: reload()
    onLoaded: root.autoText = text()

    Component.onCompleted: root.autoText = text()
  }

  readonly property var filePalette: {
    try {
      const o = JSON.parse(autoText || "null");
      if (o && o.bg && o.accent)
        return o;
    } catch (e) {}
    return null;
  }

  readonly property var palette: filePalette || fallback

  // ---------------------------------------------------------------------
  // Animated palette blending
  //
  // A wallpaper switch cross-fades every color in the shell (bar, launcher,
  // control centre, OSD, …) from the previous palette to the new one,
  // mirroring the awww wipe on the wallpaper instead of snapping.
  // ---------------------------------------------------------------------
  property real blend: 1
  property var fromPalette: palette
  property var toPalette: palette

  function paletteColor(key) {
    if (blend >= 1 || !fromPalette)
      return toPalette[key];
    return mixColor(fromPalette[key], toPalette[key], blend);
  }

  function mixColor(a, b, t) {
    const ca = parseColor(a);
    const cb = parseColor(b);
    return Qt.rgba(
      ca.r + (cb.r - ca.r) * t,
      ca.g + (cb.g - ca.g) * t,
      ca.b + (cb.b - ca.b) * t,
      ca.a + (cb.a - ca.a) * t
    );
  }

  // Accepts "#RRGGBB" and "#AARRGGBB".
  function parseColor(value) {
    const s = String(value);
    if (s.charAt(0) !== "#")
      return { r: 0, g: 0, b: 0, a: 1 };
    const h = s.substring(1);
    if (h.length === 8) {
      return {
        a: parseInt(h.substring(0, 2), 16) / 255,
        r: parseInt(h.substring(2, 4), 16) / 255,
        g: parseInt(h.substring(4, 6), 16) / 255,
        b: parseInt(h.substring(6, 8), 16) / 255
      };
    }
    if (h.length === 6) {
      return {
        a: 1,
        r: parseInt(h.substring(0, 2), 16) / 255,
        g: parseInt(h.substring(2, 4), 16) / 255,
        b: parseInt(h.substring(4, 6), 16) / 255
      };
    }
    return { r: 0, g: 0, b: 0, a: 1 };
  }

  NumberAnimation {
    id: blendAnimation
    target: root
    property: "blend"
    from: 0
    to: 1
    duration: 320
    easing.type: Easing.OutCubic
  }

  Component.onCompleted: {
    toPalette = palette;
    fromPalette = toPalette;
    blend = 1;
  }

  onPaletteChanged: {
    fromPalette = toPalette;
    toPalette = palette;
    blend = 0;
    blendAnimation.restart();
  }

  readonly property color bg: paletteColor("bg")
  readonly property color bgSolid: paletteColor("bgSolid")
  readonly property color border: paletteColor("border")
  readonly property color fg: paletteColor("fg")
  readonly property color bright: paletteColor("bright")
  readonly property color muted: paletteColor("muted")
  readonly property color hover: paletteColor("hover")
  readonly property color accent: paletteColor("accent")
  readonly property color accentSoft: paletteColor("accentSoft")
  readonly property color critical: paletteColor("critical")
  readonly property int radius: palette.radius !== undefined ? palette.radius : 10
  readonly property string fontFamily: palette.fontFamily !== undefined ? palette.fontFamily : "JetBrainsMono Nerd Font Mono"
  readonly property int fontSize: palette.fontSize !== undefined ? palette.fontSize : 13

  // ---------------------------------------------------------------------
  // Bar geometry (mirrors the Waybar base config)
  // ---------------------------------------------------------------------
  readonly property int barHeight: 40
  readonly property int barMarginTop: 10
  readonly property int barMarginSide: 20
  readonly property int barSpacing: 6
  readonly property int widgetPadding: 8
  readonly property int islandMargin: 10

  // ---------------------------------------------------------------------
  // Motion vocabulary — one place so the whole shell feels the same.
  // ---------------------------------------------------------------------
  readonly property int hoverDuration: 150     // color eases
  readonly property int popupDuration: 300     // popup slide/fade/scale
  readonly property int viewDuration: 220      // in-popup view swaps
  readonly property int scrollDuration: 320    // programmatic scrolls
  readonly property real scrimOpacity: 0.32

  // ---------------------------------------------------------------------
  // Current wallpaper (from ~/.cache/wallpaper_state)
  // ---------------------------------------------------------------------
  property string wallStateText: ""

  FileView {
    id: wallStateFile
    path: root.home + "/.cache/wallpaper_state"
    blockLoading: true
    watchChanges: true
    onFileChanged: reload()
    onLoaded: root.wallStateText = text()

    Component.onCompleted: root.wallStateText = text()
  }

  readonly property string currentWallpaper: (wallStateText || "").trim()

  // ---------------------------------------------------------------------
  // Dynamic wallpaper listing: every image/video in the assets dir.
  // Refreshed on demand (picker open), so newly added files appear with
  // no restart and no registry. Entry shape:
  // { id, name, path, isVideo, thumb }
  // ---------------------------------------------------------------------
  property string wallsText: "[]"

  readonly property var walls: {
    try {
      const a = JSON.parse(wallsText || "[]");
      if (Array.isArray(a))
        return a;
    } catch (e) {}
    return [];
  }

  Process {
    id: wallScanner
    command: [root.home + "/.config/hypr/scripts/wallpaper_switch.sh", "list-json"]

    stdout: StdioCollector {
      onStreamFinished: root.wallsText = this.text
    }
  }

  function refreshWallpapers() {
    wallScanner.running = true;
  }

  // ---------------------------------------------------------------------
  // Actions (delegate to the Hypr scripts)
  // ---------------------------------------------------------------------
  function applyWallpaper(path) {
    Quickshell.execDetached({
      command: [home + "/.config/hypr/scripts/wallpaper_switch.sh", "apply", path]
    });
  }

  function toggleNightLight() {
    Quickshell.execDetached({
      command: [home + "/.config/hypr/scripts/night_light_toggle.sh"]
    });
  }
}
