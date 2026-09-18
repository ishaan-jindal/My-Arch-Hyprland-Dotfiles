pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Single notification server for the whole shell (replaces swaync).
// Popups mirror swaync's behaviour: timeout 10s (low 5s, critical never),
// do-not-disturb suppresses popups but keeps notifications tracked so they
// still show up in the control centre.
Singleton {
  id: root

  property var popups: []

  NotificationServer {
    id: server
    keepOnReload: true

    onNotification: (notification) => {
      notification.tracked = true;
      if (!ShellState.dnd)
        root.popups = [...root.popups, notification];
    }
  }

  readonly property var tracked: server.trackedNotifications.values

  function timeoutFor(n) {
    if (n.expireTimeout > 0)
      return n.expireTimeout;
    if (n.urgency === NotificationUrgency.Critical)
      return 0;
    if (n.urgency === NotificationUrgency.Low)
      return 5;
    return 10;
  }

  function untrack(n) {
    const idx = popups.indexOf(n);
    if (idx !== -1) {
      const copy = popups.slice();
      copy.splice(idx, 1);
      popups = copy;
    }
  }

  function dismiss(n) {
    untrack(n);
    n.dismiss();
  }
}
