import QtQuick
import ".."

BarModule {
  text: Sys.memUsed.toFixed(1) + "G"
  icon: Icons.mem
  interactive: true
  onClicked: ShellState.openCenterSection("system")
}
