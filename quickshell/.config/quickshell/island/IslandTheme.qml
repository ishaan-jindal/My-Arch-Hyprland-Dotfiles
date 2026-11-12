pragma Singleton

import QtQuick
import Quickshell

// Dynamic Island visual tokens. Single source for every island pixel:
// palette, type ramp and all state sizes / motion constants.
// Font rule: "Inter" is the ONLY font string in the island.
Singleton {
  id: root

  readonly property string name: "IslandTheme"
  readonly property string fontFamily: "Inter"

  // Palette
  readonly property color surface: "#1C1C1E"
  readonly property color surfaceHigh: "#2C2C2E"
  readonly property color text: "#FFFFFF"
  readonly property color textSecondary: "#99EBEBF5"
  readonly property color accent: "#0A84FF"
  readonly property color green: "#30D158"
  readonly property color red: "#FF453A"
  readonly property color orange: "#FF9F0A"
  readonly property color yellow: "#FFD60A"

  // Pill chrome
  readonly property color pill: "#000000"
  readonly property color pillBorder: "#14FFFFFF"

  // Type ramp (weights applied at call sites: DemiBold / Normal)
  readonly property int compactSize: 13    // semibold compact
  readonly property int titleSize: 14      // semibold title
  readonly property int secondarySize: 12  // regular secondary
  readonly property int bigSize: 17        // semibold expanded title

  // State sizes (content boxes; the window adds the fixed padding)
  readonly property int idleW: 148
  readonly property int idleH: 34
  readonly property real idleR: 17
  readonly property int actW: 220
  readonly property int actH: 34
  readonly property real actR: 17
  readonly property int toastW: 300
  readonly property int toastH: 52
  readonly property real toastR: 26
  readonly property int notifW: 380
  readonly property int notifH: 92
  readonly property real notifR: 30
  readonly property int mediaW: 420
  readonly property int mediaH: 190
  readonly property real mediaR: 36
  readonly property int hubW: 420
  readonly property int hubH: 236
  readonly property real hubR: 36

  // Legacy pane hosting (existing bodies keep their settled sizes)
  readonly property real legacyR: 24
  readonly property int legacyHeaderH: 40
  readonly property int legacyMargin: 12

  // Hover peek (idle / activity only)
  readonly property int peekW: 8
  readonly property int peekH: 4

  // Motion: one spring for size, OutCubic for radius, sequenced fades.
  // Everything reads IslandState.reduceMotion and snaps when set.
  readonly property real springStiffness: 3.2
  readonly property real springDamping: 0.28
  readonly property real springEps: 0.25
  readonly property int heightLagMs: 30
  readonly property int radiusMs: 300
  readonly property int fadeOutMs: 90
  readonly property int fadeInMs: 160
  readonly property int fadeDelayMs: 120
}
