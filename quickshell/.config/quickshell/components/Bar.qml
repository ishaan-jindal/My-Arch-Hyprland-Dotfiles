import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import ".."

// Dynamic Island top bar (option B): one centered pill per monitor.
// The pill floats flush at y=0 and hosts every popup pane inline; this
// window is click-through except the mask (pill when collapsed, full
// window while expanded so outside clicks dismiss), parked above windows
// (Top layer) with no exclusive-zone reserve (ExclusionMode.Ignore —
// mapped + parked, exclusiveZone 0). The legacy overlay windows are
// retired (never shown). Keyboard focus is exclusive while any pill pane
// is open so Super+C/V/R land in the pill with no manual click; Esc
// anywhere in the bar collapses via the island trapdoor.
Variants {
  model: Quickshell.screens

  delegate: Component {
    PanelWindow {
      id: bar
      required property var modelData

      screen: modelData
      anchors {
        top: true
        left: true
        right: true
      }
      margins {
        top: 0
        left: 0
        right: 0
        bottom: 0
      }
      implicitHeight: island.height
      color: "transparent"
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.layer: WlrLayer.Top
      WlrLayershell.namespace: "quickshell-bar" // kept: hyprland.lua layerrules match this
      WlrLayershell.keyboardFocus: (ShellState.islandMode !== "" && (Hyprland.focusedMonitor === null || Hyprland.monitorFor(modelData) === Hyprland.focusedMonitor)) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

      mask: Region {
        // Tight on the pill unless a pane is open (full window then so
        // outside clicks reach the dismiss layer). Hover-peek never
        // widens the mask. Swaps on state change only, never per-frame.
        item: island.mode !== "" ? dismissArea : island.pillHit
      }

      // Click-outside-to-minimize: full-window transparent layer BEHIND
      // the pill, live only while a pane is open. The island above wins
      // all pill hits, so buttons keep working; anything else in the
      // window dismisses.
      MouseArea {
        id: dismissArea
        anchors.fill: parent
        enabled: island.mode !== ""
        onClicked: island.dismiss()
      }

      DynamicIsland {
        id: island
        barScreen: bar.screen
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
      }
    }
  }
}
