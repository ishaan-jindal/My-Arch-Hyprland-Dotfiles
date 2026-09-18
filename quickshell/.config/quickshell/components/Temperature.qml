import QtQuick
import ".."

BarModule {
  readonly property int t: Math.round(Sys.temp)
  readonly property string glyph: t >= 70 ? Icons.tempHigh : t >= 50 ? Icons.tempMid : Icons.tempLow

  text: t + "°C"
  icon: glyph
  color: t >= 80 ? Theme.critical : Theme.fg
  interactive: true
  onClicked: ShellState.openCenterSection("system")
}
