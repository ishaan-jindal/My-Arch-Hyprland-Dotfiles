import QtQuick
import ".."

BarModule {
  id: root

  readonly property int pct: Sys.batteryPct
  readonly property bool charging: Sys.batteryCharging
  readonly property bool critical: !charging && pct <= 15
  readonly property int level: Math.max(0, Math.min(10, Math.floor(pct / 10)))

  visible: Sys.hasBattery
  implicitWidth: Sys.hasBattery ? contentWidth + leftPadding + rightPadding : 0

  text: charging ? "" : pct + "%"
  icon: charging ? Icons.battCharging : Icons.battery[level]
  color: critical ? Theme.critical : charging ? Theme.accentSoft : Theme.fg
  iconColor: critical ? Theme.critical : charging ? Theme.accentSoft : Theme.accent
  interactive: true
  onClicked: ShellState.openCenterSection("power")

  SequentialAnimation on opacity {
    running: root.critical
    loops: Animation.Infinite
    NumberAnimation { to: 0.35; duration: 300 }
    NumberAnimation { to: 1.0; duration: 300 }
    onStopped: root.opacity = 1
  }
}
