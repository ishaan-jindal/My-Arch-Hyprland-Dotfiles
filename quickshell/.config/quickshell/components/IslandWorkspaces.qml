import QtQuick
import Quickshell
import Quickshell.Hyprland
import ".."

// Fixed 5-dot workspace strip for the Dynamic Island.
// Active dot uses the wallpaper accent with a soft halo, occupied is
// white at 45%, empty is white at 18% (an urgent workspace shows
// Theme.critical).
// Click a dot to go there, scroll to move by id.
Item {
  id: root

  property var barScreen
  property real dotSize: 6
  property int spaces: 5

  // Wallpaper-driven accent (same token the pill uses), fallback #92C1D8.
  readonly property color accent: Theme.accent !== undefined ? Theme.accent : "#92C1D8"

  implicitWidth: row.implicitWidth
  implicitHeight: Math.max(16, dotSize + 10)

  readonly property var monitor: barScreen ? Hyprland.monitorFor(barScreen) : null

  // id -> workspace, this monitor only (special workspaces skipped).
  readonly property var byId: {
    const map = {};
    const all = Hyprland.workspaces.values;
    for (let i = 0; i < all.length; i++) {
      const ws = all[i];
      if (ws.id <= 0)
        continue;
      if (root.monitor && ws.monitor !== root.monitor)
        continue;
      map[ws.id] = ws;
    }
    return map;
  }

  readonly property int activeId: {
    const ids = Object.keys(root.byId);
    for (let i = 0; i < ids.length; i++)
      if (root.byId[ids[i]].focused)
        return Number(ids[i]);
    return -1;
  }

  function go(id) {
    const ws = root.byId[id];
    if (ws) {
      ws.activate();
      return;
    }
    // Empty workspace: no object to activate, ask Hyprland to create it.
    Quickshell.execDetached({ command: ["hyprctl", "dispatch", "workspace", String(id)] });
  }

  function cycle(delta) {
    const next = Math.max(1, Math.min(root.spaces, (root.activeId < 0 ? 1 : root.activeId) + delta));
    root.go(next);
  }

  Row {
    id: row
    anchors.centerIn: parent
    spacing: 6

    Repeater {
      model: root.spaces

      delegate: Item {
        id: dotHit
        required property int index

        readonly property int wsId: index + 1
        readonly property var ws: root.byId[wsId] || null
        readonly property bool isActive: root.activeId === wsId
        readonly property bool occupied: ws !== null
        readonly property bool urgent: ws !== null && ws.urgent

        width: 16
        height: 16

        // Halo behind the active dot.
        Rectangle {
          anchors.centerIn: parent
          width: 12
          height: 12
          radius: 6
          color: root.accent
          opacity: dotHit.isActive ? 0.28 : 0
          visible: opacity > 0

          Behavior on opacity {
            NumberAnimation { duration: Theme.hoverDuration; easing.type: Easing.OutCubic }
          }
        }

        Rectangle {
          id: dot
          anchors.centerIn: parent
          width: root.dotSize
          height: root.dotSize
          radius: root.dotSize / 2
          color: dotHit.urgent ? Theme.critical : dotHit.isActive ? root.accent : occupiedColor()
          scale: dotHit.isActive ? 1.25 : dotHover.hovered ? 1.2 : 1

          function occupiedColor() {
            return dotHit.occupied ? Qt.rgba(1, 1, 1, 0.45) : Qt.rgba(1, 1, 1, 0.18);
          }

          Behavior on color {
            ColorAnimation { duration: Theme.hoverDuration; easing.type: Easing.OutCubic }
          }

          Behavior on scale {
            SpringAnimation { spring: 5.2; damping: 0.34; mass: 0.6 }
          }
        }

        HoverHandler {
          id: dotHover
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: root.go(dotHit.wsId)
        }
      }
    }
  }

  WheelHandler {
    onWheel: (event) => root.cycle(event.angleDelta.y > 0 ? -1 : 1)
  }
}
