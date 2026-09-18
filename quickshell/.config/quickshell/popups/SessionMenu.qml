import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

// Session menu (wlogout replacement).
// Same actions and keybinds as wlogout/layout:
//   l = lock, h = hibernate, e = logout, s = shutdown, u = suspend, r = reboot
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

  readonly property var actions: [
    { key: "l", icon: Icons.lock, label: "Lock", cmd: ["hyprlock"] },
    { key: "h", icon: Icons.snowflake, label: "Hibernate", cmd: ["systemctl", "hibernate"] },
    { key: "e", icon: Icons.logout, label: "Logout", cmd: ["hyprctl", "dispatch", "exit 0"] },
    { key: "s", icon: Icons.power, label: "Shutdown", cmd: ["systemctl", "poweroff"] },
    { key: "u", icon: Icons.moon, label: "Suspend", cmd: ["systemctl", "suspend"] },
    { key: "r", icon: Icons.reboot, label: "Reboot", cmd: ["systemctl", "reboot"] }
  ]

  function run(action) {
    ShellState.sessionOpen = false;
    Quickshell.execDetached({ command: action.cmd });
  }

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
    width: 3 * 190 + 4 * 12
    height: 2 * 110 + 3 * 12 + 56
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

    // swallow clicks so the scrim behind doesn't close the menu
    MouseArea {
      anchors.fill: parent
    }

    Text {
      id: title
      anchors.top: parent.top
      anchors.topMargin: 18
      anchors.horizontalCenter: parent.horizontalCenter
      text: "Session"
      color: Theme.bright
      font.family: Theme.fontFamily
      font.pixelSize: 16
    }

    FocusScope {
      id: keys
      anchors.fill: parent
      focus: sessionMenu.visible

      property int currentIndex: 0

      function move(delta) {
        const n = sessionMenu.actions.length;
        currentIndex = (currentIndex + delta % n + n) % n;
      }

      Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
          ShellState.sessionOpen = false;
          event.accepted = true;
          return;
        }
        if (event.key === Qt.Key_Left) {
          move(-1);
          event.accepted = true;
          return;
        }
        if (event.key === Qt.Key_Right) {
          move(1);
          event.accepted = true;
          return;
        }
        if (event.key === Qt.Key_Up) {
          move(-3);
          event.accepted = true;
          return;
        }
        if (event.key === Qt.Key_Down) {
          move(3);
          event.accepted = true;
          return;
        }
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
          sessionMenu.run(sessionMenu.actions[keys.currentIndex]);
          event.accepted = true;
          return;
        }
        const text = String(event.text || "").toLowerCase();
        for (let i = 0; i < sessionMenu.actions.length; i++) {
          if (sessionMenu.actions[i].key === text) {
            keys.currentIndex = i;
            sessionMenu.run(sessionMenu.actions[i]);
            event.accepted = true;
            return;
          }
        }
      }

      Grid {
        anchors.top: parent.top
        anchors.topMargin: 76
        anchors.horizontalCenter: parent.horizontalCenter
        columns: 3
        spacing: 12

        Repeater {
          model: sessionMenu.actions

          delegate: Rectangle {
            id: button
            required property var modelData
            required property int index

            width: 190
            height: 110
            radius: Theme.radius

            color: keys.currentIndex === index
              ? Qt.lighter(Theme.bg, 1.6)
              : buttonHover.hovered ? Qt.lighter(Theme.bg, 1.6) : "transparent"
            border.color: keys.currentIndex === index ? Theme.accent : Theme.border
            border.width: 1
            scale: buttonPress.pressed ? 0.96 : 1

            Behavior on color {
              ColorAnimation { duration: Theme.hoverDuration; easing.type: Easing.OutCubic }
            }

            Behavior on border.color {
              ColorAnimation { duration: Theme.hoverDuration; easing.type: Easing.OutCubic }
            }

            Behavior on scale {
              NumberAnimation { duration: Theme.hoverDuration; easing.type: Easing.OutCubic }
            }

            Text {
              anchors.top: parent.top
              anchors.topMargin: 20
              anchors.horizontalCenter: parent.horizontalCenter
              text: button.modelData.icon
              color: buttonHover.hovered ? Theme.accentSoft : Theme.fg
              font.family: Theme.fontFamily
              font.pixelSize: 26

              Behavior on color {
                ColorAnimation { duration: Theme.hoverDuration; easing.type: Easing.OutCubic }
              }
            }

            Text {
              anchors.bottom: parent.bottom
              anchors.bottomMargin: 18
              anchors.horizontalCenter: parent.horizontalCenter
              text: button.modelData.label + "  (" + button.modelData.key + ")"
              color: Theme.muted
              font.family: Theme.fontFamily
              font.pixelSize: 12
            }

            HoverHandler {
              id: buttonHover
            }

            MouseArea {
              id: buttonPress
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: sessionMenu.run(button.modelData)
            }
          }
        }
      }
    }
  }
}
