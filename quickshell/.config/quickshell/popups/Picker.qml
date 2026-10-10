import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../components"

// Legacy wallpaper picker overlay window (retired as the pill host —
// ShellState.togglePicker drives `islandMode` now, so `pickerOpen`
// never goes true in normal use). Kept as a thin wrapper around
// WallpaperBody so the UI still works if the legacy bool is ever set.
PanelWindow {
  id: picker

  anchors {
    top: true
    left: true
    right: true
    bottom: true
  }
  color: "transparent"
  visible: ShellState.pickerOpen
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "quickshell-popup"
  WlrLayershell.keyboardFocus: ShellState.pickerOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  // kept for shell.qml diagnostics
  readonly property alias pickerIndex: body.pickerIndex
  readonly property alias pickerCount: body.pickerCount
  readonly property alias wallpaperGridFocus: body.wallpaperGridFocus

  // dim scrim, click outside to close
  Rectangle {
    id: backdrop
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, Theme.scrimOpacity * (ShellState.pickerOpen ? 1 : 0))

    Behavior on color {
      ColorAnimation { duration: Theme.popupDuration; easing.type: Easing.OutCubic }
    }

    MouseArea {
      anchors.fill: parent
      onClicked: ShellState.pickerOpen = false
    }
  }

  Rectangle {
    id: card
    anchors.top: parent.top
    anchors.topMargin: Theme.barMarginTop + Theme.barHeight + 8
    anchors.horizontalCenter: parent.horizontalCenter
    width: Math.min(1120, parent.width - 80)
    height: 560
    color: Theme.bgSolid
    border.color: Theme.border
    border.width: 1
    radius: Theme.radius

    scale: ShellState.pickerOpen ? 1 : 0.985

    Behavior on scale {
      NumberAnimation { duration: Theme.popupDuration; easing.type: Easing.OutQuint }
    }

    transform: Translate {
      y: ShellState.pickerOpen ? 0 : -110

      Behavior on y {
        NumberAnimation { duration: Theme.popupDuration; easing.type: Easing.OutQuint }
      }
    }

    opacity: ShellState.pickerOpen ? 1 : 0

    Behavior on opacity {
      NumberAnimation { duration: Theme.popupDuration * 0.7 }
    }

    MouseArea {
      anchors.fill: parent
    }

    WallpaperBody {
      id: body
      anchors.fill: parent
      anchors.margins: 16
      active: picker.visible
    }
  }
}
