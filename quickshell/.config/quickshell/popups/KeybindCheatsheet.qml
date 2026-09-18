import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

// Keybind cheatsheet (Super + K).
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
  WlrLayershell.keyboardFocus: ShellState.cheatsheetOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  readonly property var sections: [
    {
      title: "Launcher & apps",
      binds: [
        { keys: "SUPER + RETURN", desc: "Terminal (ghostty)" },
        { keys: "SUPER + R", desc: "App launcher" },
        { keys: "SUPER + B", desc: "Browser (zen-browser)" },
        { keys: "SUPER + E", desc: "File manager (nemo)" },
        { keys: "SUPER + M", desc: "Android emulator" }
      ]
    },
    {
      title: "Shell (Quickshell)",
      binds: [
        { keys: "SUPER + C", desc: "Control centre (audio/media/notifs)" },
        { keys: "SUPER + V", desc: "Clipboard history" },
        { keys: "SUPER + T", desc: "Wallpaper picker (theme follows wallpaper)" },
        { keys: "SUPER + K", desc: "This cheatsheet" },
        { keys: "SUPER + L", desc: "Session menu" },
        { keys: "SUPER + SHIFT + K", desc: "Stop Quickshell" },
        { keys: "SUPER + SHIFT + W", desc: "Start Quickshell" }
      ]
    },
    {
      title: "Windows",
      binds: [
        { keys: "SUPER + Q", desc: "Close window" },
        { keys: "SUPER + A", desc: "Toggle floating" },
        { keys: "SUPER + F", desc: "Fullscreen" },
        { keys: "SUPER + P", desc: "Pin window" },
        { keys: "SUPER + J", desc: "Toggle split direction" },
        { keys: "SUPER + ←/→/↑/↓", desc: "Move focus" },
        { keys: "SUPER + drag", desc: "Move window" },
        { keys: "SUPER + right-drag", desc: "Resize window" }
      ]
    },
    {
      title: "Workspaces",
      binds: [
        { keys: "SUPER + 1…0", desc: "Switch workspace" },
        { keys: "SUPER + SHIFT + 1…0", desc: "Move window to workspace" },
        { keys: "SUPER + S", desc: "Toggle special workspace (magic)" },
        { keys: "SUPER + SHIFT + S", desc: "Move window to special" },
        { keys: "SUPER + wheel", desc: "Cycle workspaces" },
        { keys: "3-finger swipe", desc: "Workspaces / special" }
      ]
    },
    {
      title: "Media & system",
      binds: [
        { keys: "Media keys", desc: "Play/pause, next, previous (playerctl)" },
        { keys: "Volume keys", desc: "Volume / mute (wpctl)" },
        { keys: "Mic mute key", desc: "Toggle microphone" },
        { keys: "Brightness keys", desc: "Backlight (brightnessctl)" },
        { keys: "SUPER + N", desc: "Night light (hyprsunset)" },
        { keys: "SUPER + Z", desc: "Cursor zoom (2x)" },
        { keys: "Print", desc: "Region screenshot (hyprshot)" }
      ]
    },
    {
      title: "Session menu keys",
      binds: [
        { keys: "l", desc: "Lock (hyprlock)" },
        { keys: "h", desc: "Hibernate" },
        { keys: "e", desc: "Logout" },
        { keys: "s", desc: "Shutdown" },
        { keys: "u", desc: "Suspend" },
        { keys: "r", desc: "Reboot" }
      ]
    }
  ]

  component BindRow: Item {
    id: row
    required property var modelData

    width: parent ? parent.width : 0
    height: 24

    Row {
      id: chips
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      spacing: 3

      Repeater {
        model: row.modelData.keys.split(" + ")

        delegate: Rectangle {
          required property string modelData

          height: 18
          width: chipText.implicitWidth + 12
          radius: 4
          color: "transparent"
          border.color: Theme.border
          border.width: 1
          anchors.verticalCenter: parent.verticalCenter

          Text {
            id: chipText
            anchors.centerIn: parent
            text: modelData
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: 9
          }
        }
      }
    }

    Text {
      anchors.left: chips.right
      anchors.leftMargin: 10
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      text: row.modelData.desc
      color: Theme.fg
      font.family: Theme.fontFamily
      font.pixelSize: 11
      elide: Text.ElideRight
    }
  }

  component Section: Column {
    id: section
    required property var modelData

    width: parent ? parent.width : 0
    spacing: 2

    Text {
      text: section.modelData.title
      color: Theme.accent
      font.family: Theme.fontFamily
      font.pixelSize: 12
      font.bold: true
      bottomPadding: 4
    }

    Repeater {
      model: section.modelData.binds
      delegate: BindRow {}
    }
  }

  Rectangle {
    anchors.fill: parent
    color: "#66000000"

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

      Text {
        id: title
        anchors.top: parent.top
        anchors.topMargin: 22
        anchors.horizontalCenter: parent.horizontalCenter
        text: "Keybinds"
        color: Theme.bright
        font.family: Theme.fontFamily
        font.pixelSize: 18
      }

      Text {
        anchors.top: title.bottom
        anchors.topMargin: 4
        anchors.horizontalCenter: parent.horizontalCenter
        text: "Super + K or Esc to close"
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: 10
      }

      Row {
        anchors.top: title.bottom
        anchors.topMargin: 34
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 40

        Column {
          width: 420
          spacing: 16

          Repeater {
            model: cheatsheet.sections.slice(0, 3)
            delegate: Section {}
          }
        }

        Column {
          width: 420
          spacing: 16

          Repeater {
            model: cheatsheet.sections.slice(3)
            delegate: Section {}
          }
        }
      }
    }
  }
}
