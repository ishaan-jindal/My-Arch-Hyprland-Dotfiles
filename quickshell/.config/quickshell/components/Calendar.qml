import QtQuick
import ".."

// Month calendar with keyboard support:
//   ←/→ day, ↑/↓ week, PgUp/PgDn month, Home today, Enter pick
Item {
  id: root

  property date selected: new Date()
  property date shown: new Date()
  readonly property bool interactive: true

  signal picked(date when)

  readonly property int cellWidth_: 36
  readonly property int cellHeight_: 22
  readonly property int headerHeight: 28

  readonly property var weekdayLabels: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

  function sameDay(a, b) {
    return a.getFullYear() === b.getFullYear()
      && a.getMonth() === b.getMonth()
      && a.getDate() === b.getDate();
  }

  function daysInMonth(year, month) {
    return new Date(year, month + 1, 0).getDate();
  }

  // 0 = Monday … 6 = Sunday
  function firstWeekday(year, month) {
    return (new Date(year, month, 1).getDay() + 6) % 7;
  }

  readonly property var cells: {
    const year = shown.getFullYear();
    const month = shown.getMonth();
    const first = firstWeekday(year, month);
    const count = daysInMonth(year, month);
    const out = [];
    for (let i = 0; i < 42; i++) {
      const dayNumber = i - first + 1;
      out.push({
        date: new Date(year, month, dayNumber),
        inMonth: dayNumber >= 1 && dayNumber <= count
      });
    }
    return out;
  }

  function shift(days) {
    const next = new Date(selected.getFullYear(), selected.getMonth(), selected.getDate() + days);
    selected = next;
    if (next.getMonth() !== shown.getMonth() || next.getFullYear() !== shown.getFullYear())
      shown = next;
  }

  implicitWidth: cellWidth_ * 7
  implicitHeight: headerHeight + cellHeight_ + 7 * cellHeight_

  Keys.onLeftPressed: shift(-1)
  Keys.onRightPressed: shift(1)
  Keys.onUpPressed: shift(-7)
  Keys.onDownPressed: shift(7)
  Keys.onPressed: (event) => {
    if (event.key === Qt.Key_PageUp) {
      shown = new Date(shown.getFullYear(), shown.getMonth() - 1, 1);
      event.accepted = true;
    } else if (event.key === Qt.Key_PageDown) {
      shown = new Date(shown.getFullYear(), shown.getMonth() + 1, 1);
      event.accepted = true;
    } else if (event.key === Qt.Key_Home) {
      const today = new Date();
      selected = today;
      shown = today;
      event.accepted = true;
    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
      root.picked(root.selected);
      event.accepted = true;
    }
  }

  // ---------------------------------------------------------------------
  // Header: month + year, prev/next buttons
  // ---------------------------------------------------------------------
  Item {
    id: header
    width: parent.width
    height: root.headerHeight

    Text {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      text: Qt.formatDateTime(root.shown, "MMMM yyyy")
      color: Theme.bright
      font.family: Theme.fontFamily
      font.pixelSize: 12
      font.bold: true
    }

    Row {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      spacing: 6

      Repeater {
        model: [
          { label: "\u2039", delta: -1, tag: "prev" },
          { label: "\u203a", delta: 1, tag: "next" }
        ]

        delegate: Rectangle {
          required property var modelData

          width: 20
          height: 20
          radius: Theme.radius
          color: navHover.hovered ? Theme.hover : "transparent"
          border.color: Theme.border
          border.width: 1

          Text {
            anchors.centerIn: parent
            text: modelData.label
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 12
          }

          HoverHandler {
            id: navHover
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.shown = new Date(root.shown.getFullYear(), root.shown.getMonth() + modelData.delta, 1)
          }
        }
      }
    }
  }

  // ---------------------------------------------------------------------
  // Weekday strip
  // ---------------------------------------------------------------------
  Row {
    id: weekdayRow
    anchors.top: header.bottom
    width: parent.width

    Repeater {
      model: root.weekdayLabels

      delegate: Text {
        required property string modelData

        width: root.cellWidth_
        height: root.cellHeight_
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: modelData
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: 10
      }
    }
  }

  // ---------------------------------------------------------------------
  // Day grid
  // ---------------------------------------------------------------------
  Grid {
    anchors.top: weekdayRow.bottom
    width: parent.width
    columns: 7

    Repeater {
      model: root.cells

      delegate: Item {
        id: dayCell
        required property var modelData

        readonly property bool isToday: root.sameDay(dayCell.modelData.date, new Date())
        readonly property bool isSelected: root.sameDay(dayCell.modelData.date, root.selected)

        width: root.cellWidth_
        height: root.cellHeight_

        Rectangle {
          anchors.centerIn: parent
          width: parent.width - 4
          height: parent.height - 2
          radius: Theme.radius
          color: dayCell.isSelected ? Theme.hover : "transparent"
          border.width: dayCell.isToday ? 1 : 0
          border.color: Theme.accent

          Text {
            anchors.centerIn: parent
            text: dayCell.modelData.date.getDate()
            color: !dayCell.modelData.inMonth
              ? Theme.muted
              : dayCell.isToday ? Theme.accent : dayCell.isSelected ? Theme.bright : Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 10
            font.bold: dayCell.isToday || dayCell.isSelected
          }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            root.selected = dayCell.modelData.date;
            if (!dayCell.modelData.inMonth)
              root.shown = dayCell.modelData.date;
          }
        }
      }
    }
  }
}
