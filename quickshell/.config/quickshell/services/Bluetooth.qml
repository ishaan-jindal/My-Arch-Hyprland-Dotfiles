pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth

// Thin facade over the default Bluetooth adapter (may be null until bluez
// shows up, so every read is guarded).
Singleton {
  id: root

  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property bool enabled: adapter ? adapter.enabled : false

  function toggleEnabled() {
    if (adapter)
      adapter.enabled = !adapter.enabled;
  }
}
