import QtQuick
import Quickshell.Bluetooth
import ".."

// Bluetooth status: adapter state + connected device count.
// Opens the control centre's Bluetooth view.
BarModule {
  readonly property var adapter: Bluetooth.defaultAdapter

  readonly property int connectedCount: {
    if (!adapter)
      return 0;
    let n = 0;
    const devices = adapter.devices.values;
    for (let i = 0; i < devices.length; i++)
      if (devices[i].connected)
        n++;
    return n;
  }

  text: connectedCount > 0 ? connectedCount : ""
  icon: connectedCount > 0 ? Icons.bluetoothConnected : Icons.bluetoothOff
  color: !adapter || !adapter.enabled
    ? Theme.muted
    : connectedCount > 0 ? Theme.accentSoft : Theme.fg
  interactive: true
  onClicked: ShellState.openCenterView("bluetooth")
}
