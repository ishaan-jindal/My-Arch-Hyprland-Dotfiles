import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import ".."

// swaync-style notification popups (top right, under the bar).
PanelWindow {
  id: popups

  anchors {
    top: true
    right: true
  }
  margins {
    top: Theme.barMarginTop + Theme.barHeight + 6
    right: Theme.barMarginSide
  }
  implicitWidth: 360
  implicitHeight: column.implicitHeight
  color: "transparent"
  visible: Notify.popups.length > 0
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "quickshell-popup"
  mask: Region {
    item: column
  }

  Column {
    id: column
    width: parent.width
    spacing: 8

    Repeater {
      model: Notify.popups

      delegate: Rectangle {
        id: card
        required property var modelData

        readonly property bool critical: modelData.urgency === NotificationUrgency.Critical

        width: column.width
        height: content.implicitHeight + 24
        color: Theme.bgSolid
        border.color: card.critical ? Theme.critical : Theme.border
        border.width: 1
        radius: Theme.radius
        opacity: 0

        NumberAnimation on opacity {
          from: 0
          to: 1
          duration: 140
          easing.type: Easing.OutCubic
        }

        Timer {
          interval: Notify.timeoutFor(card.modelData) * 1000
          running: interval > 0
          onTriggered: {
            const n = card.modelData;
            Notify.untrack(n);
            n.expire();
          }
        }

        Connections {
          target: card.modelData
          function onClosed(reason) {
            Notify.untrack(card.modelData);
          }
        }

        Column {
          id: content
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.margins: 12
          spacing: 4

          Item {
            width: parent.width
            implicitHeight: appRow.implicitHeight

            Row {
              id: appRow
              width: parent.width
              spacing: 6

              Text {
                text: card.modelData.appName || "Notification"
                color: Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 11
                elide: Text.ElideRight
                width: parent.width - closeButton.width - 6
              }

              Text {
                id: closeButton
                text: Icons.close
                color: closeHover.hovered ? Theme.critical : Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 12

                HoverHandler {
                  id: closeHover
                }

                MouseArea {
                  anchors.fill: parent
                  anchors.margins: -4
                  cursorShape: Qt.PointingHandCursor
                  onClicked: Notify.dismiss(card.modelData)
                }
              }
            }
          }

          Text {
            width: parent.width
            text: card.modelData.summary
            color: Theme.bright
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.bold: true
            wrapMode: Text.Wrap
            elide: Text.ElideRight
            maximumLineCount: 2
            visible: text !== ""
          }

          Text {
            width: parent.width
            text: card.modelData.body
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 12
            wrapMode: Text.Wrap
            elide: Text.ElideRight
            maximumLineCount: 4
            visible: text !== ""
          }

          Row {
            spacing: 8
            visible: card.modelData.actions.length > 0

            Repeater {
              model: card.modelData.actions

              delegate: Rectangle {
                required property var modelData

                width: actionText.implicitWidth + 20
                height: 26
                radius: Theme.radius
                color: actionHover.hovered ? Theme.hover : "transparent"
                border.color: Theme.border
                border.width: 1

                Text {
                  id: actionText
                  anchors.centerIn: parent
                  text: modelData.text
                  color: Theme.fg
                  font.family: Theme.fontFamily
                  font.pixelSize: 11
                }

                HoverHandler {
                  id: actionHover
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: modelData.invoke()
                }
              }
            }
          }
        }
      }
    }
  }
}
