import QtQuick
import ".."

BarModule {
  readonly property int pct: Sys.brightness
  readonly property int idx: Math.max(0, Math.min(Icons.brightness.length - 1,
    Math.floor(pct / 100 * Icons.brightness.length - 0.0001)))

  text: pct + "%"
  icon: Icons.brightness[idx]
  interactive: true
  onClicked: ShellState.openCenterSection("display")
  onRightClicked: Theme.toggleNightLight()
}
