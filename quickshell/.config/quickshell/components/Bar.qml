import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../island" as Isle
import ".."

// Dynamic Island host window: one fixed, transparent, top-centered
// window per monitor. The window holds its largest-state envelope
// (hub 420x200 + 64px side padding + 8px top margin) and only the pill
// resizes; the click-through mask tracks the pill exactly. Clicking
// anywhere outside while expanded clears the focus grab and collapses.
Variants {
  // One island per monitor; a single-monitor setup falls back to the
  // primary screen when the Config flag is off.
  model: Isle.IslandState.showOnAllMonitors || Quickshell.screens.length === 0
    ? Quickshell.screens : [Quickshell.screens[0]]

  delegate: Component {
    PanelWindow {
      id: bar
      required property var modelData

      screen: modelData
      anchors {
        top: true
      }
      margins {
        top: 8
      }
      implicitWidth: island.implicitWidth
      implicitHeight: island.implicitHeight
      color: "transparent"
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.layer: WlrLayer.Top
      WlrLayershell.namespace: "quickshell-bar" // kept: hyprland.lua layerrules match this
      // Text panes need Exclusive; hub/media take focus on demand so a
      // preempting notification never sits under a stale Exclusive grab.
      WlrLayershell.keyboardFocus: Isle.IslandState.legacyActive ? WlrKeyboardFocus.Exclusive
        : Isle.IslandState.expanded ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

      mask: Region {
        item: island.pillItem
      }

      // Click-outside-to-collapse: while expanded the island owns the
      // grab; losing it (click elsewhere, workspace switch) collapses.
      // The grab can report a spurious `cleared` in the same frame it
      // activates (focus hasn't settled) — ignore those, or no pane
      // would ever stay open.
      HyprlandFocusGrab {
        id: grab
        active: Isle.IslandState.expanded
        windows: [bar]
        property double armedAt: 0
        onActiveChanged: if (active) armedAt = Date.now()
        onCleared: if (Date.now() - grab.armedAt > 250) Isle.IslandState.collapse()
      }

      Isle.Island {
        id: island
        barScreen: bar.screen
      }
    }
  }
}
