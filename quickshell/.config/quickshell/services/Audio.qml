pragma Singleton

import QtQuick
import Quickshell
import ".."

// Thin facade: Sys.qml already owns the Pipewire tracker + sink bindings.
Singleton {
  id: root

  readonly property real volume: Sys.volume
  readonly property bool muted: Sys.muted

  function setVolume(v) {
    Sys.setVolume(v);
  }

  function toggleMute() {
    Sys.toggleMute();
  }
}
