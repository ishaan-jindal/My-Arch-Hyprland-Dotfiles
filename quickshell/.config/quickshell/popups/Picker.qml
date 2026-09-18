import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

// Slide-down theme / wallpaper picker (Super + Shift + T / Super + T).
//
// A centred card that slides out from under the bar, with live previews:
//   - themes: palette swatches rendered in the theme's own colors
//   - wallpapers: image thumbnails (videos show their middle-frame thumb
//     with a play fallback)
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

  readonly property bool wallpapers: ShellState.pickerTab === "wallpapers"

  // exposed for diagnostics / tests
  readonly property bool themeGridFocus: themeGrid.activeFocus
  readonly property bool wallpaperGridFocus: wallpaperGrid.activeFocus
  readonly property int pickerIndex: wallpapers ? wallpaperGrid.currentIndex : themeGrid.currentIndex
  readonly property int pickerCount: wallpapers ? wallpaperGrid.count : themeGrid.count

  function close() {
    ShellState.pickerOpen = false;
  }

  function activateTheme() {
    const names = Theme.themeNames;
    if (themeGrid.currentIndex >= 0 && themeGrid.currentIndex < names.length) {
      Theme.applyTheme(names[themeGrid.currentIndex]);
      close();
    }
  }

  function activateWallpaper() {
    const walls = Theme.wallpapersFor(Theme.current);
    if (wallpaperGrid.currentIndex >= 0 && wallpaperGrid.currentIndex < walls.length) {
      Theme.applyWallpaper(walls[wallpaperGrid.currentIndex].id);
      close();
    }
  }

  onVisibleChanged: {
    if (!visible)
      return;
    const themeIdx = Theme.themeNames.indexOf(Theme.current);
    themeGrid.currentIndex = Math.max(0, themeIdx);
    const walls = Theme.wallpapersFor(Theme.current);
    let wallIdx = 0;
    for (let i = 0; i < walls.length; i++) {
      if (Theme.wallpaperPath(walls[i]) === Theme.currentWallpaper) {
        wallIdx = i;
        break;
      }
    }
    wallpaperGrid.currentIndex = wallIdx;
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
    height: picker.wallpapers ? 560 : 420
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

      // NOTE: Esc/Tab are handled on the GridViews below, not here — key
      // events from the focused grid don't reliably bubble to this scope.

      // ---------------------------------------------------------------
      // Header: tabs + close
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
          spacing: 8

          Rectangle {
            readonly property bool active: !picker.wallpapers

            width: tabThemeRow.implicitWidth + 24
            height: 30
            radius: Theme.radius
            color: active ? Theme.hover : "transparent"
            border.color: active ? Theme.accent : Theme.border
            border.width: 1

            Row {
              id: tabThemeRow
              anchors.centerIn: parent
              spacing: 6

              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Icons.palette
                color: parent.parent.active ? Theme.accent : Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 12
              }

              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Themes"
                color: parent.parent.active ? Theme.bright : Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 12
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: ShellState.pickerTab = "themes"
            }
          }

          Rectangle {
            readonly property bool active: picker.wallpapers

            width: tabWallRow.implicitWidth + 24
            height: 30
            radius: Theme.radius
            color: active ? Theme.hover : "transparent"
            border.color: active ? Theme.accent : Theme.border
            border.width: 1

            Row {
              id: tabWallRow
              anchors.centerIn: parent
              spacing: 6

              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Icons.image
                color: parent.parent.active ? Theme.accent : Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 12
              }

              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Wallpapers"
                color: parent.parent.active ? Theme.bright : Theme.muted
                font.family: Theme.fontFamily
                font.pixelSize: 12
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: ShellState.pickerTab = "wallpapers"
            }
          }
        }

        Text {
          anchors.centerIn: parent
          text: picker.wallpapers ? ("Wallpapers for " + Theme.current) : "Desktop theme"
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
      // Themes grid
      // ---------------------------------------------------------------
      GridView {
        id: themeGrid
        visible: !picker.wallpapers
        focus: picker.visible && !picker.wallpapers
        keyNavigationWraps: true
        Keys.onReturnPressed: picker.activateTheme()
        Keys.onEnterPressed: picker.activateTheme()
        Keys.onSpacePressed: picker.activateTheme()
        Keys.onEscapePressed: picker.close()
        Keys.onTabPressed: ShellState.pickerTab = "wallpapers"
        anchors.top: header.bottom
        anchors.topMargin: 6
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.bottomMargin: 16
        clip: true
        cellWidth: Math.floor(width / 3)
        cellHeight: 128
        model: Theme.themeNames

        delegate: Rectangle {
          id: themeCard
          required property string modelData

          readonly property var pal: Theme.palettes[modelData]
          readonly property bool isCurrent: modelData === Theme.current

          width: themeGrid.cellWidth - 12
          height: themeGrid.cellHeight - 12
          radius: Theme.radius
          color: pal.bgSolid
          border.width: isCurrent ? 2 : 1
          border.color: GridView.isCurrentItem ? Theme.accent : isCurrent ? Theme.accent : Theme.border

          Column {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            Row {
              spacing: 8

              Text {
                text: themeCard.modelData
                color: themeCard.pal.bright
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.bold: true
              }

              Rectangle {
                visible: themeCard.isCurrent
                anchors.verticalCenter: parent.verticalCenter
                width: badge.implicitWidth + 12
                height: 18
                radius: 4
                color: "transparent"
                border.color: themeCard.pal.accent
                border.width: 1

                Text {
                  id: badge
                  anchors.centerIn: parent
                  text: "current"
                  color: themeCard.pal.accent
                  font.family: Theme.fontFamily
                  font.pixelSize: 9
                }
              }
            }

            Row {
              spacing: 6

              Repeater {
                model: [
                  themeCard.pal.bg, themeCard.pal.fg, themeCard.pal.accent,
                  themeCard.pal.accentSoft, themeCard.pal.critical
                ]

                delegate: Rectangle {
                  required property var modelData

                  width: 22
                  height: 22
                  radius: 5
                  color: modelData
                  border.color: themeCard.pal.border
                  border.width: 1
                }
              }
            }

            Text {
              width: parent.width
              text: Theme.themeTags(themeCard.modelData).join(" · ")
              color: themeCard.pal.muted
              font.family: Theme.fontFamily
              font.pixelSize: 11
              elide: Text.ElideRight
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              Theme.applyTheme(themeCard.modelData);
              picker.close();
            }
          }
        }
      }

      // ---------------------------------------------------------------
      // Wallpapers grid (current theme's tagged wallpapers)
      // ---------------------------------------------------------------
      GridView {
        id: wallpaperGrid
        visible: picker.wallpapers
        focus: picker.visible && picker.wallpapers
        keyNavigationWraps: true
        Keys.onReturnPressed: picker.activateWallpaper()
        Keys.onEnterPressed: picker.activateWallpaper()
        Keys.onSpacePressed: picker.activateWallpaper()
        Keys.onEscapePressed: picker.close()
        Keys.onTabPressed: ShellState.pickerTab = "themes"
        anchors.top: header.bottom
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
        model: Theme.wallpapersFor(Theme.current)

        delegate: Rectangle {
          id: wallCard
          required property var modelData

          readonly property string abs: Theme.wallpaperPath(modelData)
          readonly property bool isVideo: /\.mp4$/i.test(modelData.path)
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
              source: "file://" + Theme.wallpaperThumb(wallCard.modelData)
              sourceSize.width: 512
              sourceSize.height: 256
              fillMode: Image.PreserveAspectCrop
              visible: status === Image.Ready
              asynchronous: true
            }
          }

          Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 8
            spacing: 0

            Text {
              width: parent.width
              text: Theme.wallpaperName(wallCard.modelData)
              color: wallCard.isCurrent ? Theme.accent : Theme.fg
              font.family: Theme.fontFamily
              font.pixelSize: 10
              elide: Text.ElideMiddle
            }

            Text {
              width: parent.width
              visible: (wallCard.modelData.tags || []).length > 0
              text: (wallCard.modelData.tags || []).join(", ")
              color: Theme.muted
              font.family: Theme.fontFamily
              font.pixelSize: 9
              elide: Text.ElideRight
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              Theme.applyWallpaper(wallCard.modelData.id);
              picker.close();
            }
          }
        }
      }
    }
  }
}
