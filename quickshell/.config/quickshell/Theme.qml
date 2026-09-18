pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Theme bridge.
//
// Reads the *existing* single source of truth for the desktop theme
// (hypr/.config/hypr/themes/themes.json) plus the current selection out of
// ~/.cache/theme_state (written by hypr/scripts/theme_toggle.sh), so the
// Quickshell shell stays in lockstep with Waybar/Wofi/Wlogout/Swaync while
// both stacks run side by side.
//
// The palette values below were ported 1:1 from the per-theme Waybar CSS
// (hypr/.config/hypr/themes/waybar/<theme>/style.css).
Singleton {
  id: root

  readonly property string home: Quickshell.env("HOME") || ""

  // ---------------------------------------------------------------------
  // Palettes
  // ---------------------------------------------------------------------
  readonly property var palettes: ({
    obsidian: {
      bg: "#c70a0a0c",
      bgSolid: "#f20a0a0c",
      border: "#1c1f26",
      fg: "#e6e6e6",
      bright: "#ffffff",
      muted: "#8b8f98",
      hover: "#3a3f4b",
      accent: "#ffffff",
      accentSoft: "#ffffff",
      critical: "#ff5f5f",
      radius: 10,
      fontFamily: "JetBrainsMono Nerd Font Mono",
      fontSize: 13
    },
    crimson: {
      bg: "#d908080a",
      bgSolid: "#f208080a",
      border: "#2a0f14",
      fg: "#e8e8e8",
      bright: "#ffffff",
      muted: "#8a8a8a",
      hover: "#5a1a22",
      accent: "#ff2a3d",
      accentSoft: "#ff4d5e",
      critical: "#ff2a3d",
      radius: 10,
      fontFamily: "JetBrainsMono Nerd Font Mono",
      fontSize: 13
    },
    aether: {
      bg: "#a6141820",
      bgSolid: "#f2141820",
      border: "#2a3444",
      fg: "#eaf2ff",
      bright: "#ffffff",
      muted: "#9aa6b2",
      hover: "#3b4b6b",
      accent: "#7aa2f7",
      accentSoft: "#a6c8ff",
      critical: "#ff6b6b",
      radius: 12,
      fontFamily: "JetBrainsMono Nerd Font Mono",
      fontSize: 13
    },
    ember: {
      bg: "#d1140e08",
      bgSolid: "#f2140e08",
      border: "#3a2a18",
      fg: "#e6d3b3",
      bright: "#e0af68",
      muted: "#a89984",
      hover: "#5a4025",
      accent: "#e0af68",
      accentSoft: "#e0af68",
      critical: "#fb4934",
      radius: 10,
      fontFamily: "JetBrainsMono Nerd Font Mono",
      fontSize: 13
    },
    drift: {
      bg: "#9912141a",
      bgSolid: "#f212141a",
      border: "#2a2f3a",
      fg: "#d6dbe3",
      bright: "#c792ea",
      muted: "#8f96a3",
      hover: "#7aa2a9",
      accent: "#7aa2a9",
      accentSoft: "#c792ea",
      critical: "#ff6b6b",
      radius: 12,
      fontFamily: "JetBrainsMono Nerd Font Mono",
      fontSize: 13
    }
  })

  // ---------------------------------------------------------------------
  // Current theme (from ~/.cache/theme_state)
  // ---------------------------------------------------------------------
  property string stateText: ""

  FileView {
    id: stateFile
    path: root.home + "/.cache/theme_state"
    blockLoading: true
    watchChanges: true
    onFileChanged: reload()
    onLoaded: root.stateText = text()

    Component.onCompleted: root.stateText = text()
  }

  readonly property string current: palettes[(stateText || "").trim()] !== undefined
    ? (stateText || "").trim()
    : "obsidian"

  readonly property var palette: palettes[current]

  // ---------------------------------------------------------------------
  // Animated palette blending
  //
  // A theme switch cross-fades every color in the shell (bar, launcher,
  // control centre, OSD, …) from the previous palette to the new one,
  // mirroring the awww wipe on the wallpaper instead of snapping.
  // ---------------------------------------------------------------------
  property real blend: 1
  property var fromPalette: palettes[current]
  property var toPalette: palettes[current]

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
    toPalette = palettes[current];
    fromPalette = toPalette;
    blend = 1;
  }

  onCurrentChanged: {
    fromPalette = toPalette;
    toPalette = palettes[current];
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
  readonly property int radius: palette.radius
  readonly property string fontFamily: palette.fontFamily
  readonly property int fontSize: palette.fontSize

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
  // themes.json (theme list + wallpapers)
  // ---------------------------------------------------------------------
  property string themesText: ""

  FileView {
    id: themesFile
    path: root.home + "/.config/hypr/themes/themes.json"
    blockLoading: true
    watchChanges: true
    onFileChanged: reload()
    onLoaded: root.themesText = text()

    Component.onCompleted: root.themesText = text()
  }

  readonly property var themesData: {
    try {
      return JSON.parse(themesText || "{}");
    } catch (e) {
      return {};
    }
  }

  readonly property var themeNames: Object.keys(palettes)

  // ---------------------------------------------------------------------
  // Current wallpaper (from ~/.cache/wallpaper_state_<theme>)
  // ---------------------------------------------------------------------
  property string wallStateText: ""

  FileView {
    id: wallStateFile
    path: root.home + "/.cache/wallpaper_state_" + root.current
    blockLoading: true
    watchChanges: true
    onFileChanged: reload()
    onLoaded: root.wallStateText = text()

    Component.onCompleted: root.wallStateText = text()
  }

  readonly property string currentWallpaper: (wallStateText || "").trim()

  function themeTags(name) {
    const data = themesData;
    if (data.themes && data.themes[name] && data.themes[name].tags)
      return data.themes[name].tags;
    return [];
  }

  // Wallpapers whose tags intersect the theme's tags (same rule as
  // wallpaper_switch.sh).
  function wallpapersFor(name) {
    const data = themesData;
    if (!data.wallpapers)
      return [];
    const tags = themeTags(name);
    const out = [];
    for (let i = 0; i < data.wallpapers.length; i++) {
      const w = data.wallpapers[i];
      if (!w.tags)
        continue;
      for (let j = 0; j < w.tags.length; j++) {
        if (tags.indexOf(w.tags[j]) !== -1) {
          out.push(w);
          break;
        }
      }
    }
    return out;
  }

  function wallpaperPath(w) {
    return home + "/.config/hypr/themes/" + w.path;
  }

  function wallpaperName(w) {
    const parts = String(w.path).split("/");
    return parts[parts.length - 1];
  }

  // Middle-frame thumbnail for videos (generated per THEMES.md with ffmpeg
  // into wallpapers/thumbs/<id>.jpg).
  function wallpaperThumb(w) {
    return home + "/.config/hypr/themes/wallpapers/thumbs/" + w.id + ".jpg";
  }

  // ---------------------------------------------------------------------
  // Actions (delegate to the existing, battle-tested Hypr scripts)
  // ---------------------------------------------------------------------
  function applyTheme(name) {
    Quickshell.execDetached({
      command: [home + "/.config/hypr/scripts/theme_toggle.sh", "apply", name]
    });
  }

  function applyWallpaper(id) {
    Quickshell.execDetached({
      command: [home + "/.config/hypr/scripts/wallpaper_switch.sh", "apply", id]
    });
  }

  function toggleNightLight() {
    Quickshell.execDetached({
      command: [home + "/.config/hypr/scripts/night_light_toggle.sh"]
    });
  }
}
