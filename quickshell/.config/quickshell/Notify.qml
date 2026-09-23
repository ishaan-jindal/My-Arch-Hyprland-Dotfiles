pragma Singleton

import QtQuick
import QtQml
import Quickshell
import Quickshell.Services.Notifications

// Single notification server for the whole shell (replaces swaync).
// Popups mirror swaync's behaviour: timeout 10s (low 5s, critical never),
// do-not-disturb suppresses popups but keeps notifications tracked so they
// still show up in the control centre.
//
// popupModel is the incremental view model for the popup stack. Each row is
// stamped at creation with an absolute dismissAt deadline plus lifeMs, so a
// delegate created later (or rebuilt) resumes its remaining time instead of
// restarting it. ListModel keeps a stable identity and updates row-by-row,
// so adding or removing one popup never recreates the other cards: their
// Timers, entrance state and progress bars keep running untouched.
// popups stays as a plain array mirror so `Notify.popups.length` readers
// keep working.
Singleton {
  id: root

  property var popups: []
  property ListModel popupModel: ListModel {
  }

  NotificationServer {
    id: server
    keepOnReload: true

    onNotification: (notification) => {
      notification.tracked = true;
      if (ShellState.dnd)
        return;
      const lifeMs = root.timeoutFor(notification) * 1000;
      root.popups = [...root.popups, notification];
      root.popupModel.append({
        "notif": notification,
        "dismissAt": lifeMs > 0 ? Date.now() + lifeMs : 0,
        "lifeMs": lifeMs
      });
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
    if (idx === -1) {
      removeFromModel(n);
      return;
    }
    const copy = popups.slice();
    copy.splice(idx, 1);
    popups = copy;
    // Array and model stay in lockstep (append-only at the end, same
    // element removed from both), so the indices match.
    if (idx >= 0 && idx < popupModel.count)
      popupModel.remove(idx);
    else
      removeFromModel(n);
  }

  // Fallback removal by identity, for closes that arrive without an
  // array entry (e.g. server-side close racing an exit fade).
  function removeFromModel(n) {
    for (let i = 0; i < popupModel.count; ++i) {
      if (popupModel.get(i).notif === n) {
        popupModel.remove(i);
        return;
      }
    }
  }

  function dismiss(n) {
    untrack(n);
    n.dismiss();
  }

  function dismissAll() {
    if (popups.length === 0)
      return;
    const copy = popups.slice();
    popups = [];
    popupModel.clear();
    for (let i = 0; i < copy.length; ++i)
      copy[i].dismiss();
  }

  function clearAll() {
    dismissAll();
  }
}
