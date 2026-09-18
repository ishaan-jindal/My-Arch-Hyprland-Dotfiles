import QtQuick
import ".."

BarModule {
  id: root

  property string time: Qt.formatDateTime(new Date(), "hh:mm")

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: root.time = Qt.formatDateTime(new Date(), "hh:mm")
  }

  text: root.time
  color: Theme.bright
  leftPadding: 25
  rightPadding: 25
  interactive: true
  onClicked: ShellState.openCenterSection("calendar")
}
