import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

// Slide-down wallpaper picker (Super + T).
//
// A centred card that slides out from under the bar. The model is a live
// scan of the wallpaper assets dir (`wallpaper_switch.sh list-json`), so
// newly added files appear with no restart and no registry. Selecting one
// applies it and regenerates the desktop palette from it (matugen, dark).
PanelWindow {
  id: picker

  anchors {
    top: true
    left: true
    right: true
    bottom: true
  }
  color: "transparent"
  visible: ShellState.pickerOpen
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: ShellState.pickerOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  // exposed for diagnostics / tests
  readonly property bool wallpaperGridFocus: wallpaperGrid.activeFocus
  readonly property int pickerIndex: wallpaperGrid.currentIndex
  readonly property int pickerCount: wallpaperGrid.count

  function close() {
    ShellState.pickerOpen = false;
  }

  function activateWallpaper() {
    const walls = filteredWalls;
    if (wallpaperGrid.currentIndex >= 0 && wallpaperGrid.currentIndex < walls.length) {
      Theme.applyWallpaper(walls[wallpaperGrid.currentIndex].path);
      close();
    }
  }

  // Live name filter (case-insensitive substring).
  property string query: ""

  readonly property var filteredWalls: {
    const q = query.trim().toLowerCase();
    const walls = Theme.walls;
    if (q === "")
      return walls;
    const out = [];
    for (let i = 0; i < walls.length; i++) {
      if (String(walls[i].name).toLowerCase().indexOf(q) !== -1)
        out.push(walls[i]);
    }
    return out;
  }

  onQueryChanged: wallpaperGrid.currentIndex = 0

  onVisibleChanged: {
    if (!visible)
      return;
    query = "";
    searchInput.text = "";
    Theme.refreshWallpapers();
    const walls = Theme.walls;
    let wallIdx = 0;
    for (let i = 0; i < walls.length; i++) {
      if (walls[i].path === Theme.currentWallpaper) {
        wallIdx = i;
        break;
      }
    }
    wallpaperGrid.currentIndex = wallIdx;
    searchInput.forceActiveFocus();
  }

  // dim scrim, click outside to close
  Rectangle {
    anchors.fill: parent
    color: "#4d000000"

    MouseArea {
      anchors.fill: parent
      onClicked: picker.close()
    }
  }

  Rectangle {
    id: card
    anchors.top: parent.top
    anchors.topMargin: Theme.barMarginTop + Theme.barHeight + 8
    anchors.horizontalCenter: parent.horizontalCenter
    width: Math.min(1120, parent.width - 80)
    height: 560
    color: Theme.bgSolid
    border.color: Theme.border
    border.width: 1
    radius: Theme.radius

    Behavior on height {
      NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
    }

    transform: Translate {
      y: ShellState.pickerOpen ? 0 : -90

      Behavior on y {
        NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
      }
    }

    opacity: ShellState.pickerOpen ? 1 : 0

    Behavior on opacity {
      NumberAnimation { duration: 180 }
    }

    MouseArea {
      anchors.fill: parent
    }

    FocusScope {
      anchors.fill: parent
      focus: picker.visible

      // ---------------------------------------------------------------
      // Header
      // ---------------------------------------------------------------
      Item {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 16
        height: 30

        Row {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          spacing: 6

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Icons.image
            color: Theme.accent
            font.family: Theme.fontFamily
            font.pixelSize: 12
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Wallpapers"
            color: Theme.bright
            font.family: Theme.fontFamily
            font.pixelSize: 12
          }
        }

        Text {
          anchors.centerIn: parent
          text: filteredWalls.length + " / " + Theme.walls.length + " wallpapers · theme follows wallpaper"
          color: Theme.muted
          font.family: Theme.fontFamily
          font.pixelSize: 11
        }

        Text {
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          text: Icons.close
          color: closeHover.hovered ? Theme.critical : Theme.muted
          font.family: Theme.fontFamily
          font.pixelSize: 14

          HoverHandler {
            id: closeHover
          }

          MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            cursorShape: Qt.PointingHandCursor
            onClicked: picker.close()
          }
        }
      }

      // ---------------------------------------------------------------
      // Search (filters by filename, case-insensitive)
      // ---------------------------------------------------------------
      Item {
        id: searchBox
        anchors.top: header.bottom
        anchors.topMargin: 6
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        height: 34

        Rectangle {
          anchors.fill: parent
          radius: Theme.radius
          color: Theme.bg
          border.color: searchInput.activeFocus ? Theme.accent : Theme.border
          border.width: 1

          Text {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: Icons.search
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: 12
          }

          TextInput {
            id: searchInput
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 34
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            onTextChanged: picker.query = text
            color: Theme.fg
            selectionColor: Theme.accent
            selectedTextColor: Theme.bgSolid
            font.family: Theme.fontFamily
            font.pixelSize: 12
            clip: true

            Text {
              anchors.fill: parent
              visible: parent.displayText === ""
              text: "Search wallpapers…"
              color: Theme.muted
              font.family: Theme.fontFamily
              font.pixelSize: 12
              verticalAlignment: Text.AlignVCenter
            }

            Keys.onDownPressed: {
              if (filteredWalls.length > 0)
                wallpaperGrid.forceActiveFocus();
            }
            Keys.onReturnPressed: picker.activateWallpaper()
            Keys.onEnterPressed: picker.activateWallpaper()
            Keys.onEscapePressed: {
              if (searchInput.displayText !== "")
                searchInput.text = "";
              else
                picker.close();
            }
          }
        }
      }

      // ---------------------------------------------------------------
      // Empty state
      // ---------------------------------------------------------------
      Text {
        visible: filteredWalls.length === 0
        anchors.top: searchBox.bottom
        anchors.topMargin: 40
        anchors.horizontalCenter: parent.horizontalCenter
        text: "No wallpapers match \"" + query + "\""
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: 12
      }

      // ---------------------------------------------------------------
      // Wallpapers grid (live scan of the assets dir)
      // ---------------------------------------------------------------
      GridView {
        id: wallpaperGrid
        focus: false
        keyNavigationWraps: true
        Keys.onReturnPressed: picker.activateWallpaper()
        Keys.onEnterPressed: picker.activateWallpaper()
        Keys.onSpacePressed: picker.activateWallpaper()
        Keys.onEscapePressed: picker.close()
        Keys.onUpPressed: {
          const cols = Math.max(1, Math.floor(wallpaperGrid.width / wallpaperGrid.cellWidth));
          if (wallpaperGrid.currentIndex < cols)
            searchInput.forceActiveFocus();
          else
            wallpaperGrid.moveCurrentIndexUp();
        }
        anchors.top: searchBox.bottom
        anchors.topMargin: 6
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.bottomMargin: 16
        clip: true
        cellWidth: Math.floor(width / 4)
        cellHeight: 172
        model: filteredWalls

        delegate: Rectangle {
          id: wallCard
          required property var modelData

          readonly property string abs: modelData.path
          readonly property bool isVideo: modelData.isVideo === true
          readonly property string thumb: modelData.thumb || ""
          readonly property bool isCurrent: abs === Theme.currentWallpaper

          width: wallpaperGrid.cellWidth - 12
          height: wallpaperGrid.cellHeight - 12
          radius: Theme.radius
          color: Theme.bg
          border.width: isCurrent ? 2 : 1
          border.color: GridView.isCurrentItem ? Theme.accent : isCurrent ? Theme.accent : Theme.border

          Image {
            anchors.fill: parent
            anchors.margins: parent.border.width
            anchors.bottomMargin: 34
            source: wallCard.isVideo ? "" : "file://" + wallCard.abs
            sourceSize.width: 512
            sourceSize.height: 256
            fillMode: Image.PreserveAspectCrop
            visible: !wallCard.isVideo
            asynchronous: true
          }

          Item {
            anchors.fill: parent
            anchors.margins: parent.border.width
            anchors.bottomMargin: 34
            visible: wallCard.isVideo

            // play glyph underneath: shows while the thumb loads and stays
            // as the fallback if the thumbnail is missing
            Text {
              anchors.centerIn: parent
              text: Icons.play
              color: Theme.muted
              font.family: Theme.fontFamily
              font.pixelSize: 26
            }

            Image {
              id: thumbImg
              anchors.fill: parent
              source: wallCard.thumb !== "" ? "file://" + wallCard.thumb : ""
              sourceSize.width: 512
              sourceSize.height: 256
              fillMode: Image.PreserveAspectCrop
              visible: status === Image.Ready
              asynchronous: true
            }
          }

          Text {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 8
            text: modelData.name
            color: wallCard.isCurrent ? Theme.accent : Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 10
            elide: Text.ElideMiddle
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              Theme.applyWallpaper(wallCard.modelData.path);
              picker.close();
            }
          }
        }
      }
    }
  }
}
