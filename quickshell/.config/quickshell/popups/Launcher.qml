import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import ".."

// Unified launcher (wofi replacement) with two pages:
//   apps       - desktop entries (was `wofi --show drun`)
//   clipboard  - cliphist history (was `cliphist list | wofi --dmenu`)
// Wallpapers live in the slide-down picker (was `wallpaper_switch.sh`).
PanelWindow {
  id: launcher

  anchors {
    top: true
    left: true
    right: true
    bottom: true
  }
  color: "transparent"
  visible: ShellState.launcherOpen
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "quickshell-popup"
  WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  property string query: ""
  property string clipboardRaw: ""

  property var items: buildItems()
  readonly property alias inputFocus: input.activeFocus

  readonly property var pages: [
    { id: "apps", label: "Apps", icon: Icons.apps },
    { id: "clipboard", label: "Clipboard", icon: Icons.clipboard }
  ]

  function close() {
    ShellState.launcherOpen = false;
  }

  function move(delta) {
    if (items.length === 0)
      return;
    const next = Math.max(0, Math.min(items.length - 1, list.currentIndex + delta));
    list.currentIndex = next;
    list.positionViewAtIndex(next, ListView.Contain);
  }

  function activateCurrent() {
    if (list.currentIndex >= 0 && list.currentIndex < items.length)
      items[list.currentIndex].run();
  }

  function buildItems() {
    const page = ShellState.launcherPage;
    const q = query.trim().toLowerCase();

    if (page === "clipboard") {
      const out = [];
      const lines = clipboardRaw.split("\n");
      for (let i = 0; i < lines.length; i++) {
        const m = lines[i].match(/^(\d+)\t(.*)$/);
        if (!m)
          continue;
        const preview = m[2].replace(/\s+/g, " ").trim();
        if (preview === "")
          continue;
        if (q !== "" && preview.toLowerCase().indexOf(q) === -1)
          continue;
        out.push({
          kind: "clipboard",
          label: preview.length > 90 ? preview.substring(0, 90) + "…" : preview,
          sub: "clipboard entry #" + m[1],
          run: ((id) => () => {
            Quickshell.execDetached({
              command: ["sh", "-c", "cliphist decode " + id + " | wl-copy"]
            });
            launcher.close();
          })(m[1])
        });
        if (out.length >= 300)
          break;
      }
      return out;
    }

    // apps
    const entries = DesktopEntries.applications.values;
    const scored = [];
    for (let i = 0; i < entries.length; i++) {
      const entry = entries[i];
      const score = appScore(entry, q);
      if (score > 0)
        scored.push({ entry: entry, score: score });
    }
    scored.sort((a, b) => b.score - a.score || (a.entry.name || "").localeCompare(b.entry.name || ""));
    const out = [];
    for (let i = 0; i < scored.length && i < 200; i++)
      out.push(appItem(scored[i].entry));
    return out;
  }

  function appScore(entry, q) {
    if (q === "")
      return 1;
    const name = (entry.name || "").toLowerCase();
    if (name.startsWith(q))
      return 100;
    if (name.indexOf(" " + q) !== -1)
      return 80;
    if (name.indexOf(q) !== -1)
      return 60;
    const keywords = (entry.keywords || []).join(" ").toLowerCase();
    if (keywords.indexOf(q) !== -1)
      return 40;
    if ((entry.comment || "").toLowerCase().indexOf(q) !== -1)
      return 20;
    return 0;
  }

  function appItem(entry) {
    return {
      kind: "app",
      label: entry.name || entry.id,
      sub: entry.genericName || entry.comment || "",
      run: () => {
        if (entry.runInTerminal)
          Quickshell.execDetached({ command: ["ghostty", "-e"].concat(entry.command) });
        else
          entry.execute();
        launcher.close();
      }
    };
  }

  Process {
    id: clipProc
    command: ["cliphist", "list"]

    stdout: StdioCollector {
      onStreamFinished: launcher.clipboardRaw = this.text
    }
  }

  function refreshClipboard() {
    if (ShellState.launcherPage === "clipboard")
      clipProc.running = true;
  }

  function focusInput() {
    input.forceActiveFocus();
    input.selectAll();
  }

  // Keyboard focus on the layer surface is granted asynchronously, so keep
  // re-asserting it until the search field owns the focus.
  Timer {
    interval: 60
    repeat: true
    running: launcher.visible && !input.activeFocus
    onTriggered: launcher.focusInput()
  }

  onVisibleChanged: {
    if (visible) {
      query = "";
      list.currentIndex = 0;
      refreshClipboard();
      focusInput();
    }
  }

  Connections {
    target: ShellState
    function onLauncherPageChanged() {
      launcher.query = "";
      list.currentIndex = 0;
      launcher.refreshClipboard();
      launcher.focusInput();
    }
  }

  // dim scrim, click outside the card to close
  Rectangle {
    id: backdrop
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.4 * (ShellState.launcherOpen ? 1 : 0))

    Behavior on color {
      ColorAnimation { duration: Theme.popupDuration; easing.type: Easing.OutCubic }
    }

    MouseArea {
      anchors.fill: parent
      onClicked: launcher.close()
    }
  }

  Rectangle {
    id: card
    anchors.centerIn: parent
    width: 640
    height: 460
    color: Theme.bgSolid
    border.color: Theme.border
    border.width: 1
    radius: Theme.radius

    scale: ShellState.launcherOpen ? 1 : 0.97

    Behavior on scale {
      NumberAnimation { duration: Theme.popupDuration; easing.type: Easing.OutQuint }
    }

    transform: Translate {
      y: ShellState.launcherOpen ? 0 : 30

      Behavior on y {
        NumberAnimation { duration: Theme.popupDuration; easing.type: Easing.OutQuint }
      }
    }

    opacity: ShellState.launcherOpen ? 1 : 0

    Behavior on opacity {
      NumberAnimation { duration: Theme.popupDuration * 0.7 }
    }

    MouseArea {
      anchors.fill: parent
    }

    // ---------------------------------------------------------------------
    // Page tabs
    // ---------------------------------------------------------------------
    Row {
      id: tabs
      anchors.top: parent.top
      anchors.topMargin: 14
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 8

      Repeater {
        model: launcher.pages

        delegate: Rectangle {
          required property var modelData

          readonly property bool active: ShellState.launcherPage === modelData.id

          width: tabRow.implicitWidth + 24
          height: 30
          radius: Theme.radius
          color: active ? Theme.hover : tabHover.hovered ? Qt.rgba(Theme.hover.r, Theme.hover.g, Theme.hover.b, 0.5) : "transparent"
          border.color: active ? Theme.accent : Theme.border
          border.width: 1

          Behavior on color {
            ColorAnimation { duration: Theme.hoverDuration; easing.type: Easing.OutCubic }
          }

          Behavior on border.color {
            ColorAnimation { duration: Theme.hoverDuration; easing.type: Easing.OutCubic }
          }

          HoverHandler {
            id: tabHover
          }

          Row {
            id: tabRow
            anchors.centerIn: parent
            spacing: 6

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: modelData.icon
              color: parent.parent.active ? Theme.accent : Theme.muted
              font.family: Theme.fontFamily
              font.pixelSize: 12

              Behavior on color {
                ColorAnimation { duration: Theme.hoverDuration; easing.type: Easing.OutCubic }
              }
            }

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: modelData.label
              color: parent.parent.active ? Theme.bright : Theme.muted
              font.family: Theme.fontFamily
              font.pixelSize: 12

              Behavior on color {
                ColorAnimation { duration: Theme.hoverDuration; easing.type: Easing.OutCubic }
              }
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: ShellState.launcherPage = modelData.id
          }
        }
      }
    }

    // ---------------------------------------------------------------------
    // Search input
    // ---------------------------------------------------------------------
    Rectangle {
      id: searchBox
      anchors.top: tabs.bottom
      anchors.topMargin: 12
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.leftMargin: 16
      anchors.rightMargin: 16
      height: 42
      radius: Theme.radius
      color: "transparent"
      border.color: input.activeFocus ? Theme.accent : Theme.border
      border.width: 1

      Behavior on border.color {
        ColorAnimation { duration: Theme.hoverDuration; easing.type: Easing.OutCubic }
      }

      Text {
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        text: Icons.search
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: 13
      }

      TextInput {
        id: input
        anchors.left: parent.left
        anchors.leftMargin: 40
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        focus: launcher.visible
        color: Theme.fg
        font.family: Theme.fontFamily
        font.pixelSize: 14
        selectionColor: Theme.hover
        selectedTextColor: Theme.bright
        clip: true

        onTextChanged: launcher.query = text

        Keys.onEscapePressed: (event) => {
          launcher.close();
          event.accepted = true;
        }
        Keys.onUpPressed: (event) => {
          launcher.move(-1);
          event.accepted = true;
        }
        Keys.onDownPressed: (event) => {
          launcher.move(1);
          event.accepted = true;
        }
        Keys.onReturnPressed: (event) => {
          launcher.activateCurrent();
          event.accepted = true;
        }
        Keys.onTabPressed: (event) => {
          ShellState.launcherPage = ShellState.launcherPage === "apps" ? "clipboard" : "apps";
          event.accepted = true;
        }
      }

      Text {
        anchors.left: parent.left
        anchors.leftMargin: 40
        anchors.verticalCenter: parent.verticalCenter
        text: ShellState.launcherPage === "apps" ? "Search applications…" : "Search clipboard history…"
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: 13
        visible: input.text === ""
      }
    }

    // ---------------------------------------------------------------------
    // Results
    // ---------------------------------------------------------------------
    ListView {
      id: list
      anchors.top: searchBox.bottom
      anchors.topMargin: 10
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: footer.top
      anchors.leftMargin: 16
      anchors.rightMargin: 16
      anchors.bottomMargin: 10
      clip: true
      spacing: 4
      model: launcher.items
      currentIndex: 0
      boundsBehavior: Flickable.StopAtBounds
      // calmer glide, same feel as the control centre
      flickDeceleration: 900
      maximumFlickVelocity: 3200

      // keep the selected row in view while arrowing through results
      onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

      delegate: Rectangle {
        id: row
        required property var modelData
        required property int index

        readonly property bool selected: ListView.isCurrentItem

        width: ListView.view.width
        height: 46
        radius: Theme.radius
        color: selected ? Theme.hover : "transparent"
        border.color: selected ? Theme.accent : Theme.border
        border.width: selected ? 1 : 0

        Behavior on color {
          ColorAnimation { duration: Theme.hoverDuration; easing.type: Easing.OutCubic }
        }

        Behavior on border.color {
          ColorAnimation { duration: Theme.hoverDuration; easing.type: Easing.OutCubic }
        }

        Column {
          anchors.left: parent.left
          anchors.leftMargin: 12
          anchors.right: parent.right
          anchors.rightMargin: 12
          anchors.verticalCenter: parent.verticalCenter
          spacing: 2

          Text {
            width: parent.width
            text: row.modelData.label
            color: Theme.fg
            font.family: Theme.fontFamily
            font.pixelSize: 13
            elide: Text.ElideRight
          }

          Text {
            width: parent.width
            text: row.modelData.sub
            color: Theme.muted
            font.family: Theme.fontFamily
            font.pixelSize: 11
            elide: Text.ElideRight
            visible: text !== ""
          }
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onEntered: list.currentIndex = row.index
          onClicked: row.modelData.run()
        }
      }
    }

    // ---------------------------------------------------------------------
    // Footer
    // ---------------------------------------------------------------------
    Item {
      id: footer
      anchors.bottom: parent.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.margins: 14
      height: 18

      Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: launcher.items.length + " result" + (launcher.items.length === 1 ? "" : "s")
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: 10
      }

      Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: "Enter run   ↑↓ navigate   Esc close"
        color: Theme.muted
        font.family: Theme.fontFamily
        font.pixelSize: 10
      }
    }
  }
}
