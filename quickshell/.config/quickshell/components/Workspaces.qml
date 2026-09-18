import QtQuick
import Quickshell
import Quickshell.Hyprland
import ".."

// Hyprland workspace strip, filtered to the bar's monitor exactly like
// `hyprland/workspaces` in the Waybar config.
// Format: "{icon} {id}" with the focused workspace underlined.
Item {
  id: root

  property var barScreen
  implicitHeight: Theme.barHeight
  implicitWidth: row.implicitWidth + 8 // #workspaces margin: 0 4px

  readonly property var monitor: barScreen ? Hyprland.monitorFor(barScreen) : null

  readonly property var workspaces: {
    const all = Hyprland.workspaces.values;
    const out = [];
    for (let i = 0; i < all.length; i++) {
      const ws = all[i];
      if (ws.id <= 0)
        continue; // skip special:magic
      if (monitor && ws.monitor !== monitor)
        continue;
      out.push(ws);
    }
    out.sort((a, b) => a.id - b.id);
    return out;
  }

  function cycle(delta) {
    const list = workspaces;
    if (list.length === 0)
      return;
    let idx = 0;
    for (let i = 0; i < list.length; i++)
      if (list[i].focused)
        idx = i;
    const next = Math.max(0, Math.min(list.length - 1, idx + delta));
    if (next !== idx)
      list[next].activate();
  }

  Row {
    id: row
    anchors.centerIn: parent
    spacing: 0

    Repeater {
      model: root.workspaces

      delegate: Item {
        id: wsItem
        required property var modelData

        readonly property bool focused: modelData.focused
        readonly property bool urgent: modelData.urgent

        width: wsLabel.implicitWidth + 12 // button padding: 0 6px
        height: root.height

        Text {
          id: wsLabel
          anchors.centerIn: parent
          text: (wsItem.focused ? Icons.wsActive : Icons.wsDefault) + " " + wsItem.modelData.id
          color: wsItem.urgent ? Theme.critical
            : wsItem.focused ? Theme.bright
            : wsHover.hovered ? Theme.accentSoft : Theme.muted
          font.family: Theme.fontFamily
          font.pixelSize: Theme.fontSize + 2 // Waybar buttons are 15px
        }

        // focused / hover underline (Waybar: box-shadow inset 0 -2px)
        Rectangle {
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 4
          anchors.horizontalCenter: parent.horizontalCenter
          width: parent.width - 8
          height: 2
          radius: 1
          color: wsItem.focused ? Theme.accent : wsHover.hovered ? Theme.hover : "transparent"
        }

        HoverHandler {
          id: wsHover
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: wsItem.modelData.activate()
        }
      }
    }
  }

  WheelHandler {
    onWheel: (event) => root.cycle(event.angleDelta.y > 0 ? -1 : 1)
  }
}
