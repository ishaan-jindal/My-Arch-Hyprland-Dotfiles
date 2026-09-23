import QtQuick
import ".."

// Pill button used by the control centre quick toggle row.
// cardWidth is injected by the caller (was ccCard.width before extraction).
Rectangle {
  id: pill
  property string icon: ""
  property string label: ""
  property bool on: false
  property color tint: Theme.accent
  property real cardWidth: 0
  signal activated()

  width: (cardWidth - 32 - 3 * 8) / 4
  height: 48
  radius: Theme.radius
  color: pillHover.hovered
    ? (on ? Qt.rgba(tint.r, tint.g, tint.b, 0.30) : Qt.rgba(tint.r, tint.g, tint.b, 0.08))
    : (on ? Qt.rgba(tint.r, tint.g, tint.b, 0.22) : "transparent")
  border.color: activeFocus ? Theme.bright : on ? tint : Theme.border
  border.width: 1
  activeFocusOnTab: true

  Behavior on color {
    ColorAnimation { duration: Theme.hoverDuration; easing.type: Easing.OutCubic }
  }

  Behavior on border.color {
    ColorAnimation { duration: Theme.hoverDuration; easing.type: Easing.OutCubic }
  }

  Behavior on scale {
    NumberAnimation { duration: Theme.hoverDuration; easing.type: Easing.OutCubic }
  }

  scale: pillPress.pressed ? 0.97 : 1

  Column {
    anchors.centerIn: parent
    spacing: 2

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: pill.icon
      color: pill.on || pillHover.hovered ? pill.tint : Theme.fg
      font.family: Theme.fontFamily
      font.pixelSize: 15

      Behavior on color {
        ColorAnimation { duration: Theme.hoverDuration; easing.type: Easing.OutCubic }
      }
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: pill.label
      color: pill.on || pillHover.hovered ? pill.tint : Theme.muted
      font.family: Theme.fontFamily
      font.pixelSize: 9

      Behavior on color {
        ColorAnimation { duration: Theme.hoverDuration; easing.type: Easing.OutCubic }
      }
    }
  }

  Keys.onSpacePressed: pill.activated()
  Keys.onReturnPressed: pill.activated()
  Keys.onEnterPressed: pill.activated()

  HoverHandler {
    id: pillHover
  }

  MouseArea {
    id: pillPress
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: pill.activated()
  }
}
