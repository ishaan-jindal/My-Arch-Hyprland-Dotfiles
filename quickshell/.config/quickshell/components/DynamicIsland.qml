import QtQuick
import Quickshell
import Quickshell.Networking
import ".."

// The Dynamic Island pill: glass notch stuck to the top edge (flush
// y=0, square top corners, rounded bottom — an attached tab), and the
// single host for every popup pane: controls, launcher, picker,
// session, keys, osd (NotificationPopups stays a top-right stack).
// Rest is 320x36 radius 18 (8px grid: 9px dots + 15px clock + 15px
// signal/battery icons, 14px inner pad, 12px sides); hover peeks to a 400x132 live-stats
// strip radius 24 (2x2 Sys grid), while shortcuts expand the SAME pill downward to host
// full panes inline (content margin 12): controls 504x320,
// launcher 504x400, session 504x300, keys 504x440, osd 504x160,
// picker cinematic grid 848x460, calendar 504x328.
// Panes reuse extracted bodies (QuickToggle / BarSlider / WifiPanel /
// BluetoothPanel / LauncherBody / WallpaperBody / SessionBody /
// CheatsheetBody / OsdBody) — the retired overlay windows never show.
// Geometry binds settled targets (mask/window resize on state changes
// only, never per-frame — except the mask, which tracks the animated
// shrink on close so it lands on 320x36 with the glass.
// Faces sequence 240ms after the morph starts on open (140ms fade);
// on close it's sequential: strip/pane out immediately at full size
// (90ms, no spill, no clip), then rest fades in as the 220ms shrink
// starts (unmount past 0.01). Mask/shadow hold settled sizes; the mask
// swaps only after the morph settles. Hover changes are ignored
// mid-collapse (settle re-peeks if the pointer is still inside). One
// morphT clock drives width/height/radius together (OutQuint 380 open /
// 220 close); icon scales freeze while collapsed.
Item {
  id: island

  property var barScreen
  property alias pillHit: hitBox

  // Focus trapdoor: with Exclusive window focus while a pane is open,
  // Esc steps a wifi/bt sub-view back to main, else collapses the pill
  // (focused inputs handle Esc themselves first).
  focus: ShellState.islandMode !== ""
  Keys.onEscapePressed: {
    if (ShellState.centerView !== "main")
      ShellState.centerBack();
    else
      ShellState.closeAllPopups();
  }

  readonly property int restW: 320
  readonly property int restH: 36
  readonly property int peekW: 400
  readonly property int peekH: 132
  readonly property int paneW: 504 // grid-snapped 500
  readonly property int pickerW: 848 // cinematic wallpaper grid, 8px grid
  readonly property int controlsH: 320
  readonly property int launcherH: 400
  readonly property int pickerH: 460
  readonly property int sessionH: 300
  readonly property int keysH: 440
  readonly property int osdH: 160
  readonly property int calendarH: 328 // month grid + hint, 8px grid

  readonly property string mode: ShellState.islandMode // "" | "controls" | "launcher" | "picker" | "session" | "keys" | "osd" | "calendar"

  // Hybrid triggers: hover peeks (delayed both ways), click latches,
  // pill mode holds. Geometry reads the settled targets below; faces
  // read the sequenced flags (never the raw trigger, so content never
  // races the morph).
  property bool pointerInside: false
  property bool hoverPeek: false
  property bool latched: false
  readonly property bool expanded: hoverPeek || latched || mode !== ""

  // Settled geometry: integer targets the pill animates toward. Mask
  // and pane layout bind here — never to the per-frame animated size
  // (mask excepted on close, see hitBox) — so nothing resizes every
  // frame during a morph. Widths are integers; 500 is nominal, 4px off
  // the 8px grid, visually identical.
  readonly property int targetW: mode === "picker" ? pickerW : mode !== "" ? paneW : expanded ? peekW : restW
  readonly property int targetH: mode === "controls" ? controlsH
    : mode === "launcher" ? launcherH
    : mode === "picker" ? pickerH
    : mode === "session" ? sessionH
    : mode === "keys" ? keysH
    : mode === "osd" ? osdH
    : mode === "calendar" ? calendarH
    : expanded ? peekH : restH

  // Sequenced faces: on open, outgoing hides now and incoming waits
  // ~240ms so text never renders tiny; on close everything flips
  // immediately (90ms, no delay) and unmounts after the fade
  // (visible past 0.01, never during).
  property bool restShown: true
  property bool stripShown: false
  property bool paneShown: false

  Timer {
    id: faceSync
    interval: 240
    onTriggered: {
      if (!island.expanded) {
        island.restShown = true;
        island.stripShown = false;
        island.paneShown = false;
        return;
      }
      island.restShown = false;
      island.stripShown = true;
      island.paneShown = island.mode !== "";
    }
  }

  function kickFaces() {
    faceSync.stop();
    if (!island.expanded) {
      // Collapse, phase 1: strip/pane out NOW while the pill is still
      // full-size (90ms, no spill, no clip needed). Rest + geometry
      // follow via closeGeom once they're fully gone.
      stripShown = false;
      paneShown = false;
      closeGeom.restart();
      return;
    }
    restShown = false;
    faceSync.interval = 240;
    faceSync.restart();
  }

  // Collapse, phase 2: rest fades in as the 220ms shrink starts.
  Timer {
    id: closeGeom
    interval: 90
    onTriggered: {
      island.restShown = true;
      kickMorph();
    }
  }

  // Click-outside dismiss (called by the bar's dismiss layer): clears
  // popups, drops the latch AND the hover peek, and parks the hover
  // timers so nothing re-arms mid-collapse.
  function dismiss() {
    openDelay.stop();
    closeDelay.stop();
    hoverPeek = false;
    latched = false;
    ShellState.closeAllPopups();
  }

  onExpandedChanged: {
    closeGeom.stop();
    if (island.expanded) {
      kickMorph();
      kickFaces();
    } else {
      // Geometry waits for closeGeom; faces hide immediately above.
      kickFaces();
    }
  }
  onModeChanged: {
    closeGeom.stop();
    // Collapse owns its sequence via onExpandedChanged + closeGeom:
    // bail on empty mode (or while collapsed) so geometry never starts
    // before the content fade. Open-path double-fire with
    // onExpandedChanged is same-tick/same-values and harmless.
    if (mode === "" || !island.expanded)
      return;
    kickMorph();
    kickFaces();
    if ((mode === "controls" && ShellState.centerView === "main") || mode === "calendar")
      controlsFocus.restart();
  }

  // Single morph driver: pill width/height and bg radius ALL derive from
  // morphT, so the whole body morphs on one clock with one easing —
  // no racing Behaviors. kickMorph snapshots the rendered start (clean
  // mid-flight redirects) and re-runs 0→1 toward the settled targets.
  // Width targets sit on the 8px grid (320/400/504); heights round to
  // integers; fonts/scales are never geometry-driven.
  property real morphT: 0
  property real startW: restW
  property real startH: restH
  property real startR: 18
  readonly property bool morphing: morphAnim.running

  // Open/close splits: bloom open slow, dismiss reads instant.
  readonly property int openMs: 380
  readonly property int closeMs: 220

  NumberAnimation {
    id: morphAnim
    target: island
    property: "morphT"
    from: 0
    to: 1
    duration: island.expanded ? island.openMs : island.closeMs
    easing.type: Easing.OutQuint

    onFinished: {
      // Settle re-arm: a pointer that rode out the collapse peeks again.
      if (!island.expanded && island.pointerInside)
        island.hoverPeek = true;
    }
  }

  function kickMorph() {
    startW = pill.width;
    startH = pill.height;
    startR = pillBg.radius;
    morphT = 0;
    morphAnim.restart();
  }

  Timer {
    id: openDelay
    interval: 150
    onTriggered: {
      // No hover re-arm mid-collapse; the morph-end handler below
      // re-peeks if the pointer is still inside at settle.
      if (island.pointerInside && (island.expanded || !morphAnim.running))
        island.hoverPeek = true;
    }
  }

  Timer {
    id: closeDelay
    interval: 150
    onTriggered: {
      if (!island.pointerInside)
        island.hoverPeek = false;
    }
  }

  // Stage fits the widest pill (picker); height holds the taller of
  // rendered vs settled until settle so the window never guillotines
  // fading content mid-close (then rests at targetH+18). Bar window
  // (masked to the pill) hugs every mode. Padding is click-through.
  implicitWidth: pickerW
  implicitHeight: Math.max(pill.height, island.targetH) + 18
  width: implicitWidth
  height: implicitHeight

  // Entry focus: land on the first toggle when the controls main view
  // shows, on the calendar grid in calendar mode (grant is async — one
  // delayed attempt, re-armed on view/mode back).
  Timer {
    id: controlsFocus
    interval: 120
    repeat: false
    onTriggered: {
      if (island.mode === "controls" && ShellState.centerView === "main")
        controlsBody.focusFirst();
      else if (island.mode === "calendar")
        cal.forceActiveFocus();
    }
  }

  Connections {
    target: ShellState
    function onCenterViewChanged() {
      if (island.mode === "controls" && ShellState.centerView === "main")
        controlsFocus.restart();
    }
  }

  // ------------------------------------------------------------------
  // Status derivations (read-only mirrors of Sys / Networking)
  // ------------------------------------------------------------------
  readonly property var activeDevice: {
    const devices = Networking.devices.values;
    for (let i = 0; i < devices.length; i++)
      if (devices[i].connected)
        return devices[i];
    return devices.length > 0 ? devices[0] : null;
  }

  readonly property var activeNetwork: {
    const dev = activeDevice;
    if (!dev || !dev.networks)
      return null;
    const nets = dev.networks.values;
    for (let i = 0; i < nets.length; i++)
      if (nets[i].connected)
        return nets[i];
    return null;
  }

  readonly property bool isWifi: activeDevice && activeDevice.type === DeviceType.Wifi
  readonly property bool connected: activeDevice && activeDevice.connected
  readonly property string wifiGlyph: {
    if (activeNetwork && isWifi)
      return Icons.wifiIcon(activeNetwork.signalStrength);
    if (connected)
      return Icons.eth;
    return Icons.warning;
  }
  readonly property string wifiColor: connected ? islandFg : Theme.critical

  readonly property int battPct: Sys.batteryPct
  readonly property bool charging: Sys.batteryCharging
  readonly property int battLevel: Math.max(0, Math.min(10, Math.floor(battPct / 10)))
  readonly property string battGlyph: charging ? Icons.battCharging : Icons.battery[battLevel]

  readonly property real vol: Sys.volume
  readonly property bool muted: Sys.muted
  readonly property string volGlyph: muted
    ? Icons.audioMuted
    : vol < 0.34 ? Icons.volLow : vol < 0.67 ? Icons.volMid : Icons.volHigh

  // Wallpaper-driven cups (same tokens the popups use): the surface is
  // bgSolid at 0.85 alpha, accents/text follow the palette, and the
  // Theme crossfade flows through these bindings on wallpaper switch.
  // Fallbacks hold if a token is ever missing.
  readonly property color islandBg: Qt.rgba(Theme.bgSolid.r, Theme.bgSolid.g, Theme.bgSolid.b, Theme.bgSolid.a * 0.85)
  readonly property color islandAccent: Theme.accent
  readonly property color islandFg: Theme.fg

  property string timeText: Qt.formatDateTime(new Date(), "HH:mm")
  property string dateText: Qt.formatDateTime(new Date(), "ddd d MMM")

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: {
      island.timeText = Qt.formatDateTime(new Date(), "HH:mm");
      island.dateText = Qt.formatDateTime(new Date(), "ddd d MMM");
    }
  }

  // ------------------------------------------------------------------
  // The pill: notch container flush at y=0. The background below is
  // shifted up by R and clipped square at the top, so only the bottom
  // corners carry the radius — it reads as an attached tab.
  // ------------------------------------------------------------------
  Item {
    id: pill
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    width: Math.round(island.startW + (island.targetW - island.startW) * island.morphT)
    height: Math.round(island.startH + (island.targetH - island.startH) * island.morphT)
    // Scissor while growing or while faces sequence (open + lateral
    // switches); never during shrink — dismiss reads instant. Releases
    // at face settle, not morph end.
    clip: island.expanded && (morphAnim.running || faceSync.running)

    // Notch glass: uniform radius, top R px clipped off by the parent
    // so the top edge sits square on the screen edge (no top border
    // needed there); bottom corners keep the arc + outline.
    Rectangle {
      id: pillBg
      anchors.fill: parent
      anchors.topMargin: -radius
      radius: island.startR + ((island.expanded ? 24 : 18) - island.startR) * island.morphT
      color: island.islandBg
      border.color: Theme.border
      border.width: 1
    }

    HoverHandler {
      id: islandHover
      onHoveredChanged: {
        // Tracked always, acted on never mid-collapse: glass shrinking
        // from under a still cursor must not re-arm the timers.
        island.pointerInside = hovered;
        if (morphAnim.running && !island.expanded)
          return;
        if (hovered)
          openDelay.restart();
        else
          closeDelay.restart();
      }
    }

    WheelHandler {
      onWheel: (event) => wsDots.cycle(event.angleDelta.y > 0 ? -1 : 1)
    }

    // Background gaps latch/unlatch; shortcut MouseAreas above win first.
    MouseArea {
      anchors.fill: parent
      onClicked: island.latched = !island.latched
    }

    // --------------------------------------------------------------
    // Rest content: dots + 12px 24h clock + signal/battery icons
    // Overlaid with the status strip; cross-faded, never remounted.
    // --------------------------------------------------------------
    Item {
      anchors.fill: parent
      opacity: island.restShown ? 1 : 0
      visible: opacity > 0.01

      // Close reads instant (90ms, flipped with no delay); open keeps
      // the 140ms fade behind the 240ms faceSync delay.
      Behavior on opacity {
        NumberAnimation { duration: 90; easing.type: Easing.OutCubic }
      }

      Row {
        // Top-anchored (not centered): during the sequenced close this
        // row fades in while the pill is still tall, then rides down.
        anchors.top: parent.top
        anchors.topMargin: 6
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 14

        IslandWorkspaces {
          id: wsDots
          barScreen: island.barScreen
          dotSize: 9
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: island.timeText
          color: island.islandFg
          font.family: Theme.fontFamily
          font.pixelSize: 15

          MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            cursorShape: Qt.PointingHandCursor
            onClicked: ShellState.toggleCalendar()
          }
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: island.dateText
          color: Theme.muted
          font.family: Theme.fontFamily
          font.pixelSize: 11

          MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            cursorShape: Qt.PointingHandCursor
            onClicked: ShellState.toggleCalendar()
          }
        }

        Text {
          id: restWifi
          anchors.verticalCenter: parent.verticalCenter
          text: island.wifiGlyph
          color: island.wifiColor
          font.family: Theme.fontFamily
          font.pixelSize: 15
          scale: island.expanded && restWifiHover.hovered ? 1.2 : 1

          Behavior on scale {
            enabled: island.expanded
            SpringAnimation { spring: 5.2; damping: 0.34; mass: 0.6 }
          }

          HoverHandler {
            id: restWifiHover
          }

          MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            cursorShape: Qt.PointingHandCursor
            onClicked: ShellState.openCenterView("wifi")
          }
        }

        Text {
          id: restBatt
          anchors.verticalCenter: parent.verticalCenter
          visible: Sys.hasBattery
          text: island.battGlyph
          color: island.islandFg
          font.family: Theme.fontFamily
          font.pixelSize: 15
          scale: island.expanded && restBattHover.hovered ? 1.2 : 1

          Behavior on scale {
            enabled: island.expanded
            SpringAnimation { spring: 5.2; damping: 0.34; mass: 0.6 }
          }

          HoverHandler {
            id: restBattHover
          }

          MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            cursorShape: Qt.PointingHandCursor
            onClicked: ShellState.openCenterSection("power")
          }
        }
      }
    }

    // --------------------------------------------------------------
    // Status strip: full status + shortcuts. Fixed 72px when a pane is
    // hosted below, otherwise fills the peek pill so the row stays
    // centered. Shortcuts expand the SAME pill (toggle to close).
    // Overlaid with the rest face; cross-faded, never remounted.
    // --------------------------------------------------------------
    Item {
      id: topStrip
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.leftMargin: 12
      anchors.rightMargin: 12
      height: island.mode !== "" ? 72 : island.targetH
      opacity: island.stripShown ? 1 : 0
      visible: opacity > 0.01

      // Open: 140ms behind the faceSync delay; close: 90ms, no delay.
      Behavior on opacity {
        NumberAnimation { duration: island.expanded ? 140 : 90; easing.type: Easing.OutCubic }
      }

      Column {
        anchors.centerIn: parent
        spacing: 6

        // Peek clock header: the prominent calendar entry point, only
        // when no pane is hosted (the strip clock hides then to avoid a
        // duplicate). Accent on hover = clickable.
        Item {
          anchors.horizontalCenter: parent.horizontalCenter
          width: peekClockText.implicitWidth + 16
          height: 22
          visible: island.mode === ""

          Text {
            id: peekClockText
            anchors.centerIn: parent
            text: island.timeText + "  ·  " + island.dateText
            color: peekClockHover.hovered ? island.islandAccent : island.islandFg
            font.family: Theme.fontFamily
            font.pixelSize: 15

            Behavior on color {
              ColorAnimation { duration: Theme.hoverDuration; easing.type: Easing.OutCubic }
            }
          }

          HoverHandler {
            id: peekClockHover
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: ShellState.toggleCalendar()
          }
        }

      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 16

        IslandWorkspaces {
          barScreen: island.barScreen
          dotSize: 8
          anchors.verticalCenter: parent.verticalCenter
          scale: island.expanded ? 1.06 : 1

          Behavior on scale {
            enabled: island.expanded
            SpringAnimation { spring: 4.5; damping: 0.4; mass: 0.9 }
          }
        }

        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          width: 1
          height: 24
          color: Theme.border
        }

        Column {
          anchors.verticalCenter: parent.verticalCenter
          spacing: 1
          // Hidden while peeking — the header clock above owns calendar.
          visible: island.mode !== ""

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: island.timeText
            color: island.islandFg
            font.family: Theme.fontFamily
            font.pixelSize: 14
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: island.dateText
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: 10
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: ShellState.toggleCalendar()
          }
        }

        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          width: 1
          height: 24
          color: Theme.border
        }

        // Wi-Fi -> controls pane, wifi view (toggle to close)
        Text {
          id: openWifi
          anchors.verticalCenter: parent.verticalCenter
          text: island.wifiGlyph
          color: island.mode === "controls" && ShellState.centerView === "wifi" ? island.islandAccent : island.wifiColor
          font.family: Theme.fontFamily
          font.pixelSize: 16
          scale: island.expanded && openWifiHover.hovered ? 1.2 : 1

          Behavior on scale {
            enabled: island.expanded
            SpringAnimation { spring: 5.2; damping: 0.34; mass: 0.6 }
          }

          HoverHandler {
            id: openWifiHover
          }

          MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            cursorShape: Qt.PointingHandCursor
            onClicked: ShellState.openCenterView("wifi")
          }
        }

        // Volume -> controls pane, audio section (toggle to close)
        Text {
          id: openVol
          anchors.verticalCenter: parent.verticalCenter
          text: island.volGlyph + " " + Math.round(island.vol * 100)
          color: island.mode === "controls" && ShellState.centerView === "main" && ShellState.centerSection === "audio"
            ? island.islandAccent : island.muted ? Theme.muted : island.islandFg
          font.family: Theme.fontFamily
          font.pixelSize: 13
          scale: island.expanded && openVolHover.hovered ? 1.1 : 1

          Behavior on scale {
            enabled: island.expanded
            SpringAnimation { spring: 5.2; damping: 0.34; mass: 0.6 }
          }

          HoverHandler {
            id: openVolHover
          }

          MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            cursorShape: Qt.PointingHandCursor
            onClicked: ShellState.openCenterSection("audio")
          }
        }

        // Battery -> controls pane, power section (toggle to close)
        Text {
          id: openBatt
          anchors.verticalCenter: parent.verticalCenter
          visible: Sys.hasBattery
          text: island.battGlyph + " " + island.battPct
          color: island.mode === "controls" && ShellState.centerView === "main" && ShellState.centerSection === "power"
            ? island.islandAccent : island.islandFg
          font.family: Theme.fontFamily
          font.pixelSize: 13
          scale: island.expanded && openBattHover.hovered ? 1.1 : 1

          Behavior on scale {
            enabled: island.expanded
            SpringAnimation { spring: 5.2; damping: 0.34; mass: 0.6 }
          }

          HoverHandler {
            id: openBattHover
          }

          MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            cursorShape: Qt.PointingHandCursor
            onClicked: ShellState.openCenterSection("power")
          }
        }

        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          width: 1
          height: 24
          color: Theme.border
        }

        // Launcher pane shortcut (toggle to close); power opens session pane
        Text {
          id: appsBtn
          anchors.verticalCenter: parent.verticalCenter
          text: Icons.apps
          color: island.mode === "launcher" ? island.islandAccent : appsHover.hovered ? Theme.bright : Theme.muted
          font.family: Theme.fontFamily
          font.pixelSize: 15
          scale: island.expanded && appsHover.hovered ? 1.2 : 1

          Behavior on scale {
            enabled: island.expanded
            SpringAnimation { spring: 5.2; damping: 0.34; mass: 0.6 }
          }

          HoverHandler {
            id: appsHover
          }

          MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            cursorShape: Qt.PointingHandCursor
            onClicked: ShellState.toggleLauncher("")
          }
        }

        Text {
          id: powerBtn
          anchors.verticalCenter: parent.verticalCenter
          text: Icons.power
          color: island.mode === "session" ? island.islandAccent : powerHover.hovered ? Theme.bright : Theme.muted
          font.family: Theme.fontFamily
          font.pixelSize: 15
          scale: island.expanded && powerHover.hovered ? 1.2 : 1

          Behavior on scale {
            enabled: island.expanded
            SpringAnimation { spring: 5.2; damping: 0.34; mass: 0.6 }
          }

          HoverHandler {
            id: powerHover
          }

          MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            cursorShape: Qt.PointingHandCursor
            onClicked: ShellState.toggleSession()
          }
        }
      }

        // Peek extra: live system stats for the 400x132 hover face —
        // 2x2 grid straight from Sys. Hidden once a pane takes the pill.
        Item {
          anchors.horizontalCenter: parent.horizontalCenter
          width: 340
          height: 60
          visible: island.mode === ""

          Grid {
            anchors.centerIn: parent
            columns: 2
            columnSpacing: 10
            rowSpacing: 4

            Repeater {
              model: [
                { label: "CPU", value: Math.round(Sys.cpu) + "%" },
                { label: "RAM", value: Sys.memUsed.toFixed(1) + " / " + Sys.memTotal.toFixed(1) + "G" },
                { label: "TEMP", value: Math.round(Sys.temp) + "°C" },
                { label: Sys.hasBattery ? "BATT" : "VOL",
                  value: Sys.hasBattery ? island.battPct + "%" : Math.round(island.vol * 100) + "%" }
              ]

              delegate: Item {
                required property var modelData
                width: 165
                height: 28

                Text {
                  anchors.top: parent.top
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: modelData.label
                  color: Theme.muted
                  font.family: Theme.fontFamily
                  font.pixelSize: 9
                }

                Text {
                  anchors.bottom: parent.bottom
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: modelData.value
                  color: island.islandFg
                  font.family: Theme.fontFamily
                  font.pixelSize: 12
                }
              }
            }
          }
        }
      }
    }

    // --------------------------------------------------------------
    // Pane area: full panes hosted inline below the 72px strip.
    // --------------------------------------------------------------
    Item {
      id: paneArea
      anchors.top: parent.top
      anchors.topMargin: 72
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      anchors.leftMargin: 12
      anchors.rightMargin: 12
      anchors.bottomMargin: 12
      opacity: island.paneShown ? 1 : 0
      visible: opacity > 0.01

      Behavior on opacity {
        NumberAnimation { duration: island.expanded ? 140 : 90; easing.type: Easing.OutCubic }
      }

      // ---------- Controls pane (extracted body, same toggles/sliders
      // + embedded wifi/bt panels) ----------
      Item {
        id: controlsPane
        anchors.fill: parent
        opacity: island.mode === "controls" ? 1 : 0
        visible: opacity > 0.01

        Behavior on opacity {
          NumberAnimation { duration: island.expanded ? 140 : 90; easing.type: Easing.OutCubic }
        }

        ControlsBody {
          id: controlsBody
          anchors.fill: parent
          battGlyph: island.battGlyph
          battPct: island.battPct
        }
      }

      // ---------- Launcher pane: the same body as the overlay window ----
      Item {
        id: launcherPane
        anchors.fill: parent
        opacity: island.mode === "launcher" ? 1 : 0
        visible: opacity > 0.01

        Behavior on opacity {
          NumberAnimation { duration: island.expanded ? 140 : 90; easing.type: Easing.OutCubic }
        }

        LauncherBody {
          anchors.fill: parent
          active: island.mode === "launcher" && island.expanded
        }
      }

      // ---------- Picker pane: wallpaper search + grid ------------------
      Item {
        anchors.fill: parent
        opacity: island.mode === "picker" ? 1 : 0
        visible: opacity > 0.01

        Behavior on opacity {
          NumberAnimation { duration: island.expanded ? 140 : 90; easing.type: Easing.OutCubic }
        }

        WallpaperBody {
          anchors.fill: parent
          active: island.mode === "picker" && island.expanded
        }
      }

      // ---------- Session pane: compact power grid ----------------------
      Item {
        anchors.fill: parent
        opacity: island.mode === "session" ? 1 : 0
        visible: opacity > 0.01

        Behavior on opacity {
          NumberAnimation { duration: island.expanded ? 140 : 90; easing.type: Easing.OutCubic }
        }

        SessionBody {
          anchors.fill: parent
          active: island.mode === "session" && island.expanded
        }
      }

      // ---------- Cheatsheet pane: scrollable keybind columns -----------
      Item {
        anchors.fill: parent
        opacity: island.mode === "keys" ? 1 : 0
        visible: opacity > 0.01

        Behavior on opacity {
          NumberAnimation { duration: island.expanded ? 140 : 90; easing.type: Easing.OutCubic }
        }

        CheatsheetBody {
          anchors.fill: parent
        }
      }

      // ---------- OSD pane: transient level readout ---------------------
      Item {
        anchors.fill: parent
        opacity: island.mode === "osd" ? 1 : 0
        visible: opacity > 0.01

        Behavior on opacity {
          NumberAnimation { duration: island.expanded ? 140 : 90; easing.type: Easing.OutCubic }
        }

        OsdBody {
          anchors.fill: parent
        }
      }

      // ---------- Calendar pane: month grid, today in accent -----------
      Item {
        anchors.fill: parent
        opacity: island.mode === "calendar" ? 1 : 0
        visible: opacity > 0.01

        Behavior on opacity {
          NumberAnimation { duration: island.expanded ? 140 : 90; easing.type: Easing.OutCubic }
        }

        Calendar {
          id: cal
          anchors.top: parent.top
          anchors.horizontalCenter: parent.horizontalCenter
          onPicked: island.dismiss()
        }

        Text {
          anchors.top: cal.bottom
          anchors.topMargin: 8
          anchors.horizontalCenter: parent.horizontalCenter
          text: Qt.formatDateTime(new Date(), "dddd, d MMMM") + "  ·  arrows move · Home today · Esc close"
          color: Theme.muted
          font.family: Theme.fontFamily
          font.pixelSize: 10
        }
      }
    }
  }

  // Mask target: exact pill geometry (the Region is rectangular anyway,
  // so no halo is needed — the pill rect already covers the arcs).
  // Settled size, frozen across morphs; Bar swaps between this and the
  // dismiss layer on settle (see Bar.qml).
  Item {
    id: hitBox
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    width: island.targetW
    height: island.targetH
  }
}
