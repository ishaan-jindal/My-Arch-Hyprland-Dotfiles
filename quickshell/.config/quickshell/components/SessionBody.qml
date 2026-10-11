import QtQuick
import Quickshell
import ".."

// Session grid: lock / hibernate / logout / shutdown / suspend / reboot.
// Same actions as the legacy SessionMenu overlay (now retired); the grid
// sizes from its host width so it fits both the wide card and the pill.
// Letter keys work on the focused button, arrows move between buttons.
Item {
  id: body

  readonly property var actions: [
    { key: "l", icon: Icons.lock, label: "Lock", cmd: ["hyprlock"] },
    { key: "h", icon: Icons.snowflake, label: "Hibernate", cmd: ["systemctl", "hibernate"] },
    { key: "e", icon: Icons.logout, label: "Logout", cmd: ["hyprctl", "dispatch", "hl.dsp.exit()"] },
    { key: "s", icon: Icons.power, label: "Shutdown", cmd: ["systemctl", "poweroff"] },
    { key: "u", icon: Icons.moon, label: "Suspend", cmd: ["systemctl", "suspend"] },
    { key: "r", icon: Icons.reboot, label: "Reboot", cmd: ["systemctl", "reboot"] }
  ]

  property int currentIndex: 0
  property bool active: false
  // Two-step arm for letter keys: first press highlights + arms, second
  // press of the SAME letter (or Enter/Space) runs. Destructive actions
  // never fire on a single keypress.
  property string armedKey: ""

  function focusCurrent() {
    const it = cells.itemAt(currentIndex);
    if (it)
      it.forceActiveFocus();
  }

  // One delayed retry: the host grants Exclusive focus asynchronously.
  Timer {
    id: focusRetry
    interval: 120
    repeat: false
    onTriggered: {
      if (body.active)
        body.focusCurrent();
    }
  }

  onActiveChanged: {
    if (active) {
      armedKey = "";
      focusCurrent();
      focusRetry.restart();
    }
  }

  function run(action) {
    ShellState.closeAllPopups();
    Quickshell.execDetached({ command: action.cmd });
  }

  function move(delta) {
    currentIndex = (currentIndex + delta % 6 + 6) % 6;
    armedKey = "";
    focusCurrent();
  }

  Text {
    id: title
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    text: "Session"
    color: Theme.bright
    font.family: Theme.fontFamily
    font.pixelSize: 14
  }

  Grid {
    anchors.top: title.bottom
    anchors.topMargin: 10
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    columns: 3
    columnSpacing: 10
    rowSpacing: 10

    Repeater {
      id: cells
      model: body.actions

      delegate: Rectangle {
        id: button
        required property var modelData
        required property int index

        readonly property bool current: body.currentIndex === index

        width: Math.floor((body.width - 20) / 3)
        height: (parent.height - 10) / 2
        radius: Theme.radius
        color: current
          ? Qt.lighter(Theme.bg, 1.6)
          : buttonHover.hovered ? Qt.lighter(Theme.bg, 1.6) : "transparent"
        border.color: current ? Theme.accent : Theme.border
        border.width: 1
        scale: buttonPress.pressed ? 0.96 : 1
        activeFocusOnTab: true

        onActiveFocusChanged: {
          if (activeFocus)
            body.currentIndex = index;
        }

        Behavior on color {
          ColorAnimation { duration: Theme.hoverDuration; easing.type: Easing.OutCubic }
        }

        Behavior on border.color {
          ColorAnimation { duration: Theme.hoverDuration; easing.type: Easing.OutCubic }
        }

        Behavior on scale {
          NumberAnimation { duration: Theme.hoverDuration; easing.type: Easing.OutCubic }
        }

        Keys.onPressed: (event) => {
          if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            body.run(button.modelData);
            event.accepted = true;
            return;
          }
          if (event.key === Qt.Key_Left) {
            body.move(-1);
            event.accepted = true;
            return;
          }
          if (event.key === Qt.Key_Right) {
            body.move(1);
            event.accepted = true;
            return;
          }
          if (event.key === Qt.Key_Up) {
            body.move(-3);
            event.accepted = true;
            return;
          }
          if (event.key === Qt.Key_Down) {
            body.move(3);
            event.accepted = true;
            return;
          }
          const text = String(event.text || "").toLowerCase();
          for (let i = 0; i < body.actions.length; i++) {
            if (body.actions[i].key === text) {
              // Two-step: arm on first press, run on confirmation.
              if (body.armedKey === text) {
                body.armedKey = "";
                body.run(body.actions[i]);
              } else {
                body.armedKey = text;
                body.currentIndex = i;
                body.focusCurrent();
              }
              event.accepted = true;
              return;
            }
          }
        }

        Text {
          anchors.top: parent.top
          anchors.topMargin: 12
          anchors.horizontalCenter: parent.horizontalCenter
          text: button.modelData.icon
          color: buttonHover.hovered || button.current ? Theme.accentSoft : Theme.fg
          font.family: Theme.fontFamily
          font.pixelSize: 22

          Behavior on color {
            ColorAnimation { duration: Theme.hoverDuration; easing.type: Easing.OutCubic }
          }
        }

        Text {
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 10
          anchors.horizontalCenter: parent.horizontalCenter
          text: button.modelData.label + "  (" + button.modelData.key + ")"
          color: Theme.muted
          font.family: Theme.fontFamily
          font.pixelSize: 11
        }

        HoverHandler {
          id: buttonHover
        }

        MouseArea {
          id: buttonPress
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onEntered: body.currentIndex = button.index
          onClicked: body.run(button.modelData)
        }
      }
    }
  }
}
