import QtQuick
import Quickshell.Services.SystemTray
import ".."

// System tray (icon-size 20, spacing 10 - same as the Waybar tray module).
Item {
  id: root

  implicitHeight: Theme.barHeight
  implicitWidth: row.implicitWidth
  visible: SystemTray.items.values.length > 0

  Row {
    id: row
    anchors.centerIn: parent
    spacing: 10

    Repeater {
      model: SystemTray.items

      delegate: Item {
        id: trayItem
        required property var modelData

        width: 20
        height: root.height

        Image {
          anchors.centerIn: parent
          width: 20
          height: 20
          source: trayItem.modelData.icon
          sourceSize.width: 20
          sourceSize.height: 20
          smooth: true
        }

        MouseArea {
          id: area
          anchors.fill: parent
          acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
          cursorShape: Qt.PointingHandCursor
          onClicked: (mouse) => {
            const item = trayItem.modelData;
            if (mouse.button === Qt.LeftButton) {
              item.activate();
            } else if (mouse.button === Qt.MiddleButton) {
              item.secondaryActivate();
            } else if (mouse.button === Qt.RightButton && item.hasMenu) {
              const win = Window.window;
              if (win) {
                const pos = area.mapToItem(win.contentItem, mouse.x, mouse.y);
                item.display(win, Math.round(pos.x), Math.round(pos.y));
              }
            }
          }
        }
      }
    }
  }
}
