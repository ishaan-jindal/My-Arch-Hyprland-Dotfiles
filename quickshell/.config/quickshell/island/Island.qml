import QtQuick
import QtQuick.Effects
import Quickshell
import ".."
import "../components" as C

// The Dynamic Island pill: one centered pill per monitor, fixed window,
// morphing content. Faces crossfade (out 90ms / in 160ms + 120ms delay);
// the pill resizes on a spring, height lagging 30ms; radius eases 300ms
// OutCubic. Everything snaps when IslandState.reduceMotion is set.
// Existing panes (controls/launcher/picker/session/keys/calendar) are
// hosted here with their settled sizes — the window grows past the fixed
// island envelope only for those.
Item {
  id: island

  property var barScreen
  property alias pillItem: pill

  readonly property bool rm: IslandState.reduceMotion
  readonly property string display: IslandState.display
  readonly property string face: display.indexOf("demo:") === 0 ? display.substring(5) : display
  readonly property string legacyMode: IslandState.legacyMode
  readonly property var notif: IslandState.notifToShow

  // Crossfade helper: opacity is BOUND to shown (never animated
  // imperatively), so a face can never freeze mid-fade and leak an
  // invisible-but-clickable layer. The Behavior only shapes the
  // transition; visibility drops the moment the fade completes.
  component Face: Item {
    id: faceRoot
    property bool shown: false
    opacity: shown ? 1 : 0
    visible: shown || opacity > 0.01
    Behavior on opacity {
      enabled: !IslandState.reduceMotion
      NumberAnimation {
        duration: faceRoot.shown ? IslandTheme.fadeInMs : IslandTheme.fadeOutMs
        easing.type: Easing.OutCubic
      }
    }
  }

  // Hub toggle: 42px circle + 12px label (QuickToggle's 9px label
  // grazes at this size; the shared component itself is untouched).
  component HubToggle: Column {
    id: toggleRoot
    required property string icon
    required property string caption
    required property bool isOn
    required property color tint
    signal activated()

    spacing: 4

    Rectangle {
      id: circle
      width: 42
      height: 42
      radius: 21
      anchors.horizontalCenter: parent.horizontalCenter
      color: toggleRoot.isOn
        ? Qt.rgba(toggleRoot.tint.r, toggleRoot.tint.g, toggleRoot.tint.b, 0.22) : "transparent"
      border.color: circle.activeFocus ? Theme.bright
        : toggleRoot.isOn ? toggleRoot.tint : Qt.rgba(1, 1, 1, 0.12)
      border.width: 1
      activeFocusOnTab: true

      Text {
        anchors.centerIn: parent
        text: toggleRoot.icon
        color: toggleRoot.isOn ? toggleRoot.tint : Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: 18
      }

      Keys.onSpacePressed: toggleRoot.activated()
      Keys.onReturnPressed: toggleRoot.activated()

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          circle.forceActiveFocus();
          toggleRoot.activated();
        }
      }
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: toggleRoot.caption
      color: toggleRoot.isOn ? toggleRoot.tint : IslandTheme.textSecondary
      font.family: IslandTheme.fontFamily
      font.pixelSize: 12
    }
  }

  // ---- geometry -------------------------------------------------
  function legacyContentW() {
    return island.legacyMode === "picker" ? 848 : 504;
  }
  function legacyContentH() {
    switch (island.legacyMode) {
    case "controls":
      return 320;
    case "launcher":
      return 400;
    case "picker":
      return 460;
    case "session":
      return 300;
    case "keys":
      return 440;
    case "calendar":
      return 328;
    default:
      return 320;
    }
  }
  function legacyTitle() {
    switch (island.legacyMode) {
    case "controls":
      return "Controls";
    case "launcher":
      return "Launcher";
    case "picker":
      return "Wallpapers";
    case "session":
      return "Session";
    case "keys":
      return "Shortcuts";
    case "calendar":
      return "Calendar";
    default:
      return "";
    }
  }

  readonly property int baseW: island.face === "idle" ? IslandTheme.idleW
    : island.face === "activity" ? IslandTheme.actW
    : island.face === "toast" ? IslandTheme.toastW
    : island.face === "notification" ? IslandTheme.notifW
    : island.face === "media" ? IslandTheme.mediaW
    : island.face === "hub" ? IslandTheme.hubW
    : island.face === "legacy" ? island.legacyContentW() : IslandTheme.idleW

  readonly property int baseH: island.face === "idle" ? IslandTheme.idleH
    : island.face === "activity" ? IslandTheme.actH
    : island.face === "toast" ? IslandTheme.toastH
    : island.face === "notification" ? IslandTheme.notifH
    : island.face === "media" ? IslandTheme.mediaH
    : island.face === "hub" ? IslandTheme.hubH
    : island.face === "legacy"
      ? IslandTheme.legacyHeaderH + island.legacyContentH() + IslandTheme.legacyMargin * 2
      : IslandTheme.idleH

  readonly property real baseR: island.face === "idle" ? IslandTheme.idleR
    : island.face === "activity" ? IslandTheme.actR
    : island.face === "toast" ? IslandTheme.toastR
    : island.face === "notification" ? IslandTheme.notifR
    : island.face === "media" || island.face === "hub" ? IslandTheme.mediaR
    : island.face === "legacy" ? IslandTheme.legacyR : IslandTheme.idleR

  // Hover peek (+8 x +4, 150ms feel) on idle/activity only.
  readonly property bool peeking: pillHover.hovered
    && (island.face === "idle" || island.face === "activity")
  readonly property int targetW: island.baseW + (island.peeking ? IslandTheme.peekW : 0)
  readonly property int targetH: island.baseH + (island.peeking ? IslandTheme.peekH : 0)

  // Height lags the width by 30ms, per spec.
  property int hShown: 34
  Timer {
    id: hLag
    interval: IslandTheme.heightLagMs
    onTriggered: island.hShown = island.targetH
  }
  onTargetHChanged: {
    if (island.rm)
      island.hShown = island.targetH;
    else
      hLag.restart();
  }
  Component.onCompleted: island.hShown = island.targetH

  // Fixed window envelope: hub + 64px side padding + 8px top margin.
  // Legacy panes may push past it; island states never resize it.
  implicitWidth: Math.max(548, island.targetW + 128)
  implicitHeight: Math.max(308, island.targetH + 72)

  // ---- the pill --------------------------------------------------
  Item {
    id: pill
    anchors.top: parent.top
    anchors.topMargin: 8
    anchors.horizontalCenter: parent.horizontalCenter
    width: island.targetW
    height: island.hShown
    clip: wSpring.running || hSpring.running

    Behavior on width {
      enabled: !island.rm
      SpringAnimation {
        id: wSpring
        spring: IslandTheme.springStiffness
        damping: IslandTheme.springDamping
        epsilon: IslandTheme.springEps
      }
    }
    Behavior on height {
      enabled: !island.rm
      SpringAnimation {
        id: hSpring
        spring: IslandTheme.springStiffness
        damping: IslandTheme.springDamping
        epsilon: IslandTheme.springEps
      }
    }

    Rectangle {
      id: pillBg
      anchors.fill: parent
      radius: island.baseR
      color: IslandTheme.pill
      border.color: island.face === "notification" && IslandState.notifUrgent
        ? IslandTheme.red : IslandTheme.pillBorder
      border.width: 1

      Behavior on radius {
        NumberAnimation {
          duration: island.rm ? 0 : IslandTheme.radiusMs
          easing.type: Easing.OutCubic
        }
      }

      Behavior on border.color {
        ColorAnimation {
          duration: island.rm ? 0 : 150
        }
      }

      layer.enabled: IslandState.expanded || (island.face !== "idle" && island.face !== "activity")
      layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: "#000000"
        shadowBlur: 0.8
        shadowOpacity: 0.5
        shadowHorizontalOffset: 0
        shadowVerticalOffset: 6
      }
    }

    HoverHandler {
      id: pillHover
    }

    WheelHandler {
      // Scroll: volume ±5%; Shift+scroll: brightness ±5%.
      onWheel: (event) => {
        const d = event.angleDelta.y > 0 ? 1 : -1;
        if (event.modifiers & Qt.ShiftModifier)
          IslandState.nudgeLevel(d * 0.05);
        else
          IslandState.nudgeVolume(d * 0.05);
      }
    }

    // Background gaps: left toggles the activity's expanded view
    // (idle→hub), right flips DND, middle plays/mutes.
    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: (mouse) => {
        if (mouse.button === Qt.RightButton)
          IslandState.toggleDnd();
        else if (mouse.button === Qt.MiddleButton) {
          if (IslandState.hasPlayer)
            IslandState.togglePlaying();
          else
            IslandState.toggleMute();
        } else {
          IslandState.toggleView();
        }
      }
    }

    // ---- idle: compact clock --------------------------------
    Face {
      anchors.fill: parent
      shown: island.face === "idle"

      Row {
        anchors.centerIn: parent
        spacing: 6

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: IslandState.timeText
          color: IslandTheme.text
          font.family: IslandTheme.fontFamily
          font.pixelSize: IslandTheme.compactSize
          font.weight: Font.DemiBold
        }

        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          width: 6
          height: 6
          radius: 3
          color: IslandTheme.orange
          visible: IslandState.dnd
        }
      }
    }

    // ---- activity: art + title + AudioBars -----------------------
    Face {
      anchors.fill: parent
      shown: island.face === "activity"

      // Sequential cluster: art | title | bars, packed left with
      // fixed gaps — short titles leave trailing space at the pill
      // edge, never a void between title and bars.
      Row {
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Item {
          width: 22
          height: 22
          anchors.verticalCenter: parent.verticalCenter

          Rectangle {
            anchors.fill: parent
            radius: 6
            color: IslandTheme.surfaceHigh
          }

          Image {
            id: actArt
            anchors.fill: parent
            source: IslandState.artUrl
            fillMode: Image.PreserveAspectCrop
            visible: IslandState.artUrl !== "" && status === Image.Ready
          }

          Text {
            anchors.centerIn: parent
            text: (IslandState.title || "?").charAt(0).toUpperCase()
            color: IslandTheme.textSecondary
            font.family: IslandTheme.fontFamily
            font.pixelSize: 12
            font.weight: Font.DemiBold
            visible: !actArt.visible
          }

          // Charger ring: green arc around the art while charging.
          Rectangle {
            anchors.fill: parent
            radius: 6
            color: "transparent"
            border.color: IslandTheme.green
            border.width: 1.5
            visible: IslandState.charging && IslandState.battAvailable
          }
        }

        // Title hugs its content up to 150px, then marquees while playing.
        Item {
          width: Math.min(actTitle.implicitWidth, 150)
          height: 22
          clip: true

          Text {
            id: actTitle
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -1
            text: IslandState.title !== "" ? IslandState.title : "Nothing playing"
            color: IslandTheme.text
            font.family: IslandTheme.fontFamily
            font.pixelSize: IslandTheme.compactSize
            font.weight: Font.DemiBold

            NumberAnimation on x {
              id: actMarq
              from: 0
              to: -(actTitle.implicitWidth - 150)
              duration: Math.max(1200, actTitle.implicitWidth * 30)
              loops: Animation.Infinite
              running: actTitle.implicitWidth > 150 && IslandState.isPlaying
                && island.face === "activity" && !island.rm
              onRunningChanged: {
                if (!running)
                  actTitle.x = 0;
              }
            }
          }
        }

        // AudioBars: grounded in the 22px row box, frozen unless playing.
        Row {
          spacing: 2
          height: 22

          Repeater {
            model: 4

            delegate: Rectangle {
              required property int index
              width: 3
              height: 7
              radius: 1.5
              color: IslandTheme.accent
              anchors.bottom: parent.bottom

              SequentialAnimation on height {
                loops: Animation.Infinite
                running: island.face === "activity" && IslandState.isPlaying && !island.rm
                NumberAnimation {
                  to: 13
                  duration: 260 + index * 70
                  easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                  to: 5
                  duration: 260 + index * 70
                  easing.type: Easing.InOutQuad
                }
              }
            }
          }
        }
      }
    }

    // ---- toast: volume / brightness / ws-dots --------------------
    Face {
      id: toastFace
      anchors.fill: parent
      shown: island.face === "toast"

      readonly property bool demoToast: island.display.indexOf("demo:") === 0

      MouseArea {
        anchors.fill: parent
        onClicked: IslandState.clearToast()
      }

      // OSD path: icon+label row centered as a group, level bar
      // centered in the capsule independent of the label row.
      Column {
        anchors.centerIn: parent
        spacing: 6
        visible: ShellState.osdVisible || toastFace.demoToast

        Row {
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: 10

          Text {
            anchors.verticalCenter: parent.verticalCenter
            // Glyph ink verified centered against the 12px Inter label (1x).
            anchors.verticalCenterOffset: 0
            text: toastFace.demoToast ? IslandState.volGlyph : IslandState.osdIcon()
            color: IslandTheme.text
            font.family: Theme.fontFamily
            font.pixelSize: 20
            renderType: Text.QtRendering
          }

          Text {
            id: toastLabel
            anchors.verticalCenter: parent.verticalCenter
            text: toastFace.demoToast ? "Volume  65%" : IslandState.osdLabel()
            color: IslandTheme.text
            font.family: IslandTheme.fontFamily
            font.pixelSize: IslandTheme.secondarySize
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            maximumLineCount: 1
          }
        }

        Rectangle {
          width: 272
          height: 5
          radius: 2.5
          anchors.horizontalCenter: parent.horizontalCenter
          color: Qt.rgba(1, 1, 1, 0.35)

          Rectangle {
            width: parent.width * (toastFace.demoToast ? 0.65 : ShellState.osdValue)
            height: parent.height
            radius: parent.radius
            color: IslandTheme.accent

            Behavior on width {
              NumberAnimation {
                duration: island.rm ? 0 : 90
                easing.type: Easing.OutCubic
              }
            }
          }
        }
      }

      // Workspace-switch path: the 5-dot strip.
      C.IslandWorkspaces {
        anchors.centerIn: parent
        barScreen: island.barScreen
        dotSize: 8
        visible: !ShellState.osdVisible && !toastFace.demoToast
      }
    }

    // ---- notification: app avatar + summary + body ------------
    Face {
      id: notifFace
      anchors.fill: parent
      shown: island.face === "notification"

      HoverHandler {
        onHoveredChanged: IslandState.notifHover = hovered
      }

      // Click = default action; X = dismiss without acting.
      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: IslandState.notifActivate()
      }

      Row {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        anchors.topMargin: 14
        anchors.bottomMargin: 14
        spacing: 10

        Rectangle {
          width: 40
          height: 40
          radius: 12
          anchors.verticalCenter: parent.verticalCenter
          color: IslandTheme.surfaceHigh

          Text {
            anchors.centerIn: parent
            text: ((island.notif && island.notif.appName) || "?").charAt(0).toUpperCase()
            color: IslandState.notifUrgent ? IslandTheme.red : IslandTheme.accent
            font.family: IslandTheme.fontFamily
            font.pixelSize: IslandTheme.bigSize
            font.weight: Font.DemiBold
          }
        }

        Column {
          width: 250
          anchors.verticalCenter: parent.verticalCenter
          spacing: 2

          Text {
            width: parent.width
            text: (island.notif && island.notif.appName ? island.notif.appName.toUpperCase() + "  ·  " : "")
              + (island.notif && island.notif.summary ? island.notif.summary : "")
            color: IslandTheme.text
            font.family: IslandTheme.fontFamily
            font.pixelSize: IslandTheme.titleSize
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            maximumLineCount: 1
          }

          Text {
            width: parent.width
            text: island.notif && island.notif.body ? island.notif.body : ""
            color: IslandTheme.textSecondary
            font.family: IslandTheme.fontFamily
            font.pixelSize: IslandTheme.secondarySize
            elide: Text.ElideRight
            maximumLineCount: 2
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            lineHeight: 1.4
            visible: text !== ""
          }
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: Icons.close
          color: closeHover.hovered ? IslandTheme.red : IslandTheme.textSecondary
          font.family: Theme.fontFamily
          font.pixelSize: 12

          HoverHandler {
            id: closeHover
          }

          MouseArea {
            anchors.fill: parent
            anchors.margins: -8
            cursorShape: Qt.PointingHandCursor
            onClicked: (mouse) => {
              mouse.accepted = true;
              IslandState.notifClose();
            }
          }
        }
      }
    }

    // ---- expandedMedia: art + marquee + seek + transport ---------
    Face {
      anchors.fill: parent
      shown: island.face === "media"

      Row {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Rectangle {
          width: 96
          height: 96
          radius: 14
          color: IslandTheme.surfaceHigh
          clip: true
          anchors.verticalCenter: parent.verticalCenter

          Image {
            id: mediaArt
            anchors.fill: parent
            source: IslandState.artUrl
            fillMode: Image.PreserveAspectCrop
            visible: IslandState.artUrl !== "" && status === Image.Ready
          }

          Text {
            anchors.centerIn: parent
            text: (IslandState.title || "?").charAt(0).toUpperCase()
            color: IslandTheme.textSecondary
            font.family: IslandTheme.fontFamily
            font.pixelSize: 34
            font.weight: Font.DemiBold
            visible: !mediaArt.visible
          }
        }

        Column {
          width: 280
          anchors.verticalCenter: parent.verticalCenter
          spacing: 4

          // Player switcher: always reserved; multi-player renders an
          // explicit ‹ label (i/n) › with bright chevrons, single stays
          // a dim label with no chevron (click cycles).
          Item {
            width: parent.width
            height: 18

            Text {
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              text: IslandState.playerCount > 1
                ? "‹  " + IslandState.playerLabel + "  (" + IslandState.playerPos + "/" + IslandState.playerCount + ")  ›"
                : IslandState.playerLabel
              color: IslandState.playerCount > 1 ? IslandTheme.text : IslandTheme.textSecondary
              font.family: IslandTheme.fontFamily
              font.pixelSize: IslandTheme.secondarySize
              font.weight: Font.DemiBold
              elide: Text.ElideRight
              width: parent.width
              maximumLineCount: 1
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: IslandState.playerCount > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
              onClicked: {
                if (IslandState.playerCount > 1)
                  IslandState.cyclePlayer();
              }
            }
          }

          // Marquee if long: scrolls only while playing + shown.
          Item {
            width: parent.width
            height: 22
            clip: true

            Text {
              id: titleText
              text: IslandState.title !== "" ? IslandState.title : "Nothing playing"
              color: IslandTheme.text
              font.family: IslandTheme.fontFamily
              font.pixelSize: IslandTheme.bigSize
              font.weight: Font.DemiBold

              NumberAnimation on x {
                id: marq
                from: 0
                to: -(titleText.implicitWidth - 280)
                duration: Math.max(1200, titleText.implicitWidth * 28)
                loops: Animation.Infinite
                running: titleText.implicitWidth > 280 && IslandState.isPlaying
                  && island.face === "media" && !island.rm
                onRunningChanged: {
                  if (!running)
                    titleText.x = 0;
                }
              }
            }
          }

          Text {
            width: parent.width
            text: IslandState.artist
            color: IslandTheme.textSecondary
            font.family: IslandTheme.fontFamily
            font.pixelSize: IslandTheme.secondarySize
            elide: Text.ElideRight
            maximumLineCount: 1
            visible: text !== ""
          }

          // Seekbar only when the player really seeks.
          Row {
            width: parent.width
            spacing: 8
            visible: IslandState.canSeek && IslandState.positionSupported && IslandState.length > 0

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: IslandState.fmtDur(IslandState.shownPos)
              color: IslandTheme.textSecondary
              font.family: IslandTheme.fontFamily
              font.pixelSize: 11
            }

            C.BarSlider {
              width: parent.width - 76
              anchors.verticalCenter: parent.verticalCenter
              value: IslandState.length > 0 ? IslandState.shownPos / IslandState.length : 0
              onMoved: (v) => IslandState.seekTo(v * IslandState.length)
            }

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: "-" + IslandState.fmtDur(IslandState.length - IslandState.shownPos)
              color: IslandTheme.textSecondary
              font.family: IslandTheme.fontFamily
              font.pixelSize: 11
            }
          }

          // Transport: 28px buttons (icon font exception — Inter
          // has no codepoints for these; all prose stays Inter).
          Row {
            height: 32
            spacing: 18
            anchors.horizontalCenter: parent.horizontalCenter

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: Icons.prev
              color: IslandState.canGoPrevious ? IslandTheme.text : IslandTheme.surfaceHigh
              font.family: Theme.fontFamily
              font.pixelSize: 28

              MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: IslandState.previous()
              }
            }

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: IslandState.isPlaying ? Icons.pause : Icons.play
              color: IslandTheme.text
              font.family: Theme.fontFamily
              font.pixelSize: 28

              MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: IslandState.togglePlaying()
              }
            }

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: Icons.next
              color: IslandState.canGoNext ? IslandTheme.text : IslandTheme.surfaceHigh
              font.family: Theme.fontFamily
              font.pixelSize: 28

              MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: IslandState.next()
              }
            }
          }
        }
      }
    }

    // ---- hub: header + toggles + sliders + mini media --------
    Face {
      anchors.fill: parent
      shown: island.face === "hub"

      Column {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 5

        Item {
          width: parent.width
          height: 36

          Column {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            Text {
              text: IslandState.timeText
              color: IslandTheme.text
              font.family: IslandTheme.fontFamily
              font.pixelSize: IslandTheme.bigSize
              font.weight: Font.DemiBold
            }

            Text {
              text: IslandState.dateText
              color: IslandTheme.textSecondary
              font.family: IslandTheme.fontFamily
              font.pixelSize: 11
            }
          }

          Item {
            id: battRing
            width: 36
            height: 36
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: IslandState.battAvailable

            Canvas {
              id: ring
              anchors.fill: parent
              onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const cx = width / 2, cy = height / 2, r = width / 2 - 2;
                ctx.lineWidth = 3;
                ctx.strokeStyle = "rgba(255,255,255,0.15)";
                ctx.beginPath();
                ctx.arc(cx, cy, r, 0, Math.PI * 2);
                ctx.stroke();
                ctx.strokeStyle = IslandState.charging ? "#30D158" : "#0A84FF";
                ctx.beginPath();
                ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * IslandState.percent / 100);
                ctx.stroke();
              }
              Component.onCompleted: {
                IslandState.percentChanged.connect(requestPaint);
                IslandState.chargingChanged.connect(requestPaint);
              }
            }

            Text {
              anchors.centerIn: parent
              text: IslandState.percent
              color: IslandTheme.text
              font.family: IslandTheme.fontFamily
              font.pixelSize: 10
              font.weight: Font.DemiBold
            }
          }

          Text {
            anchors.right: parent.right
            anchors.rightMargin: battRing.visible ? 48 : 0
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 150)
            text: IslandState.ssid !== "" ? IslandState.ssid : "Offline"
            color: IslandTheme.textSecondary
            font.family: IslandTheme.fontFamily
            font.pixelSize: 11
            elide: Text.ElideRight
            maximumLineCount: 1
            horizontalAlignment: Text.AlignRight
          }
        }

        Row {
          width: parent.width
          spacing: 8

          HubToggle {
            width: (parent.width - 16) / 3
            icon: Icons.wifi
            caption: "Wi-Fi"
            isOn: IslandState.wifiEnabled
            tint: IslandTheme.accent
            onActivated: IslandState.toggleWifi()
          }

          HubToggle {
            width: (parent.width - 16) / 3
            icon: Icons.bluetooth
            caption: "Bluetooth"
            isOn: IslandState.btEnabled
            tint: IslandTheme.accent
            onActivated: IslandState.toggleBluetooth()
          }

          HubToggle {
            width: (parent.width - 16) / 3
            icon: IslandState.dnd ? Icons.bellSlash : Icons.bell
            caption: "DND"
            isOn: IslandState.dnd
            tint: IslandTheme.red
            onActivated: IslandState.toggleDnd()
          }
        }

        Item {
          width: parent.width
          height: 30

          Text {
            id: volLabel
            anchors.left: parent.left
            anchors.baseline: volValue.baseline
            text: "Volume"
            color: IslandTheme.textSecondary
            font.family: IslandTheme.fontFamily
            font.pixelSize: 11
          }

          Text {
            id: volValue
            anchors.top: parent.top
            anchors.right: parent.right
            text: IslandState.muted ? "Muted" : Math.round(IslandState.volume * 100) + "%"
            color: IslandTheme.text
            font.family: IslandTheme.fontFamily
            font.pixelSize: 11
            font.weight: Font.DemiBold

            MouseArea {
              anchors.fill: parent
              anchors.margins: -4
              cursorShape: Qt.PointingHandCursor
              onClicked: IslandState.toggleMute()
            }
          }

          C.BarSlider {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            value: IslandState.muted ? 0 : IslandState.volume
            onMoved: (v) => IslandState.setVolume(v)
          }
        }

        Item {
          width: parent.width
          height: 30

          Text {
            anchors.left: parent.left
            anchors.baseline: brightValue.baseline
            text: "Brightness"
            color: IslandTheme.textSecondary
            font.family: IslandTheme.fontFamily
            font.pixelSize: 11
          }

          Text {
            id: brightValue
            anchors.top: parent.top
            anchors.right: parent.right
            text: Math.round(IslandState.level * 100) + "%"
            color: IslandTheme.text
            font.family: IslandTheme.fontFamily
            font.pixelSize: 11
            font.weight: Font.DemiBold
          }

          C.BarSlider {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            value: IslandState.level
            onMoved: (v) => IslandState.setLevel(v)
          }
        }

        // Mini media row: live track while playing, dim placeholder
        // otherwise so the 236px hub height is always filled.
        Item {
          width: parent.width
          height: 30

          Row {
            anchors.fill: parent
            spacing: 8
            visible: IslandState.isPlaying && IslandState.hasPlayer

            Rectangle {
              width: 28
              height: 28
              radius: 7
              color: IslandTheme.surfaceHigh
              clip: true
              anchors.verticalCenter: parent.verticalCenter

              Image {
                id: miniArt
                anchors.fill: parent
                source: IslandState.artUrl
                fillMode: Image.PreserveAspectCrop
                visible: IslandState.artUrl !== "" && status === Image.Ready
              }

              Text {
                anchors.centerIn: parent
                text: (IslandState.title || "?").charAt(0).toUpperCase()
                color: IslandTheme.textSecondary
                font.family: IslandTheme.fontFamily
                font.pixelSize: 13
                font.weight: Font.DemiBold
                visible: !miniArt.visible
              }
            }

            Column {
              width: parent.width - 28 - 24 - 16
              anchors.verticalCenter: parent.verticalCenter
              spacing: 0

              Text {
                width: parent.width
                text: IslandState.title
                color: IslandTheme.text
                font.family: IslandTheme.fontFamily
                font.pixelSize: 12
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                maximumLineCount: 1
              }

              Text {
                width: parent.width
                text: IslandState.artist
                color: IslandTheme.textSecondary
                font.family: IslandTheme.fontFamily
                font.pixelSize: 11
                elide: Text.ElideRight
                maximumLineCount: 1
              }
            }

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: Icons.pause
              color: IslandTheme.text
              font.family: Theme.fontFamily
              font.pixelSize: 16

              MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: IslandState.togglePlaying()
              }
            }
          }

          Row {
            anchors.fill: parent
            spacing: 8
            visible: !(IslandState.isPlaying && IslandState.hasPlayer)

            Rectangle {
              width: 28
              height: 28
              radius: 7
              color: IslandTheme.surfaceHigh
              anchors.verticalCenter: parent.verticalCenter
              opacity: 0.6
            }

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: "Nothing playing"
              color: IslandTheme.textSecondary
              font.family: IslandTheme.fontFamily
              font.pixelSize: 12
              opacity: 0.7
            }
          }
        }
      }
    }

    // ---- legacy panes: existing bodies, settled sizes ---------
    Face {
      anchors.fill: parent
      shown: island.face === "legacy"

      Column {
        anchors.fill: parent

        Item {
          width: parent.width
          height: IslandTheme.legacyHeaderH

          Text {
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: island.legacyTitle()
            color: IslandTheme.text
            font.family: IslandTheme.fontFamily
            font.pixelSize: IslandTheme.titleSize
            font.weight: Font.DemiBold
          }

          Text {
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: "Esc to close"
            color: IslandTheme.textSecondary
            font.family: IslandTheme.fontFamily
            font.pixelSize: 11

            MouseArea {
              anchors.fill: parent
              anchors.margins: -6
              cursorShape: Qt.PointingHandCursor
              onClicked: IslandState.collapse()
            }
          }
        }

        Item {
          width: island.legacyContentW()
          height: island.legacyContentH()
          anchors.horizontalCenter: parent.horizontalCenter

          C.ControlsBody {
            id: controlsBody
            anchors.fill: parent
            anchors.margins: IslandTheme.legacyMargin
            battGlyph: IslandState.battGlyph
            battPct: IslandState.percent
            visible: island.legacyMode === "controls"
          }

          C.LauncherBody {
            anchors.fill: parent
            anchors.margins: IslandTheme.legacyMargin
            active: island.face === "legacy" && island.legacyMode === "launcher"
            visible: island.legacyMode === "launcher"
          }

          C.WallpaperBody {
            anchors.fill: parent
            anchors.margins: IslandTheme.legacyMargin
            active: island.face === "legacy" && island.legacyMode === "picker"
            visible: island.legacyMode === "picker"
          }

          C.SessionBody {
            anchors.fill: parent
            anchors.margins: IslandTheme.legacyMargin
            active: island.face === "legacy" && island.legacyMode === "session"
            visible: island.legacyMode === "session"
          }

          C.CheatsheetBody {
            anchors.fill: parent
            anchors.margins: IslandTheme.legacyMargin
            visible: island.legacyMode === "keys"
          }

          Item {
            anchors.fill: parent
            visible: island.legacyMode === "calendar"

            C.Calendar {
              id: islandCal
              anchors.top: parent.top
              anchors.horizontalCenter: parent.horizontalCenter
              onPicked: IslandState.collapse()
            }

            Text {
              anchors.top: islandCal.bottom
              anchors.topMargin: 8
              anchors.horizontalCenter: parent.horizontalCenter
              text: "Esc close"
              color: IslandTheme.textSecondary
              font.family: IslandTheme.fontFamily
              font.pixelSize: 10
            }
          }
        }
      }
    }
  }

  focus: IslandState.expanded
  Keys.onEscapePressed: {
    if (island.legacyMode === "controls" && ShellState.centerView !== "main")
      ShellState.centerBack();
    else
      IslandState.collapse();
  }

  // Seek readout tick: media face + playing + seekable only.
  Timer {
    id: seekTick
    interval: 1000
    repeat: true
    running: island.face === "media" && IslandState.isPlaying && IslandState.canSeek && IslandState.length > 0
    onTriggered: IslandState.tickSeek()
  }

  onFaceChanged: {
    if (island.face === "media")
      IslandState.markPos();
  }

  // Keyboard parity with the old pill: land on the first toggle when
  // the controls main view opens.
  Timer {
    id: legacyFocus
    interval: 120
    onTriggered: {
      if (island.legacyMode === "controls")
        controlsBody.focusFirst();
    }
  }
  onLegacyModeChanged: {
    if (island.legacyMode === "controls")
      legacyFocus.restart();
  }
}
