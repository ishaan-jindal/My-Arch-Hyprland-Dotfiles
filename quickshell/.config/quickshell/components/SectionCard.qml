import QtQuick
import ".."

// Section card; highlights when a bar widget deep-links to it.
// contentWidth is injected by the caller (was flick.width before extraction).
Rectangle {
  id: card
  property string sectionId: ""
  property string title: ""
  property real contentWidth: 0
  default property alias body: inner.children

  readonly property bool active: ShellState.centerSection === card.sectionId && card.sectionId !== ""

  width: contentWidth
  height: inner.implicitHeight + 28
  radius: Theme.radius
  color: Theme.bg
  border.color: active ? Theme.accent : Theme.border
  border.width: active ? 2 : 1

  Behavior on y {
    NumberAnimation { duration: Theme.viewDuration; easing.type: Easing.OutCubic }
  }

  Behavior on border.color {
    ColorAnimation { duration: Theme.hoverDuration }
  }

  Column {
    id: inner
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: 14
    spacing: 10

    Text {
      visible: card.title !== ""
      width: parent.width
      text: card.title
      color: card.active ? Theme.accent : Theme.muted
      font.family: Theme.fontFamily
      font.pixelSize: 11
      font.bold: true
    }
  }
}
