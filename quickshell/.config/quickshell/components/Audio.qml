import QtQuick
import Quickshell
import ".."

BarModule {
  readonly property real vol: Sys.volume
  readonly property bool muted: Sys.muted
  readonly property string glyph: muted
    ? Icons.audioMuted
    : vol < 0.34 ? Icons.volLow : vol < 0.67 ? Icons.volMid : Icons.volHigh

  text: Math.round(vol * 100) + "%"
  icon: glyph
  color: muted ? Theme.muted : Theme.fg
  interactive: true
  onClicked: ShellState.openCenterSection("audio")
  onMiddleClicked: Sys.toggleMute()
  onRightClicked: Quickshell.execDetached({ command: ["pavucontrol"] })
}
