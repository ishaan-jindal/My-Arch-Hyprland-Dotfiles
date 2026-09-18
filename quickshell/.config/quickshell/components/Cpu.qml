import QtQuick
import ".."

BarModule {
  text: Sys.cpu + "%"
  icon: Icons.cpu
  interactive: true
  onClicked: ShellState.openCenterSection("system")
}
