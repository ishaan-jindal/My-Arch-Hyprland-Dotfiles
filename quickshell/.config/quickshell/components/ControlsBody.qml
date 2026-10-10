import QtQuick
import Quickshell.Networking
import Quickshell.Bluetooth
import ".."

// Controls pane body: quick toggles + brightness/volume sliders +
// battery/profile row, with wifi/bluetooth views embedding their panels
// directly. Extracted from the island so the pane composes from one
// component. Fills its host; `battGlyph`/`battPct` come from the island
// (single source, no duplicate derivation).
Item {
  id: body

  property string battGlyph: ""
  property int battPct: 0

  readonly property var btAdapter: Bluetooth.defaultAdapter

  function cycleProfile() {
    const order = ["performance", "balanced", "power-saver"];
    const i = order.indexOf(Sys.powerProfile);
    Sys.setPowerProfile(order[(i + 1) % order.length]);
  }

  function profileLabel() {
    if (Sys.powerProfile === "performance")
      return "Performance";
    if (Sys.powerProfile === "power-saver")
      return "Saver";
    return "Balanced";
  }

  function focusFirst() {
    wifiToggle.forceActiveFocus();
  }

  Column {
    anchors.fill: parent
    spacing: 10
    opacity: ShellState.centerView === "main" ? 1 : 0
    visible: opacity > 0

    Behavior on opacity {
      NumberAnimation { duration: Theme.viewDuration; easing.type: Easing.OutCubic }
    }

    Row {
      width: parent.width
      spacing: 8

      QuickToggle {
        id: wifiToggle
        icon: Icons.wifi
        label: "Wi-Fi"
        cardWidth: body.width
        on: Networking.wifiEnabled
        tint: Theme.accent
        onActivated: ShellState.openCenterView("wifi")
      }

      QuickToggle {
        icon: Icons.bluetooth
        label: "Bluetooth"
        cardWidth: body.width
        on: body.btAdapter ? body.btAdapter.enabled : false
        tint: Theme.accentSoft
        onActivated: ShellState.openCenterView("bluetooth")
      }

      QuickToggle {
        icon: ShellState.dnd ? Icons.bellSlash : Icons.bell
        label: "DND"
        cardWidth: body.width
        on: ShellState.dnd
        tint: Theme.critical
        onActivated: ShellState.dnd = !ShellState.dnd
      }

      QuickToggle {
        icon: Icons.moon
        label: "Night"
        cardWidth: body.width
        on: Sys.nightLight
        tint: Theme.accentSoft
        onActivated: Theme.toggleNightLight()
      }
    }

    Item {
      width: parent.width
      height: 44

      Text {
        anchors.top: parent.top
        anchors.left: parent.left
        text: "Brightness"
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: 11
      }

      Text {
        anchors.top: parent.top
        anchors.right: parent.right
        text: Sys.brightness + "%"
        color: Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: 11
      }

      BarSlider {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        value: Sys.brightness / 100
        onMoved: (v) => Sys.setBrightness(v * 100)
      }
    }

    Item {
      width: parent.width
      height: 44

      Text {
        anchors.top: parent.top
        anchors.left: parent.left
        text: "Volume · " + Sys.sinkName
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: 11
        elide: Text.ElideRight
        width: parent.width - 70
      }

      Text {
        anchors.top: parent.top
        anchors.right: parent.right
        text: Sys.muted ? "Muted" : Math.round(Sys.volume * 100) + "%"
        color: Sys.muted ? Theme.muted : Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: 11

        MouseArea {
          anchors.fill: parent
          anchors.margins: -4
          cursorShape: Qt.PointingHandCursor
          onClicked: Sys.toggleMute()
        }
      }

      BarSlider {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        value: Sys.volume
        onMoved: (v) => Sys.setVolume(v)
      }
    }

    Item {
      width: parent.width
      height: 34

      Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: Sys.hasBattery
          ? (body.battGlyph + "  Battery " + body.battPct + "% · " + Sys.batteryTimeText())
          : "No battery"
        color: Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: 11
      }

      Rectangle {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: profileLabel.implicitWidth + 20
        height: 26
        radius: Theme.radius
        color: profileHover.hovered ? Theme.hover : "transparent"
        border.color: Theme.border
        border.width: 1

        Behavior on color {
          ColorAnimation { duration: Theme.hoverDuration; easing.type: Easing.OutCubic }
        }

        Text {
          id: profileLabel
          anchors.centerIn: parent
          text: body.profileLabel()
          color: Theme.accent
          font.family: Theme.fontFamily
          font.pixelSize: 10
        }

        HoverHandler {
          id: profileHover
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: body.cycleProfile()
        }
      }
    }
  }

  WifiPanel {
    anchors.fill: parent
    visible: ShellState.islandMode === "controls" && ShellState.centerView === "wifi"
    opacity: ShellState.centerView === "wifi" ? 1 : 0

    Behavior on opacity {
      NumberAnimation { duration: Theme.viewDuration; easing.type: Easing.OutCubic }
    }

    onRequestBack: ShellState.centerBack()
  }

  BluetoothPanel {
    anchors.fill: parent
    visible: ShellState.islandMode === "controls" && ShellState.centerView === "bluetooth"
    opacity: ShellState.centerView === "bluetooth" ? 1 : 0

    Behavior on opacity {
      NumberAnimation { duration: Theme.viewDuration; easing.type: Easing.OutCubic }
    }

    onRequestBack: ShellState.centerBack()
  }
}
