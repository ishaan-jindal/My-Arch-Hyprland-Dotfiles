pragma Singleton

import QtQuick
import Quickshell
import ".."

// Thin facade over Sys.brightness (0..100 from `brightnessctl -m`).
// available stays true: brightnessctl is a hard dependency here, and Sys
// already reports 0 rather than failing when it is missing.
Singleton {
  id: root

  readonly property bool available: true
  readonly property real level: available ? Sys.brightness / 100 : -1

  function setLevel(v) {
    if (!available)
      return;
    Sys.setBrightness(Math.max(0, Math.min(1, v)) * 100);
  }
}
