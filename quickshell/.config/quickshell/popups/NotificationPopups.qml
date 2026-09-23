import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import ".."

// Notification popups (top right, under the bar).
// Left-click buttons work as normal; right-click anywhere on the
// stack clears every popup. Normal/low popups fade out on their own,
// critical ones stay until closed.
PanelWindow {
  id: popups

  anchors {
    top: true
    right: true
    bottom: true
  }
  margins {
    top: Theme.barMarginTop + Theme.barHeight + 6
    right: Theme.barMarginSide
  }
  implicitWidth: 360
  color: "transparent"
  visible: Notify.popupModel.count > 0
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "quickshell-popup"
  mask: Region {
    item: column
  }

  // Right-click anywhere on the stack clears all popups.
  // Only the right button is accepted, so left-clicks pass through
  // to close buttons and action buttons below.
  // The mask confines input to the column: the transparent remainder
  // of this full-height strip stays click-through.
  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.RightButton
    onClicked: mouse => {
      if (mouse.button === Qt.RightButton)
        Notify.dismissAll();
    }
  }

  Column {
    id: column
    width: parent.width
    spacing: 0

    // No Column transitions on purpose. Enter/exit motion is owned
    // entirely by each delegate (enterAnim / exitAnim below), so an
    // append creates exactly one animation and siblings stay idle:
    // no add/move/populate/displaced re-fading or gliding the stack.
    Repeater {
      // Stable incremental model: appending or removing one row creates
      // or destroys exactly one delegate. Siblings keep their Timers,
      // progress bars and finished entrance state untouched.
      model: Notify.popupModel

      // Wrapper owns layout + lifecycle; the visual card inside owns
      // x/opacity. The wrapper is (visual height + 10 bottom pad) so it
      // replaces the old Column spacing. Collapse drives the wrapper to
      // exactly 0, so delegate destruction removes 0px — no end-snap.
      // The window itself is a fixed full-height strip (no implicitHeight
      // binding), so collapse frames never renegotiate the Wayland
      // surface size mid-animation.
      delegate: Item {
        id: wrap
        required property var notif
        required property double dismissAt
        required property int lifeMs

        // Remaining life, frozen when this delegate is created: a card
        // created later (or rebuilt after e.g. a layer re-show) resumes
        // its own deadline instead of restarting the auto-dismiss clock.
        readonly property int remainingMs: Math.max(0, Math.round(wrap.dismissAt - Date.now()))
        readonly property bool critical: notif.urgency === NotificationUrgency.Critical
        property bool leaving: false
        property bool collapsing: false
        property real collapseHeight: 0
        property int pending: 0 // 1 = expire, 2 = dismiss, 3 = untrack only
        property real lifeProgress: wrap.lifeMs > 0 ? Math.min(1, wrap.remainingMs / wrap.lifeMs) : 1
        // Hover-pause bookkeeping: hoverPaused drives Timer running + progress
        // paused via bindings so entrance state is never touched.
        property bool hoverPaused: false
        property int pauseRemaining: -1
        property double hoverStart: 0

        // Integer rest heights: rounded once so fractional text metrics
        // never shimmer at rest. Collapse itself may run fractional.
        property int visualH: Math.round(content.implicitHeight) + 30
        property int fullH: visualH + 10

        width: column.width
        height: wrap.collapsing ? wrap.collapseHeight : wrap.fullH
        clip: true

        // Phase 2: height collapse driving the sibling move-up glide.
        // Same soft cubic, 240ms: the gentle attack avoids a multi-pixel
        // jump on the first frames (the old y1=1 snapped), so the Column
        // follows the shrinking height frame-by-frame and cards below
        // glide up. No Column add/move/displaced transitions and no
        // Behaviors on x/opacity, so appends keep siblings idle and
        // entrance never re-fires.
        NumberAnimation {
          id: collapseAnim
          target: wrap
          property: "collapseHeight"
          to: 0
          duration: 240
          easing.type: Easing.BezierSpline
          easing.bezierCurve: [0.33, 0, 0.13, 1]
          onFinished: {
            const n = wrap.notif;
            const kind = wrap.pending;
            if (kind === 1) {
              Notify.untrack(n);
              n.expire();
            } else if (kind === 2) {
              Notify.dismiss(n);
            } else {
              Notify.untrack(n);
            }
          }
        }

        Component.onCompleted: {
          // Freeze the drain once: from/duration are assigned, never bound,
          // so later dismissAt shifts for hover-pause cannot refill it.
          progressAnim.from = wrap.lifeMs > 0 ? Math.min(1, wrap.remainingMs / wrap.lifeMs) : 1;
          progressAnim.duration = Math.max(1, wrap.remainingMs);
          if (wrap.lifeMs > 0)
            progressAnim.start();
          enterAnim.start();
        }

        // Slide the timeout bar down linearly while the popup is alive.
        // Starts from this card's own remaining share, so a late-created
        // delegate resumes the drain instead of refilling it. Paused via
        // hoverPaused binding — never restarted, never refilled.
        // running: false is load-bearing: an `on`-animation auto-starts at
        // creation with the default 250ms duration, so without this the
        // from/duration assigned in onCompleted land mid-run (ignored) and
        // start() no-ops on the already-running animation — the bar would
        // flash full-to-empty in 250ms instead of draining over remainingMs.
        NumberAnimation on lifeProgress {
          id: progressAnim
          running: false
          to: 0
          paused: wrap.hoverPaused
        }

        function leave(kind) {
          if (leaving)
            return;
          leaving = true;
          pending = kind;
          // Stop the entrance if it is still running so x/opacity are
          // driven by exactly one animation during the exit.
          enterAnim.stop();
          exitAnim.start();
        }

        // Auto-dismiss: normal and low popups leave on their own,
        // critical popups never start this timer and stay put.
        // Each card runs its own remaining time, independent of siblings.
        // hoverPaused stops it via binding (no manual stop that would break
        // the leaving binding); interval is set to the leftover on unhover.
        Timer {
          id: dismissTimer
          interval: Math.max(1, wrap.remainingMs)
          running: wrap.lifeMs > 0 && !wrap.leaving && !wrap.hoverPaused
          repeat: false
          onTriggered: wrap.leave(1)
        }

        Connections {
          target: wrap.notif
          function onClosed(reason) {
            // Server-side close: fade out through the same exit path
            // instead of vanishing instantly. leave() guards re-entry,
            // and untrack is idempotent, so expire/dismiss races are safe.
            if (!wrap.leaving)
              wrap.leave(3);
            else
              Notify.untrack(wrap.notif);
          }
        }

        Rectangle {
          id: card
          width: parent.width
          height: wrap.visualH
          anchors.top: parent.top
          anchors.left: parent.left
          color: Theme.bgSolid
          border.color: wrap.critical ? Theme.critical : Theme.border
          border.width: 1
          radius: Theme.radius
          // Entrance starts off-screen-right and faded; enterAnim drives
          // to x 0 / opacity 1 once. Siblings are already at rest so they
          // never re-animate when this delegate is created at the bottom.
          opacity: 0
          x: 48
          clip: true

          // Per-delegate entrance: right-to-left slide + fade.
          // Soft ease-in-out cubic (~300ms, zero-velocity attack) so the
          // card eases out of the edge instead of snapping. No Column
          // add/populate and no Behaviors on x/opacity anywhere, so
          // nothing double-drives it.
          ParallelAnimation {
            id: enterAnim
            NumberAnimation {
              target: card
              property: "x"
              to: 0
              duration: 300
              easing.type: Easing.BezierSpline
              easing.bezierCurve: [0.33, 0, 0.13, 1]
            }
            NumberAnimation {
              target: card
              property: "opacity"
              to: 1
              duration: 300
              easing.type: Easing.BezierSpline
              easing.bezierCurve: [0.33, 0, 0.13, 1]
            }
          }

          // Per-delegate exit: exact reverse of entrance (slide back right
          // + fade, ~220ms, same soft cubic). Height stays fully open during
          // the fade so the Column does not relayout mid-animation. The model
          // row is removed only after the collapse phase below, so siblings
          // glide up instead of snapping.
          ParallelAnimation {
            id: exitAnim
            NumberAnimation {
              target: card
              property: "opacity"
              to: 0
              duration: 220
              easing.type: Easing.BezierSpline
              easing.bezierCurve: [0.33, 0, 0.13, 1]
            }
            NumberAnimation {
              target: card
              property: "x"
              to: 48
              duration: 220
              easing.type: Easing.BezierSpline
              easing.bezierCurve: [0.33, 0, 0.13, 1]
            }
            onFinished: {
              // Phase 2: collapse the wrapper (visual + pad) so the Column
              // relayout itself glides. Card is already faded + slid
              // (opacity 0, x 48), so shrinking height only moves siblings'
              // y — x/opacity never re-fire and sibling Timers / progress
              // bars are untouched. Starts from the integer rest height;
              // destruction at 0 removes exactly 0px with spacing 0.
              wrap.collapseHeight = wrap.fullH;
              wrap.collapsing = true;
              collapseAnim.start();
            }
          }

          // Hover pauses auto-dismiss anywhere on the card, buttons included.
          // HoverHandler is passive: X close, action invokes and the parent
          // right-click dismiss-all keep working mid-hover.
          HoverHandler {
            id: cardHover
            onHoveredChanged: {
              if (wrap.critical || wrap.lifeMs <= 0)
                return;
              if (hovered) {
                if (wrap.leaving || wrap.collapsing)
                  return;
                wrap.hoverStart = Date.now();
                wrap.pauseRemaining = Math.max(0, Math.round(wrap.dismissAt - Date.now()));
                // Freeze via binding; progress pauses via its paused binding.
                wrap.hoverPaused = true;
              } else {
                if (wrap.pauseRemaining < 0) {
                  wrap.hoverPaused = false;
                  return;
                }
                const hoverDur = Math.max(0, Date.now() - wrap.hoverStart);
                const leftover = Math.max(1, wrap.pauseRemaining);
                // Shift the absolute deadline forward by the hovered duration
                // so rebuilds resume the leftover instead of restarting or
                // instant-firing. Identity search keeps it robust to index
                // shifts from removals above.
                const shifted = wrap.dismissAt + hoverDur;
                for (let i = 0; i < Notify.popupModel.count; ++i) {
                  if (Notify.popupModel.get(i).notif === wrap.notif) {
                    Notify.popupModel.setProperty(i, "dismissAt", shifted);
                    break;
                  }
                }
                wrap.pauseRemaining = -1;
                if (wrap.leaving || wrap.collapsing) {
                  wrap.hoverPaused = false;
                  return;
                }
                // Leftover only — never a full-timeout restart. Assigning
                // breaks the initial interval binding on purpose: the timer
                // is now manually driven with the preserved remainder.
                // Set before clearing hoverPaused so the timer restarts
                // directly with the leftover, not the stale full interval.
                dismissTimer.interval = leftover;
                wrap.hoverPaused = false;
              }
            }
          }

          // Soft wash so critical cards feel urgent without shouting.
          Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Theme.critical
            opacity: 0.07
            visible: wrap.critical
          }

          // Left accent strip: red for critical, accent for the rest.
          Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.leftMargin: 1
            anchors.topMargin: 8
            anchors.bottomMargin: 8
            width: 3
            radius: 2
            color: wrap.critical ? Theme.critical : Theme.accent
            opacity: wrap.critical ? 1 : 0.55
          }

          Column {
            id: content
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: 18
            anchors.rightMargin: 12
            anchors.topMargin: 12
            spacing: 5

            // Header: app dot + name on the left, pill + close on the right.
            Item {
              width: parent.width
              implicitHeight: Math.max(appRow.implicitHeight, closeHit.height)

              Row {
                id: appRow
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - closeHit.width - 8
                spacing: 7

                Rectangle {
                  anchors.verticalCenter: parent.verticalCenter
                  width: 6
                  height: 6
                  radius: 3
                  color: wrap.critical ? Theme.critical : Theme.accent
                  opacity: wrap.critical ? 1 : 0.7
                }

                Text {
                  anchors.verticalCenter: parent.verticalCenter
                  width: parent.width - 13 - pill.width - (pill.visible ? 7 : 0)
                  text: (wrap.notif.appName || "Notification").toUpperCase()
                  color: Theme.muted
                  font.family: Theme.fontFamily
                  font.pixelSize: 10
                  font.letterSpacing: 0.6
                  elide: Text.ElideRight
                  maximumLineCount: 1
                }

                Rectangle {
                  id: pill
                  anchors.verticalCenter: parent.verticalCenter
                  width: pillText.implicitWidth + 12
                  height: 16
                  radius: 8
                  color: "transparent"
                  border.color: Theme.critical
                  border.width: 1
                  visible: wrap.critical

                  Text {
                    id: pillText
                    anchors.centerIn: parent
                    text: "Important"
                    color: Theme.critical
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                    font.letterSpacing: 0.4
                  }
                }
              }

              Rectangle {
                id: closeHit
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 24
                height: 24
                radius: 12
                color: closeHover.hovered ? Theme.hover : "transparent"

                Behavior on color {
                  ColorAnimation {
                    duration: Theme.hoverDuration
                  }
                }

                Text {
                  anchors.centerIn: parent
                  text: Icons.close
                  color: closeHover.hovered ? Theme.critical : Theme.muted
                  font.family: Theme.fontFamily
                  font.pixelSize: 11
                }

                HoverHandler {
                  id: closeHover
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: wrap.leave(2)
                }
              }
            }

            Text {
              width: parent.width
              text: wrap.notif.summary
              color: Theme.bright
              font.family: Theme.fontFamily
              font.pixelSize: 13
              font.bold: true
              wrapMode: Text.WordWrap
              elide: Text.ElideRight
              maximumLineCount: 2
              lineHeight: 1.25
              visible: text !== ""
            }

            Text {
              width: parent.width
              text: wrap.notif.body
              color: Theme.fg
              font.family: Theme.fontFamily
              font.pixelSize: 12
              wrapMode: Text.WordWrap
              elide: Text.ElideRight
              maximumLineCount: 4
              lineHeight: 1.4
              opacity: 0.9
              visible: text !== ""
            }

            Row {
              spacing: 8
              topPadding: 3
              visible: wrap.notif.actions.length > 0

              Repeater {
                model: wrap.notif.actions

                delegate: Rectangle {
                  required property var modelData

                  width: Math.max(actionText.implicitWidth + 24, 64)
                  height: 28
                  radius: Theme.radius - 2
                  color: actionHover.hovered ? Theme.hover : "transparent"
                  border.color: Theme.border
                  border.width: 1

                  Behavior on color {
                    ColorAnimation {
                      duration: Theme.hoverDuration
                    }
                  }

                  Text {
                    id: actionText
                    anchors.centerIn: parent
                    text: modelData.text
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                  }

                  HoverHandler {
                    id: actionHover
                  }

                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      const act = modelData;
                      act.invoke();
                      wrap.leave(3);
                    }
                  }
                }
              }
            }
          }

          // Timeout progress: drains while the popup is alive.
          Rectangle {
            id: track
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            anchors.bottomMargin: 7
            height: 2
            radius: 1
            color: wrap.critical ? Theme.critical : Theme.accent
            opacity: 0.22
            visible: wrap.lifeMs > 0

            Rectangle {
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              width: parent.width * wrap.lifeProgress
              height: parent.height
              radius: parent.radius
              color: wrap.critical ? Theme.critical : Theme.accent
              opacity: 0.9
            }
          }
        }
      }
    }

  }
}
