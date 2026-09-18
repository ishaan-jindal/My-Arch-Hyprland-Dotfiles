import QtQuick
import Quickshell
import Quickshell.Bluetooth
import ".."

// Bluetooth panel: adapter toggle, scan, device list with connect / pair /
// disconnect / forget. Keyboard:
//   ↑ ↓ select · Enter connect/pair · Del forget · s scan · Esc back
Item {
  id: root

  signal requestBack()

  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property bool active: visible && ShellState.centerView === "bluetooth"

  // exposed for diagnostics / tests
  readonly property alias btListFocus: deviceList.activeFocus

  readonly property var devices: {
    const out = [];
    if (!adapter)
      return out;
    const list = adapter.devices.values;
    for (let i = 0; i < list.length; i++)
      out.push(list[i]);
    out.sort((a, b) =>
      (b.connected - a.connected)
      || (b.paired - a.paired)
      || (a.name || "").localeCompare(b.name || ""));
    return out;
  }

  onActiveChanged: if (adapter) adapter.discovering = active
  onAdapterChanged: if (adapter) adapter.discovering = active

  function activate(dev) {
    if (dev.connected)
      dev.disconnect();
    else if (dev.paired || dev.bonded)
      dev.connect();
    else
      dev.pair();
  }

  function forget(dev) {
    if (dev.bonded || dev.paired)
      dev.forget();
  }

  // ---------------------------------------------------------------------
  // Header: back, title, adapter toggle
  // ---------------------------------------------------------------------
  Item {
    id: header
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 28

    Rectangle {
      id: backButton
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      width: 26
      height: 24
      radius: Theme.radius
      color: backHover.hovered ? Theme.hover : "transparent"
      border.color: Theme.border
      border.width: 1

      Behavior on color {
        ColorAnimation { duration: Theme.hoverDuration; easing.type: Easing.OutCubic }
      }

      Text {
        anchors.centerIn: parent
        text: "\u2039"
        color: Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: 13
      }

      HoverHandler {
        id: backHover
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.requestBack()
      }
    }

    Text {
      anchors.left: backButton.right
      anchors.leftMargin: 10
      anchors.verticalCenter: parent.verticalCenter
      text: "Bluetooth"
      color: Theme.bright
      font.family: Theme.fontFamily
      font.pixelSize: 13
      font.bold: true
    }

    Row {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      spacing: 8

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.adapter ? (root.adapter.enabled ? "On" : "Off") : "n/a"
        color: root.adapter && root.adapter.enabled ? Theme.accent : Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: 11
      }

      Rectangle {
        width: 40
        height: 20
        radius: 10
        color: root.adapter && root.adapter.enabled ? Theme.accent : Theme.hover
        border.color: Theme.border
        border.width: 1

        Rectangle {
          x: root.adapter && root.adapter.enabled ? parent.width - width - 2 : 2
          anchors.verticalCenter: parent.verticalCenter
          width: 16
          height: 16
          radius: 8
          color: root.adapter && root.adapter.enabled ? Theme.bright : Theme.muted

          Behavior on x {
            NumberAnimation { duration: 120 }
          }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: if (root.adapter) root.adapter.enabled = !root.adapter.enabled
        }
      }
    }
  }

  // ---------------------------------------------------------------------
  // Device list
  // ---------------------------------------------------------------------
  ListView {
    id: deviceList
    anchors.top: header.bottom
    anchors.topMargin: 8
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: footer.top
    anchors.bottomMargin: 6
    clip: true
    spacing: 4
    model: root.devices
    focus: root.active
    keyNavigationWraps: true
    currentIndex: 0
    boundsBehavior: Flickable.StopAtBounds

    Keys.onReturnPressed: root.activate(deviceList.model[deviceList.currentIndex])
    Keys.onEnterPressed: root.activate(deviceList.model[deviceList.currentIndex])
    Keys.onDeletePressed: root.forget(deviceList.model[deviceList.currentIndex])
    Keys.onPressed: (event) => {
      const dev = deviceList.model[deviceList.currentIndex];
      if (event.text.toLowerCase() === "s") {
        if (root.adapter)
          root.adapter.discovering = !root.adapter.discovering;
        event.accepted = true;
      } else if (event.text.toLowerCase() === "f" && dev) {
        root.forget(dev);
        event.accepted = true;
      }
    }

    delegate: Rectangle {
      id: row
      required property var modelData

      readonly property bool current: ListView.isCurrentItem

      width: deviceList.width
      height: 40
      radius: Theme.radius
      color: current ? Theme.hover : rowHover.hovered ? Qt.rgba(Theme.hover.r, Theme.hover.g, Theme.hover.b, 0.5) : "transparent"
      border.color: current ? Theme.accent : Theme.border
      border.width: 1

      Behavior on color {
        ColorAnimation { duration: Theme.hoverDuration; easing.type: Easing.OutCubic }
      }

      Behavior on border.color {
        ColorAnimation { duration: Theme.hoverDuration; easing.type: Easing.OutCubic }
      }

      HoverHandler {
        id: rowHover
      }

      Image {
        id: deviceIcon
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        width: 16
        height: 16
        source: row.modelData.icon ? Quickshell.iconPath(row.modelData.icon, true) : ""
        sourceSize.width: 16
        sourceSize.height: 16
        smooth: true
      }

      Column {
        anchors.left: deviceIcon.right
        anchors.leftMargin: 10
        anchors.right: parent.right
        anchors.rightMargin: 70
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        Text {
          width: parent.width
          text: row.modelData.name || row.modelData.deviceName || row.modelData.address
          color: row.modelData.connected ? Theme.accent : Theme.fg
          font.family: Theme.fontFamily
          font.pixelSize: 12
          elide: Text.ElideRight
        }

        Text {
          width: parent.width
          text: {
            if (row.modelData.connected)
              return "Connected";
            if (row.modelData.pairing)
              return "Pairing…";
            if (row.modelData.paired)
              return "Paired";
            return "Available";
          }
          color: Theme.muted
          font.family: Theme.fontFamily
          font.pixelSize: 10
        }
      }

      Text {
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        text: row.modelData.batteryAvailable ? Math.round(row.modelData.battery * 100) + "%" : ""
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: 10
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activate(row.modelData)
      }
    }
  }

  // ---------------------------------------------------------------------
  // Footer hint
  // ---------------------------------------------------------------------
  Item {
    id: footer
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 16

    Text {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      text: {
        if (!root.adapter)
          return "No Bluetooth adapter";
        if (!root.adapter.enabled)
          return "Bluetooth is off";
        if (root.adapter.discovering)
          return "Scanning…";
        return root.devices.length + " devices · s to scan";
      }
      color: Theme.muted
      font.family: Theme.fontFamily
      font.pixelSize: 10
    }

    Text {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      text: "Enter connect · Del forget · Esc back"
      color: Theme.muted
      font.family: Theme.fontFamily
      font.pixelSize: 10
    }
  }
}
