import QtQuick
import Quickshell.Networking
import ".."

BarModule {
  readonly property var activeDevice: {
    const devices = Networking.devices.values;
    for (let i = 0; i < devices.length; i++)
      if (devices[i].connected)
        return devices[i];
    return devices.length > 0 ? devices[0] : null;
  }

  readonly property var activeNetwork: {
    const dev = activeDevice;
    if (!dev || !dev.networks)
      return null;
    const nets = dev.networks.values;
    for (let i = 0; i < nets.length; i++)
      if (nets[i].connected)
        return nets[i];
    return null;
  }

  readonly property bool wifi: activeDevice && activeDevice.type === DeviceType.Wifi
  readonly property bool connected: activeDevice && activeDevice.connected

  text: {
    if (activeNetwork && wifi)
      return activeNetwork.name + " (" + Math.round(activeNetwork.signalStrength * 100) + "%)";
    if (connected)
      return "";
    return "No Connection";
  }
  icon: {
    if (activeNetwork && wifi)
      return Icons.wifiIcon(activeNetwork.signalStrength);
    if (connected)
      return Icons.eth;
    return Icons.warning;
  }
  color: connected ? Theme.fg : Theme.critical
  iconColor: connected ? Theme.accent : Theme.critical
  interactive: true
  onClicked: ShellState.openCenterView("wifi")
}
