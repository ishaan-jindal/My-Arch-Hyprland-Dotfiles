pragma Singleton

import QtQuick
import Quickshell

// Global shell UI state + persistent settings (survives `qs` reloads).
Singleton {
  id: root

  // ---------------------------------------------------------------------
  // Persisted settings
  // ---------------------------------------------------------------------
  PersistentProperties {
    id: persist
    reloadableId: "quickshell-shell-state"

    property bool dnd: false
  }

  property alias dnd: persist.dnd

  // ---------------------------------------------------------------------
  // Pill modes — the pill is the single host for every pane.
  // ---------------------------------------------------------------------
  property string launcherPage: "apps" // apps | clipboard
  property string centerView: "main" // main | wifi | bluetooth
  property string centerSection: "" // system | display | power | audio | calendar — deep-link target
  property string islandMode: "" // "" | "controls" | "launcher" | "picker" | "session" | "keys" | "osd" | "calendar"

  function closeAllPopups() {
    centerSection = "";
    centerView = "main";
    islandMode = "";
  }

  // Wallpaper picker (Super+T). `tab` is accepted for IPC compat and
  // ignored — there is only the wallpapers view; the theme follows the
  // wallpaper automatically.
  function togglePicker(tab) {
    if (islandMode === "picker") {
      islandMode = "";
      return;
    }
    closeAllPopups();
    islandMode = "picker";
  }

  // Toggle the launcher pill pane. `apps` (default) or `clipboard`;
  // the legacy themes/wallpapers pages now live in the slide-down picker
  // instead. Re-selecting the open page collapses the pill.
  function toggleLauncher(page) {
    let wantPage = (page !== undefined && page !== "") ? page : "apps";
    if (wantPage === "themes" || wantPage === "wallpapers") {
      togglePicker(wantPage);
      return;
    }
    if (wantPage !== "clipboard")
      wantPage = "apps";
    if (islandMode === "launcher" && launcherPage === wantPage) {
      islandMode = "";
      return;
    }
    closeAllPopups();
    launcherPage = wantPage;
    islandMode = "launcher";
  }

  function toggleSession() {
    if (islandMode === "session") {
      islandMode = "";
      return;
    }
    closeAllPopups();
    islandMode = "session";
  }

  function toggleCenter() {
    if (islandMode === "controls" && centerView === "main") {
      islandMode = "";
      return;
    }
    closeAllPopups();
    centerView = "main";
    islandMode = "controls";
  }

  // Toggle the pill calendar pane. Re-selecting collapses.
  function toggleCalendar() {
    if (islandMode === "calendar") {
      islandMode = "";
      return;
    }
    closeAllPopups();
    islandMode = "calendar";
  }

  // Open the pill control pane on a specific view (main | wifi |
  // bluetooth). Re-selecting the open view collapses the pill.
  function openCenterView(view) {
    const want = (view === "wifi" || view === "bluetooth") ? view : "main";
    if (islandMode === "controls" && centerView === want) {
      islandMode = "";
      return;
    }
    closeAllPopups();
    centerView = want;
    islandMode = "controls";
  }

  // Open the pill control pane on the main view for the given section
  // (system | display | power | audio | calendar). Pill shortcuts
  // deep-link through this instead of just popping the pane open.
  // Re-selecting the open section collapses the pill.
  function openCenterSection(section) {
    if (islandMode === "controls" && centerView === "main" && centerSection === section) {
      islandMode = "";
      return;
    }
    closeAllPopups();
    centerView = "main";
    centerSection = section;
    islandMode = "controls";
  }

  // Esc/back inside the pill control pane: leave a sub-view, else close.
  function centerBack() {
    if (centerView !== "main") {
      centerView = "main";
      return;
    }
    islandMode = "";
  }

  function toggleCheatsheet() {
    if (islandMode === "keys") {
      islandMode = "";
      return;
    }
    closeAllPopups();
    islandMode = "keys";
  }

  // ---------------------------------------------------------------------
  // On-screen display
  // ---------------------------------------------------------------------
  property bool osdVisible: false
  property string osdKind: "volume" // volume | brightness | mic
  property real osdValue: 0         // 0..1
  property string osdText: ""

  Timer {
    id: osdTimer
    interval: 1600
    onTriggered: {
      root.osdVisible = false;
      if (root.islandMode === "osd")
        root.islandMode = "";
    }
  }

  function showOsd(kind, value, text) {
    osdKind = kind;
    osdValue = Math.max(0, Math.min(1, value));
    osdText = text !== undefined ? text : Math.round(value * 100) + "%";
    osdVisible = true;
    // OSD takes the pill only when it is free; never hijack an open pane.
    if (islandMode === "")
      islandMode = "osd";
    osdTimer.restart();
  }
}
