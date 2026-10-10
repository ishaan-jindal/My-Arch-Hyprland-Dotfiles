import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../components"

// Legacy keybind cheatsheet overlay window (retired as the pill host —
// ShellState.toggleCheatsheet drives `islandMode` now, so
// `cheatsheetOpen` never goes true in normal use). Kept as a thin
// wrapper around CheatsheetBody (two-column spread at this width).
PanelWindow {
  id: cheatsheet

  anchors {
    top: true
    left: true
    right: true
    bottom: true
  }
  color: "transparent"
  visible: ShellState.cheatsheetOpen
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "quickshell-popup"
  WlrLayershell.keyboardFocus: ShellState.cheatsheetOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  Rectangle {
    id: backdrop
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.4 * (ShellState.cheatsheetOpen ? 1 : 0))

    Behavior on color {
      ColorAnimation { duration: Theme.popupDuration; easing.type: Easing.OutCubic }
    }

    MouseArea {
      anchors.fill: parent
      onClicked: ShellState.cheatsheetOpen = false
    }
  }

  Rectangle {
    id: card
    anchors.centerIn: parent
    width: 980
    height: 720
    color: Theme.bgSolid
    border.color: Theme.border
    border.width: 1
    radius: Theme.radius

    scale: ShellState.cheatsheetOpen ? 1 : 0.97

    Behavior on scale {
      NumberAnimation { duration: Theme.popupDuration; easing.type: Easing.OutQuint }
    }

    transform: Translate {
      y: ShellState.cheatsheetOpen ? 0 : 30

      Behavior on y {
        NumberAnimation { duration: Theme.popupDuration; easing.type: Easing.OutQuint }
      }
    }

    opacity: ShellState.cheatsheetOpen ? 1 : 0

    Behavior on opacity {
      NumberAnimation { duration: Theme.popupDuration * 0.7 }
    }

    MouseArea {
      anchors.fill: parent
    }

    FocusScope {
      anchors.fill: parent
      focus: cheatsheet.visible

      Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
          ShellState.cheatsheetOpen = false;
          event.accepted = true;
        }
      }

      CheatsheetBody {
        anchors.fill: parent
        anchors.margins: 22
      }
    }
  }
}
