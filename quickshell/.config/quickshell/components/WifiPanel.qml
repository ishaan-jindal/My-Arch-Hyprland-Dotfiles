import QtQuick
import Quickshell
import Quickshell.Networking
import ".."

// Wi-Fi panel: toggle radio, list access points, connect (with PSK prompt),
// disconnect, and rescan. Fully keyboard driven:
//   ↑ ↓ select · Enter connect/disconnect · s scan · Esc back
Item {
  id: root

  signal requestBack()

  readonly property var device: {
    const devices = Networking.devices.values;
    for (let i = 0; i < devices.length; i++)
      if (devices[i].type === DeviceType.Wifi)
        return devices[i];
    return null;
  }

  readonly property bool active: visible && ShellState.centerView === "wifi"

  // exposed for diagnostics / tests
  readonly property alias wifiListFocus: networkList.activeFocus

  readonly property var networks: {
    const out = [];
    if (!device || !device.networks)
      return out;
    const nets = device.networks.values;
    for (let i = 0; i < nets.length; i++)
      out.push(nets[i]);
    out.sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength));
    return out;
  }

  property var pending: null
  property string password: ""
  property string errorText: ""

  onDeviceChanged: if (device) device.scannerEnabled = active
  onActiveChanged: if (device) device.scannerEnabled = active

  function isOpen(net) {
    return net.security === WifiSecurityType.Open || net.security === WifiSecurityType.Owe;
  }

  function activate(net) {
    if (net.connected) {
      net.disconnect();
      return;
    }
    if (net.known || isOpen(net)) {
      net.connect();
      return;
    }
    pending = net;
    password = "";
    errorText = "";
  }

  component SignalBars: Item {
    property real strength: 0
    property color barColor: Theme.fg

    width: 18
    height: 14

    Row {
      anchors.bottom: parent.bottom
      spacing: 2

      Repeater {
        model: 4

        delegate: Rectangle {
          required property int index

          width: 3
          height: 4 + index * 3
          radius: 1
          color: strength * 4 >= index + 1 ? barColor : Theme.muted
        }
      }
    }
  }

  // ---------------------------------------------------------------------
  // Header: back, title, radio toggle
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
      text: "Wi-Fi"
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
        text: Networking.wifiEnabled ? "On" : "Off"
        color: Networking.wifiEnabled ? Theme.accent : Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: 11
      }

      Rectangle {
        width: 40
        height: 20
        radius: 10
        color: Networking.wifiEnabled ? Theme.accent : Theme.hover
        border.color: Theme.border
        border.width: 1

        Rectangle {
          x: Networking.wifiEnabled ? parent.width - width - 2 : 2
          anchors.verticalCenter: parent.verticalCenter
          width: 16
          height: 16
          radius: 8
          color: Networking.wifiEnabled ? Theme.bright : Theme.muted

          Behavior on x {
            NumberAnimation { duration: 120 }
          }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
        }
      }
    }
  }

  // ---------------------------------------------------------------------
  // Network list
  // ---------------------------------------------------------------------
  ListView {
    id: networkList
    anchors.top: header.bottom
    anchors.topMargin: 8
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: footer.top
    anchors.bottomMargin: 6
    clip: true
    spacing: 4
    model: root.networks
    focus: root.active && root.pending === null
    keyNavigationWraps: true
    currentIndex: 0
    boundsBehavior: Flickable.StopAtBounds

    Keys.onReturnPressed: root.activate(networkList.model[networkList.currentIndex])
    Keys.onEnterPressed: root.activate(networkList.model[networkList.currentIndex])
    Keys.onPressed: (event) => {
      if (event.text.toLowerCase() === "s") {
        if (root.device)
          root.device.scannerEnabled = !root.device.scannerEnabled;
        event.accepted = true;
      }
    }

    delegate: Rectangle {
      id: row
      required property var modelData

      readonly property bool current: ListView.isCurrentItem

      width: networkList.width
      height: 40
      radius: Theme.radius
      color: current ? Theme.hover : "transparent"
      border.color: current ? Theme.accent : Theme.border
      border.width: 1

      SignalBars {
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        strength: row.modelData.signalStrength
        barColor: row.modelData.connected ? Theme.accent : Theme.fg
      }

      Text {
        anchors.left: parent.left
        anchors.leftMargin: 36
        anchors.right: parent.right
        anchors.rightMargin: 64
        anchors.verticalCenter: parent.verticalCenter
        text: (row.modelData.connected ? Icons.wifiIcon(row.modelData.signalStrength) + "  " : "")
          + row.modelData.name
          + (root.isOpen(row.modelData) ? "" : "  " + Icons.lock)
        color: row.modelData.connected ? Theme.accent : Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: 12
        elide: Text.ElideRight
      }

      Text {
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        text: row.modelData.connected ? "Disconnect" : "Connect"
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
  // Password prompt
  // ---------------------------------------------------------------------
  FocusScope {
    id: prompt
    visible: root.pending !== null
    enabled: visible
    anchors.centerIn: parent
    width: parent.width - 24
    height: 140

    onVisibleChanged: if (visible) passwordInput.forceActiveFocus()

    Rectangle {
      anchors.fill: parent
      color: Theme.bgSolid
      border.color: Theme.accent
      border.width: 1
      radius: Theme.radius
    }

    Column {
      anchors.fill: parent
      anchors.margins: 14
      spacing: 10

      Text {
        width: parent.width
        text: root.pending ? ("Password for " + root.pending.name) : ""
        color: Theme.bright
        font.family: Theme.fontFamily
        font.pixelSize: 12
        elide: Text.ElideRight
      }

      Rectangle {
        width: parent.width
        height: 32
        radius: Theme.radius
        color: "transparent"
        border.color: passwordInput.activeFocus ? Theme.accent : Theme.border
        border.width: 1

        TextInput {
          id: passwordInput
          anchors.fill: parent
          anchors.leftMargin: 10
          anchors.rightMargin: 10
          verticalAlignment: TextInput.AlignVCenter
          echoMode: TextInput.Password
          color: Theme.fg
          font.family: Theme.fontFamily
          font.pixelSize: 13
          passwordCharacter: "•"
          clip: true

          onTextChanged: root.password = text

          Keys.onReturnPressed: connectButton.activate()
          Keys.onEnterPressed: connectButton.activate()
          Keys.onEscapePressed: root.pending = null
        }
      }

      Text {
        width: parent.width
        visible: root.errorText !== ""
        text: root.errorText
        color: Theme.critical
        font.family: Theme.fontFamily
        font.pixelSize: 10
      }

      Row {
        anchors.right: parent.right
        spacing: 8

        Rectangle {
          id: connectButton
          width: 84
          height: 28
          radius: Theme.radius
          color: connectHover.hovered ? Theme.hover : "transparent"
          border.color: Theme.accent
          border.width: 1

          function activate() {
            if (!root.pending)
              return;
            root.pending.connectWithPsk(root.password);
            root.pending = null;
          }

          Text {
            anchors.centerIn: parent
            text: "Connect"
            color: Theme.accent
            font.family: Theme.fontFamily
            font.pixelSize: 11
          }

          HoverHandler {
            id: connectHover
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: connectButton.activate()
          }
        }

        Rectangle {
          width: 84
          height: 28
          radius: Theme.radius
          color: cancelHover.hovered ? Theme.hover : "transparent"
          border.color: Theme.border
          border.width: 1

          Text {
            anchors.centerIn: parent
            text: "Cancel"
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 11
          }

          HoverHandler {
            id: cancelHover
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.pending = null
          }
        }
      }
    }

    Connections {
      target: root.pending
      function onNoSecrets() {
        root.errorText = "Wrong password - try again";
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
        if (!root.device)
          return "No Wi-Fi device";
        if (!Networking.wifiEnabled)
          return "Wi-Fi is off";
        return root.device.scannerEnabled ? "Scanning…" : "s to rescan";
      }
      color: Theme.muted
      font.family: Theme.fontFamily
      font.pixelSize: 10
    }

    Text {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      text: "Enter connect · Esc back"
      color: Theme.muted
      font.family: Theme.fontFamily
      font.pixelSize: 10
    }
  }
}
