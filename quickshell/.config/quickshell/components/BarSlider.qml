import QtQuick
import ".."

// Generic slider with keyboard support (←/→ ±1%).
Item {
  id: slider
  property real value: 0
  signal moved(real newValue)

  height: 16
  activeFocusOnTab: true

  function nudge(delta) {
    slider.moved(Math.max(0, Math.min(1, slider.value + delta)));
  }

  Keys.onLeftPressed: nudge(-0.01)
  Keys.onRightPressed: nudge(0.01)
  Keys.onDownPressed: nudge(-0.01)
  Keys.onUpPressed: nudge(0.01)

  Rectangle {
    anchors.verticalCenter: parent.verticalCenter
    width: parent.width
    height: 6
    radius: 3
    color: Theme.hover
    border.color: slider.activeFocus ? Theme.accent : "transparent"
    border.width: 1

    Behavior on border.color {
      ColorAnimation { duration: Theme.hoverDuration }
    }

    Rectangle {
      width: parent.width * Math.max(0, Math.min(1, slider.value))
      height: parent.height
      radius: parent.radius
      color: Theme.accent

      Behavior on width {
        NumberAnimation { duration: 90; easing.type: Easing.OutCubic }
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    function setFromX(x) {
      slider.moved(Math.max(0, Math.min(1, x / width)));
    }
    onPressed: (mouse) => setFromX(mouse.x)
    onPositionChanged: (mouse) => {
      if (mouse.buttons & Qt.LeftButton)
        setFromX(mouse.x);
    }
  }
}
