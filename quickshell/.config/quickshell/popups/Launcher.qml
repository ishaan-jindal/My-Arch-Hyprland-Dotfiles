import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../components"

// Legacy launcher overlay window (retired as the pill host —
// ShellState toggles drive `islandMode` now, so `launcherOpen` never goes
// true in normal use). Kept as a thin wrapper around LauncherBody so the
// UI still works if the legacy bool is ever set directly.
PanelWindow {
  id: launcher

  anchors {
    top: true
    left: true
    right: true
    bottom: true
  }
  color: "transparent"
  visible: ShellState.launcherOpen
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "quickshell-popup"
  WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  // kept for shell.qml diagnostics
  readonly property alias items: body.items
  readonly property alias inputFocus: body.inputFocus

  // dim scrim, click outside the card to close
  Rectangle {
    id: backdrop
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.4 * (ShellState.launcherOpen ? 1 : 0))

    Behavior on color {
      ColorAnimation { duration: Theme.popupDuration; easing.type: Easing.OutCubic }
    }

    MouseArea {
      anchors.fill: parent
      onClicked: ShellState.launcherOpen = false
    }
  }

  Rectangle {
    id: card
    anchors.centerIn: parent
    width: 640
    height: 460
    color: Theme.bgSolid
    border.color: Theme.border
    border.width: 1
    radius: Theme.radius

    scale: ShellState.launcherOpen ? 1 : 0.97

    Behavior on scale {
      NumberAnimation { duration: Theme.popupDuration; easing.type: Easing.OutQuint }
    }

    transform: Translate {
      y: ShellState.launcherOpen ? 0 : 30

      Behavior on y {
        NumberAnimation { duration: Theme.popupDuration; easing.type: Easing.OutQuint }
      }
    }

    opacity: ShellState.launcherOpen ? 1 : 0

    Behavior on opacity {
      NumberAnimation { duration: Theme.popupDuration * 0.7 }
    }

    MouseArea {
      anchors.fill: parent
    }

    LauncherBody {
      id: body
      anchors.fill: parent
      active: launcher.visible
    }
  }
}
