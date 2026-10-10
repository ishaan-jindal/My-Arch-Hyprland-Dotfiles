import QtQuick
import ".."

// Wallpaper picker body: search + live grid of the wallpaper assets dir.
// Extracted from the legacy Picker overlay window (now retired) so the
// pill hosts it inline — no duplication. Fills its host; the grid drops
// from 4 columns (wide card) to 2 (pill). Selecting a wallpaper applies
// it and regenerates the palette (matugen, dark).
Item {
  id: wall

  property bool active: false

  // exposed for diagnostics / tests
  readonly property bool wallpaperGridFocus: wallpaperGrid.activeFocus
  readonly property int pickerIndex: wallpaperGrid.currentIndex
  readonly property int pickerCount: wallpaperGrid.count

  function close() {
    ShellState.islandMode = "";
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

  function reset() {
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

  onActiveChanged: {
    if (active) {
      reset();
      focusTries = 0;
      focusRetry.restart();
    } else {
      focusRetry.stop();
    }
  }

  // ---------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------
  Item {
    id: header
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
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
        onClicked: wall.close()
      }
    }
  }

  // ---------------------------------------------------------------------
  // Search (filters by filename, case-insensitive)
  // ---------------------------------------------------------------------
  Item {
    id: searchBox
    anchors.top: header.bottom
    anchors.topMargin: 6
    anchors.left: parent.left
    anchors.right: parent.right
    height: 34

    Rectangle {
      anchors.fill: parent
      radius: Theme.radius
      color: "transparent"
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
        onTextChanged: wall.query = text
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
        Keys.onReturnPressed: wall.activateWallpaper()
        Keys.onEnterPressed: wall.activateWallpaper()
        Keys.onEscapePressed: {
          if (searchInput.displayText !== "")
            searchInput.text = "";
          else
            wall.close();
        }
      }
    }
  }

  // ---------------------------------------------------------------------
  // Empty state
  // ---------------------------------------------------------------------
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

  // ---------------------------------------------------------------------
  // Wallpapers grid (live scan of the assets dir)
  // ---------------------------------------------------------------------
  GridView {
    id: wallpaperGrid
    focus: false
    keyNavigationWraps: true
    Keys.onReturnPressed: wall.activateWallpaper()
    Keys.onEnterPressed: wall.activateWallpaper()
    Keys.onSpacePressed: wall.activateWallpaper()
    Keys.onEscapePressed: wall.close()
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
    clip: true
    cellWidth: Math.floor(width / (wall.width > 700 ? 4 : 2))
    cellHeight: 172
    flickDeceleration: 900
    maximumFlickVelocity: 3200
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
      color: "transparent"
      border.width: isCurrent ? 2 : 1
      border.color: GridView.isCurrentItem ? Theme.accent : isCurrent ? Theme.accent : cardHover.hovered ? Theme.muted : Theme.border

      Behavior on border.color {
        ColorAnimation { duration: Theme.hoverDuration; easing.type: Easing.OutCubic }
      }

      Behavior on scale {
        NumberAnimation { duration: Theme.hoverDuration; easing.type: Easing.OutCubic }
      }

      scale: cardHover.hovered ? 1.02 : 1

      HoverHandler {
        id: cardHover
      }

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
          wall.close();
        }
      }
    }
  }

  // Up to 3 retries at 120ms: the compositor Exclusive grant can lag
  // activation, and a single shot can race it.
  property int focusTries: 0

  Timer {
    id: focusRetry
    interval: 120
    repeat: true
    onTriggered: {
      if (!wall.active || searchInput.activeFocus) {
        focusRetry.stop();
        return;
      }
      searchInput.forceActiveFocus();
      wall.focusTries++;
      if (wall.focusTries >= 3)
        focusRetry.stop();
    }
  }
}
