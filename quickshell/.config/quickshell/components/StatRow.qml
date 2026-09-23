import QtQuick
import ".."

// Mini stat row with bar (control centre system section).
Item {
  property string label: ""
  property string value: ""
  property real fraction: 0

  width: parent ? parent.width : 0
  height: 30

  Text {
    id: statLabel
    anchors.left: parent.left
    anchors.top: parent.top
    text: label
    color: Theme.muted
    font.family: Theme.fontFamily
    font.pixelSize: 11
  }

  Text {
    anchors.right: parent.right
    anchors.top: parent.top
    text: value
    color: Theme.fg
    font.family: Theme.fontFamily
    font.pixelSize: 11
  }

  Rectangle {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 5
    radius: 2
    color: Theme.hover

    Rectangle {
      width: parent.width * Math.max(0, Math.min(1, fraction))
      height: parent.height
      radius: parent.radius
      color: Theme.accent
    }
  }
}
