import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

// Top bar, one PanelWindow per monitor.
// Geometry/font/copy tuned to match the Waybar base config:
// height 40, margin top 10 / sides 20, three rounded islands, spacing 6.
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
      implicitHeight: Theme.barHeight
      margins {
        top: Theme.barMarginTop
        left: Theme.barMarginSide
        right: Theme.barMarginSide
      }
      color: "transparent"
      // Default ExclusionMode.Auto reserves height + margins, exactly like
      // the Waybar margin-top setup.
      WlrLayershell.namespace: "quickshell-bar"

      // -----------------------------------------------------------------
      // Left island: workspaces
      // -----------------------------------------------------------------
      Rectangle {
        id: leftIsland
        anchors.left: parent.left
        anchors.leftMargin: Theme.islandMargin
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
        width: leftRow.width + 12
        color: Theme.bg
        border.color: Theme.border
        border.width: 1
        radius: Theme.radius

        Row {
          id: leftRow
          anchors.centerIn: parent
          spacing: Theme.barSpacing

          Workspaces {
            barScreen: bar.screen
          }
        }
      }

      // -----------------------------------------------------------------
      // Center island: clock
      // -----------------------------------------------------------------
      Rectangle {
        id: centerIsland
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
        width: centerRow.width + 12
        color: Theme.bg
        border.color: Theme.border
        border.width: 1
        radius: Theme.radius

        Row {
          id: centerRow
          anchors.centerIn: parent
          spacing: Theme.barSpacing

          Clock {}
        }
      }

      // -----------------------------------------------------------------
      // Right island: status modules + tray
      // -----------------------------------------------------------------
      Rectangle {
        id: rightIsland
        anchors.right: parent.right
        anchors.rightMargin: Theme.islandMargin
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
        width: rightRow.width + 12
        color: Theme.bg
        border.color: Theme.border
        border.width: 1
        radius: Theme.radius

        Row {
          id: rightRow
          anchors.centerIn: parent
          spacing: Theme.barSpacing

          NetWidget {}
          Bluetooth {}
          Audio {}
          Cpu {}
          Memory {}
          Temperature {}
          Backlight {}
          Battery {}
          Tray {}
        }
      }
    }
  }
}
