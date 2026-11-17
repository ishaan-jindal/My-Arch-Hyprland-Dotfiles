pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking

// Thin facade over Quickshell.Networking, same device lookup as WifiPanel.
Singleton {
  id: root

  readonly property var device: {
    const devices = Networking.devices.values;
    for (let i = 0; i < devices.length; i++) {
      if (devices[i].type === DeviceType.Wifi)
        return devices[i];
    }
    return null;
  }

  readonly property bool wifiEnabled: Networking.wifiEnabled

  readonly property string ssid: {
    if (!device || !device.networks)
      return "";
    const nets = device.networks.values;
    for (let i = 0; i < nets.length; i++) {
      if (nets[i].connected)
        return nets[i].name || "";
    }
    return "";
  }

  function toggleWifi() {
    Networking.wifiEnabled = !Networking.wifiEnabled;
  }
}
