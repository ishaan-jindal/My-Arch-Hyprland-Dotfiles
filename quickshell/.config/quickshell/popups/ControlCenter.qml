import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Quickshell.Networking
import Quickshell.Bluetooth
import ".."
import "../components"

// Control centre: quick toggles, system/display/power/sound sections,
// calendar, media and notifications, plus dedicated Wi-Fi and Bluetooth
// views. A centred top popout (niri-style dropdown).
//
// Keyboard: Tab/Shift+Tab move focus, Space/Enter activate, arrows adjust
// sliders and move through lists/calendar, Esc backs out, then closes.
// Bar widgets deep-link here via ShellState.openCenterSection().
PanelWindow {
  id: cc

  anchors {
    top: true
    left: true
    right: true
    bottom: true
  }
  color: "transparent"
  visible: ShellState.centerOpen
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "quickshell-popup"
  WlrLayershell.keyboardFocus: ShellState.centerOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

  readonly property bool mainView: ShellState.centerView === "main"
  readonly property bool wifiView: ShellState.centerView === "wifi"
  readonly property bool btView: ShellState.centerView === "bluetooth"

  // exposed for diagnostics / tests
  readonly property alias calendarSelected: calendar.selected
  readonly property bool wifiListFocus: wifiPanel.wifiListFocus
  readonly property bool btListFocus: btPanel.btListFocus

  readonly property var player: {
    const players = Mpris.players.values;
    if (players.length === 0)
      return null;
    for (let i = 0; i < players.length; i++)
      if (players[i].isPlaying)
        return players[i];
    return players[0];
  }

  readonly property var btAdapter: Bluetooth.defaultAdapter

  function scrollToSection() {
    const s = ShellState.centerSection;
    if (s === "" || !mainView)
      return;
    const map = {
      system: sysCard, display: dispCard, power: powCard,
      audio: audioCard, calendar: calCard
    };
    const card = map[s];
    if (!card || sectionCol.height === 0)
      return;
    const maxY = Math.max(0, sectionCol.height - flick.height);
    cc.animateTo(Math.max(0, Math.min(maxY, card.y - 8)));
  }

  Timer {
    id: scrollRetry
    interval: 80
    onTriggered: cc.scrollToSection()
  }

  // animated programmatic scroll (longer, calmer than a flick)
  NumberAnimation {
    id: scrollAnim
    target: flick
    property: "contentY"
    duration: Theme.scrollDuration
    easing.type: Easing.OutQuint
  }

  function animateTo(y) {
    scrollAnim.stop();
    scrollAnim.from = flick.contentY;
    scrollAnim.to = y;
    scrollAnim.restart();
  }

  Connections {
    target: ShellState
    function onCenterSectionChanged() {
      cc.scrollToSection();
      scrollRetry.restart();
    }
  }

  // (QuickToggle lives in ../components now)

  // (BarSlider lives in ../components now)

  // (SectionCard lives in ../components now)

  // (StatRow lives in ../components now)

  // dim scrim, click outside to close
  Rectangle {
    id: backdrop
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, Theme.scrimOpacity * (ShellState.centerOpen ? 1 : 0))

    Behavior on color {
      ColorAnimation { duration: Theme.popupDuration; easing.type: Easing.OutCubic }
    }

    MouseArea {
      anchors.fill: parent
      onClicked: ShellState.centerOpen = false
    }
  }

  Rectangle {
    id: ccCard
    anchors.top: parent.top
    anchors.topMargin: Theme.barMarginTop + Theme.barHeight + 8
    anchors.horizontalCenter: parent.horizontalCenter
    width: Math.min(620, parent.width - 80)
    height: cc.wifiView || cc.btView ? 540 : 660
    color: Theme.bgSolid
    border.color: Theme.border
    border.width: 1
    radius: Theme.radius

    Behavior on height {
      NumberAnimation { duration: Theme.viewDuration; easing.type: Easing.OutCubic }
    }

    // slight scale-up on open (GPU transform only, layout untouched)
    scale: ShellState.centerOpen ? 1 : 0.985

    Behavior on scale {
      NumberAnimation { duration: Theme.popupDuration; easing.type: Easing.OutQuint }
    }

    transform: Translate {
      y: ShellState.centerOpen ? 0 : -110

      Behavior on y {
        NumberAnimation { duration: Theme.popupDuration; easing.type: Easing.OutQuint }
      }
    }

    opacity: ShellState.centerOpen ? 1 : 0

    Behavior on opacity {
      NumberAnimation { duration: Theme.popupDuration * 0.7 }
    }

    MouseArea {
      anchors.fill: parent
    }

    FocusScope {
      id: rootScope
      anchors.fill: parent
      anchors.margins: 18
      focus: cc.visible

      Keys.onEscapePressed: ShellState.centerBack()

      // ---------------------------------------------------------------
      // Header
      // ---------------------------------------------------------------
      Item {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 26

        Text {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          text: cc.mainView ? "Control Center" : cc.wifiView ? "Wi-Fi" : "Bluetooth"
          color: Theme.bright
          font.family: Theme.fontFamily
          font.pixelSize: 15
        }

        Rectangle {
          visible: !cc.mainView
          anchors.right: closeButton.left
          anchors.rightMargin: 8
          anchors.verticalCenter: parent.verticalCenter
          width: 28
          height: 28
          radius: Theme.radius
          color: backHover.hovered ? Theme.hover : "transparent"
          border.color: Theme.border
          border.width: 1

          Behavior on color {
            ColorAnimation { duration: Theme.hoverDuration; easing.type: Easing.OutCubic }
          }

          Text {
            anchors.centerIn: parent
            text: "\u2039"
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 14
          }

          HoverHandler {
            id: backHover
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: ShellState.centerBack()
          }
        }

        Rectangle {
          id: closeButton
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          width: 28
          height: 28
          radius: Theme.radius
          color: closeHover.hovered ? Theme.hover : "transparent"
          border.color: Theme.border
          border.width: 1

          Behavior on color {
            ColorAnimation { duration: Theme.hoverDuration; easing.type: Easing.OutCubic }
          }

          Text {
            anchors.centerIn: parent
            text: Icons.close
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 13
          }

          HoverHandler {
            id: closeHover
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: ShellState.centerOpen = false
          }
        }
      }

      // ---------------------------------------------------------------
      // Wi-Fi / Bluetooth views
      // ---------------------------------------------------------------
      // Wi-Fi / Bluetooth views (cross-faded via opacity)
      WifiPanel {
        id: wifiPanel
        anchors.top: header.bottom
        anchors.topMargin: 12
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: opacity > 0
        enabled: cc.wifiView
        opacity: cc.wifiView ? 1 : 0
        onRequestBack: ShellState.centerBack()

        Behavior on opacity {
          NumberAnimation { duration: Theme.viewDuration; easing.type: Easing.OutCubic }
        }
      }

      BluetoothPanel {
        id: btPanel
        anchors.top: header.bottom
        anchors.topMargin: 12
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: opacity > 0
        enabled: cc.btView
        opacity: cc.btView ? 1 : 0
        onRequestBack: ShellState.centerBack()

        Behavior on opacity {
          NumberAnimation { duration: Theme.viewDuration; easing.type: Easing.OutCubic }
        }
      }

      // ---------------------------------------------------------------
      // Main view
      // ---------------------------------------------------------------
      Item {
        id: mainView
        visible: opacity > 0
        enabled: cc.mainView
        opacity: cc.mainView ? 1 : 0
        anchors.top: header.bottom
        anchors.topMargin: 12
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        Behavior on opacity {
          NumberAnimation { duration: Theme.viewDuration; easing.type: Easing.OutCubic }
        }

        onVisibleChanged: {
          if (visible)
            cc.scrollToSection();
        }

        // quick toggles
        Row {
          id: toggles
          width: parent.width
          spacing: 8

          QuickToggle {
            icon: Icons.wifi
            label: "Wi-Fi"
            cardWidth: ccCard.width
            on: Networking.wifiEnabled
            tint: Theme.accent
            onActivated: ShellState.openCenterView("wifi")
          }

          QuickToggle {
            icon: Icons.bluetooth
            label: "Bluetooth"
            cardWidth: ccCard.width
            on: cc.btAdapter ? cc.btAdapter.enabled : false
            tint: Theme.accentSoft
            onActivated: ShellState.openCenterView("bluetooth")
          }

          QuickToggle {
            icon: ShellState.dnd ? Icons.bellSlash : Icons.bell
            label: "DND"
            cardWidth: ccCard.width
            on: ShellState.dnd
            tint: Theme.critical
            onActivated: ShellState.dnd = !ShellState.dnd
          }

          QuickToggle {
            icon: Icons.moon
            label: "Night"
            cardWidth: ccCard.width
            on: Sys.nightLight
            tint: Theme.accentSoft
            onActivated: Theme.toggleNightLight()
          }
        }

        // scrollable sections
        Flickable {
          id: flick
          anchors.top: toggles.bottom
          anchors.topMargin: 12
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          clip: true
          contentWidth: width
          contentHeight: sectionCol.height
          boundsBehavior: Flickable.StopAtBounds
          // calmer, longer glide (Qt's default deceleration is a hard stop)
          flickDeceleration: 900
          maximumFlickVelocity: 3200

          Column {
            id: sectionCol
            width: flick.width
            spacing: 10

            SectionCard {
              id: sysCard
              contentWidth: flick.width
              sectionId: "system"
              title: "System"

              StatRow {
                label: "CPU"
                value: Sys.cpu + "%"
                fraction: Sys.cpu / 100
              }

              StatRow {
                label: "Memory"
                value: Sys.memUsed.toFixed(1) + " / " + Sys.memTotal.toFixed(1) + " GiB"
                fraction: Sys.memPct / 100
              }

              StatRow {
                label: "Temperature"
                value: Math.round(Sys.temp) + "°C"
                fraction: Sys.temp / 100
              }
            }

            SectionCard {
              id: dispCard
              contentWidth: flick.width
              sectionId: "display"
              title: "Display"

              Item {
                width: parent.width
                height: 22

                Text {
                  anchors.left: parent.left
                  anchors.verticalCenter: parent.verticalCenter
                  text: "Brightness"
                  color: Theme.muted
                  font.family: Theme.fontFamily
                  font.pixelSize: 11
                }

                Text {
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  text: Sys.brightness + "%"
                  color: Theme.fg
                  font.family: Theme.fontFamily
                  font.pixelSize: 11
                }
              }

              BarSlider {
                width: parent.width
                value: Sys.brightness / 100
                onMoved: (v) => Sys.setBrightness(v * 100)
              }

              Item {
                width: parent.width
                height: 20

                Text {
                  anchors.left: parent.left
                  anchors.verticalCenter: parent.verticalCenter
                  text: Icons.moon + "  Night light"
                  color: Sys.nightLight ? Theme.accent : Theme.fg
                  font.family: Theme.fontFamily
                  font.pixelSize: 11
                }

                Text {
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  text: Sys.nightLight ? "On" : "Off"
                  color: Sys.nightLight ? Theme.accent : Theme.muted
                  font.family: Theme.fontFamily
                  font.pixelSize: 11
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: Theme.toggleNightLight()
                }
              }
            }

            SectionCard {
              id: powCard
              contentWidth: flick.width
              sectionId: "power"
              title: "Power"

              Item {
                visible: Sys.hasBattery
                width: parent.width
                height: 22

                Text {
                  anchors.left: parent.left
                  anchors.verticalCenter: parent.verticalCenter
                  text: {
                    const level = Math.max(0, Math.min(10, Math.floor(Sys.batteryPct / 10)));
                    return (Sys.batteryCharging ? Icons.battCharging : Icons.battery[level]) + "  Battery";
                  }
                  color: Theme.fg
                  font.family: Theme.fontFamily
                  font.pixelSize: 11
                }

                Text {
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  text: Sys.batteryPct + "% · " + Sys.batteryTimeText()
                  color: Theme.muted
                  font.family: Theme.fontFamily
                  font.pixelSize: 11
                }
              }

              Item {
                width: parent.width
                height: 30

                Text {
                  anchors.left: parent.left
                  anchors.verticalCenter: parent.verticalCenter
                  text: "Profile"
                  color: Theme.muted
                  font.family: Theme.fontFamily
                  font.pixelSize: 11
                }

                Row {
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: 6

                  Repeater {
                    model: [
                      { id: "performance", label: "Performance" },
                      { id: "balanced", label: "Balanced" },
                      { id: "power-saver", label: "Saver" }
                    ]

                    delegate: Rectangle {
                      required property var modelData

                      readonly property bool current: Sys.powerProfile === modelData.id

                      width: profileLabel.implicitWidth + 18
                      height: 24
                      radius: Theme.radius
                      color: current ? Theme.hover : "transparent"
                      border.color: activeFocus ? Theme.bright : current ? Theme.accent : Theme.border
                      border.width: 1
                      activeFocusOnTab: true

                      Keys.onSpacePressed: Sys.setPowerProfile(modelData.id)
                      Keys.onReturnPressed: Sys.setPowerProfile(modelData.id)
                      Keys.onEnterPressed: Sys.setPowerProfile(modelData.id)

                      Text {
                        id: profileLabel
                        anchors.centerIn: parent
                        text: modelData.label
                        color: current ? Theme.accent : Theme.muted
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                      }

                      MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Sys.setPowerProfile(modelData.id)
                      }
                    }
                  }
                }
              }
            }

            SectionCard {
              id: audioCard
              contentWidth: flick.width
              sectionId: "audio"
              title: "Sound"

              Item {
                width: parent.width
                height: 22

                Text {
                  anchors.left: parent.left
                  anchors.verticalCenter: parent.verticalCenter
                  text: "Volume · " + Sys.sinkName
                  color: Theme.muted
                  font.family: Theme.fontFamily
                  font.pixelSize: 11
                  elide: Text.ElideRight
                  width: parent.width - 60
                }

                Text {
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  text: Sys.muted ? "Muted" : Math.round(Sys.volume * 100) + "%"
                  color: Sys.muted ? Theme.muted : Theme.fg
                  font.family: Theme.fontFamily
                  font.pixelSize: 11

                  MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Sys.toggleMute()
                  }
                }
              }

              BarSlider {
                width: parent.width
                value: Sys.volume
                onMoved: (v) => Sys.setVolume(v)
              }

              Item {
                width: parent.width
                height: 20

                Text {
                  anchors.left: parent.left
                  anchors.verticalCenter: parent.verticalCenter
                  text: (Sys.sourceMuted ? Icons.micOff : Icons.mic) + "  Microphone"
                  color: Sys.sourceMuted ? Theme.critical : Theme.fg
                  font.family: Theme.fontFamily
                  font.pixelSize: 11
                }

                Text {
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  text: Sys.sourceMuted ? "Muted" : "On"
                  color: Sys.sourceMuted ? Theme.critical : Theme.muted
                  font.family: Theme.fontFamily
                  font.pixelSize: 11
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: Sys.toggleSourceMute()
                }
              }
            }

            SectionCard {
              id: calCard
              contentWidth: flick.width
              sectionId: "calendar"
              title: "Calendar"

              Calendar {
                id: calendar
                anchors.horizontalCenter: parent.horizontalCenter
                activeFocusOnTab: true
              }
            }

            Item {
              id: mediaSection
              width: flick.width
              height: visible ? mediaBox.height : 0
              visible: cc.player !== null

              Rectangle {
                id: mediaBox
                width: parent.width
                height: 108
                color: Theme.bg
                border.color: Theme.border
                border.width: 1
                radius: Theme.radius

                Column {
                  anchors.fill: parent
                  anchors.margins: 12
                  spacing: 6

                  Text {
                    width: parent.width
                    text: cc.player ? (cc.player.trackTitle || "Unknown Title") : ""
                    color: Theme.bright
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    elide: Text.ElideRight
                  }

                  Text {
                    width: parent.width
                    text: cc.player
                      ? ((cc.player.trackArtist || "Unknown Artist") + " - " + (cc.player.identity || ""))
                      : ""
                    color: Theme.muted
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    elide: Text.ElideRight
                  }

                  Item {
                    width: parent.width
                    height: 14

                    Rectangle {
                      anchors.verticalCenter: parent.verticalCenter
                      width: parent.width
                      height: 4
                      radius: 2
                      color: Theme.hover

                      Rectangle {
                        width: {
                          const p = cc.player;
                          if (!p || !p.length || isNaN(p.length) || p.length <= 0)
                            return 0;
                          return parent.width * Math.max(0, Math.min(1, p.position / p.length));
                        }
                        height: parent.height
                        radius: parent.radius
                        color: Theme.accent
                      }
                    }
                  }

                  Row {
                    spacing: 14
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                      text: Icons.prev
                      color: prevHover.hovered ? Theme.bright : Theme.fg
                      font.family: Theme.fontFamily
                      font.pixelSize: 14

                      HoverHandler {
                        id: prevHover
                      }

                      MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                          if (cc.player && cc.player.canGoPrevious)
                            cc.player.previous();
                        }
                      }
                    }

                    Text {
                      text: cc.player && cc.player.isPlaying ? Icons.pause : Icons.play
                      color: Theme.bright
                      font.family: Theme.fontFamily
                      font.pixelSize: 16

                      MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                          if (cc.player && cc.player.canTogglePlaying)
                            cc.player.togglePlaying();
                        }
                      }
                    }

                    Text {
                      text: Icons.next
                      color: nextHover.hovered ? Theme.bright : Theme.fg
                      font.family: Theme.fontFamily
                      font.pixelSize: 14

                      HoverHandler {
                        id: nextHover
                      }

                      MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                          if (cc.player && cc.player.canGoNext)
                            cc.player.next();
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }

        // ---------------------------------------------------------------
        // (notification history intentionally omitted — popups are transient)
        // ---------------------------------------------------------------
      }
    }
  }
}
