pragma Singleton

import QtQuick
import Quickshell
import ".."

// Thin facade over Sys's UPower displayDevice bindings.
Singleton {
  id: root

  readonly property bool available: Sys.hasBattery
  readonly property int percent: Sys.batteryPct
  readonly property bool charging: Sys.batteryCharging

  // "Full in 38 min" / "2h 5m left" / "Full" (Sys owns the UPower math).
  readonly property string timeText: Sys.batteryTimeText()
}
