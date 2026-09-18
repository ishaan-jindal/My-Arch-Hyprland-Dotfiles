import QtQuick
import ".."

// Shared base for the text-style bar modules.
// Mirrors the Waybar module contract: 8px horizontal padding, bar height,
// optional left/right/middle click handlers.
//
// The value and the glyph are separate Text elements so the icon can render
// larger than the text (Nerd Font glyphs read small at body size in Qt).
Item {
  id: root

  property string text: ""
  property string icon: ""
  property color color: Theme.fg
  // Icons follow the generated accent so a wallpaper switch visibly
  // re-themes the whole bar; modules with status states set their own
  // iconColor explicitly (muted/critical/…).
  property color iconColor: Theme.accent
  property int iconSize: Theme.fontSize + 5
  property bool interactive: false
  property int leftPadding: Theme.widgetPadding
  property int rightPadding: Theme.widgetPadding
  readonly property alias contentWidth: content.implicitWidth

  signal clicked()
  signal rightClicked()
  signal middleClicked()

  implicitWidth: content.implicitWidth + leftPadding + rightPadding
  implicitHeight: Theme.barHeight

  Row {
    id: content
    anchors.centerIn: parent
    spacing: 0

    Text {
      id: label
      visible: root.text !== ""
      anchors.verticalCenter: parent.verticalCenter
      text: root.text
      color: root.color
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontSize
    }

    Text {
      id: glyph
      visible: root.icon !== ""
      anchors.verticalCenter: parent.verticalCenter
      // Single separating space between value and icon.
      text: " " + root.icon
      color: root.iconColor
      font.family: Theme.fontFamily
      font.pixelSize: root.iconSize
    }
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: (mouse) => {
      if (mouse.button === Qt.LeftButton)
        root.clicked();
      else if (mouse.button === Qt.RightButton)
        root.rightClicked();
      else
        root.middleClicked();
    }
  }
}
