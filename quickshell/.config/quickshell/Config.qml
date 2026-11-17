pragma Singleton

import Quickshell

// User-facing shell behaviour switches. Read-only consumers; nothing here
// polls, persists or spawns processes.
Singleton {
  property bool reduceMotion: false
  property bool enableNotifications: true  // Quickshell owns org.freedesktop.Notifications (verified)
  property bool showOnAllMonitors: true
  property int autoDismissMs: 1800
  property int notifDismissMs: 5000
}
