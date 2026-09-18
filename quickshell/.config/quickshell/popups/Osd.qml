import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

// Transient OSD for volume / brightness / mic changes, positioned under the
// bar exactly where the old notify-send bubbles appeared.
PanelWindow {
  id: osd

  anchors {
    top: true
    left: true
    right: true
  }
  margins.top: Theme.barMarginTop + Theme.barHeight + 14
  implicitHeight: 56
  color: "transparent"
  visible: ShellState.osdVisible
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "quickshell-popup"
  mask: Region {
    item: box
  }

  readonly property string icon: {
    if (ShellState.osdKind === "brightness") {
      const idx = Math.max(0, Math.min(Icons.brightness.length - 1,
        Math.floor(ShellState.osdValue * Icons.brightness.length - 0.0001)));
      return Icons.brightness[idx];
    }
    if (ShellState.osdKind === "mic")
      return ShellState.osdValue <= 0.001 ? Icons.micOff : Icons.mic;
    if (ShellState.osdValue <= 0.001)
      return Icons.audioMuted;
    if (ShellState.osdValue < 0.34)
      return Icons.volLow;
    if (ShellState.osdValue < 0.67)
      return Icons.volMid;
    return Icons.volHigh;
  }

  readonly property string label: {
    if (ShellState.osdKind === "brightness")
      return "Brightness  " + ShellState.osdText;
    if (ShellState.osdKind === "mic")
      return ShellState.osdText;
    return "Volume  " + ShellState.osdText;
  }

  Rectangle {
    id: box
    anchors.centerIn: parent
    width: 320
    height: 48
    color: Theme.bgSolid
    border.color: Theme.border
    border.width: 1
    radius: Theme.radius

    Text {
      id: iconText
      anchors.left: parent.left
      anchors.leftMargin: 16
      anchors.verticalCenter: parent.verticalCenter
      text: osd.icon
      color: Theme.fg
      font.family: Theme.fontFamily
      font.pixelSize: 18
    }

    Column {
      anchors.left: iconText.right
      anchors.leftMargin: 14
      anchors.right: parent.right
      anchors.rightMargin: 16
      anchors.verticalCenter: parent.verticalCenter
      spacing: 6

      Text {
        text: osd.label
        color: Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: 12
      }

      Rectangle {
        width: parent.width
        height: 6
        radius: 3
        color: Theme.hover

        Rectangle {
          width: parent.width * ShellState.osdValue
          height: parent.height
          radius: parent.radius
          color: Theme.accent

          Behavior on width {
            NumberAnimation { duration: 90 }
          }
        }
      }
    }
  }
}
