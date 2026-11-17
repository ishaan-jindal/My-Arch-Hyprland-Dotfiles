pragma Singleton

import QtQuick
import Quickshell
import ".."

// Notification facade. Notify.qml owns the single NotificationServer on the
// bus; this only mirrors its newest popup and the shared DND flag.
Singleton {
  id: root

  readonly property bool dnd: ShellState.dnd

  function toggleDnd() {
    ShellState.dnd = !ShellState.dnd;
  }

  readonly property var popup: Notify.popups.length > 0 ? Notify.popups[Notify.popups.length - 1] : null
  readonly property bool hasPopup: popup !== null
  readonly property string appName: popup ? (popup.appName || "") : ""
  readonly property string summary: popup ? (popup.summary || "") : ""
  readonly property string body: popup ? (popup.body || "") : ""
  readonly property int urgency: popup ? popup.urgency : 0
}
