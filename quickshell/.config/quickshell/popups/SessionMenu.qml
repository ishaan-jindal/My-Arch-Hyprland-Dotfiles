import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../components"

// Legacy session overlay window (retired as the pill host —
// ShellState.toggleSession drives `islandMode` now, so `sessionOpen`
// never goes true in normal use). Kept as a thin wrapper around
// SessionBody so the UI still works if the legacy bool is ever set.
PanelWindow {
  id: sessionMenu

  anchors {
    top: true
    left: true
    right: true
    bottom: true
  }
  color: "transparent"
  visible: ShellState.sessionOpen
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "quickshell-popup"
  WlrLayershell.keyboardFocus: ShellState.sessionOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  // dim scrim, click outside to close
  Rectangle {
    id: backdrop
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.4 * (ShellState.sessionOpen ? 1 : 0))

    Behavior on color {
      ColorAnimation { duration: Theme.popupDuration; easing.type: Easing.OutCubic }
    }

    MouseArea {
      anchors.fill: parent
      onClicked: ShellState.sessionOpen = false
    }
  }

  Rectangle {
    id: card
    anchors.centerIn: parent
    width: 618
    height: 312
    color: Theme.bgSolid
    border.color: Theme.border
    border.width: 1
    radius: Theme.radius

    scale: ShellState.sessionOpen ? 1 : 0.97

    Behavior on scale {
      NumberAnimation { duration: Theme.popupDuration; easing.type: Easing.OutQuint }
    }

    transform: Translate {
      y: ShellState.sessionOpen ? 0 : 40

      Behavior on y {
        NumberAnimation { duration: Theme.popupDuration; easing.type: Easing.OutQuint }
      }
    }

    opacity: ShellState.sessionOpen ? 1 : 0

    Behavior on opacity {
      NumberAnimation { duration: Theme.popupDuration * 0.7 }
    }

    MouseArea {
      anchors.fill: parent
    }

    FocusScope {
      anchors.fill: parent
      focus: sessionMenu.visible

      Keys.onEscapePressed: ShellState.sessionOpen = false

      SessionBody {
        anchors.fill: parent
        anchors.margins: 18
      }
    }
  }
}
