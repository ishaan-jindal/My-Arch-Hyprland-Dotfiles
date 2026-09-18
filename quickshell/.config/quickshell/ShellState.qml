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
  // Popup visibility
  // ---------------------------------------------------------------------
  property bool launcherOpen: false
  property string launcherPage: "apps"
  property bool sessionOpen: false
  property bool centerOpen: false
  property string centerView: "main" // main | wifi | bluetooth
  property string centerSection: "" // system | display | power | audio | calendar — deep-link target
  property bool cheatsheetOpen: false
  property bool pickerOpen: false
  property string pickerTab: "wallpapers" // wallpapers only; kept for IPC compat

  function closeAllPopups() {
    launcherOpen = false;
    sessionOpen = false;
    centerOpen = false;
    centerSection = "";
    cheatsheetOpen = false;
    pickerOpen = false;
    centerView = "main";
  }

  // Wallpaper picker (slide-down). `tab` is accepted for IPC compat and
  // ignored — there is only the wallpapers view; the theme follows the
  // wallpaper automatically.
  function togglePicker(tab) {
    if (pickerOpen) {
      pickerOpen = false;
      return;
    }
    pickerTab = "wallpapers";
    launcherOpen = false;
    sessionOpen = false;
    centerOpen = false;
    cheatsheetOpen = false;
    pickerOpen = true;
  }

  // Toggle the launcher. `apps` (default) or `clipboard`; the legacy
  // themes/wallpapers pages now live in the slide-down picker instead.
  function toggleLauncher(page) {
    let wantPage = (page !== undefined && page !== "") ? page : "apps";
    if (wantPage === "themes" || wantPage === "wallpapers") {
      togglePicker(wantPage);
      return;
    }
    if (wantPage !== "clipboard")
      wantPage = "apps";
    if (launcherOpen) {
      // already open on another page -> switch page, stay open
      if (launcherPage !== wantPage) {
        launcherPage = wantPage;
        sessionOpen = false;
        centerOpen = false;
        return;
      }
      launcherOpen = false;
      return;
    }
    launcherPage = wantPage;
    sessionOpen = false;
    centerOpen = false;
    launcherOpen = true;
  }

  function toggleSession() {
    const wasOpen = sessionOpen;
    closeAllPopups();
    if (!wasOpen)
      sessionOpen = true;
  }

  function toggleCenter() {
    const wasOpen = centerOpen;
    closeAllPopups();
    if (!wasOpen) {
      centerView = "main";
      centerOpen = true;
    }
  }

  // Open the control centre on a specific view (main | wifi | bluetooth).
  function openCenterView(view) {
    closeAllPopups();
    centerView = (view === "wifi" || view === "bluetooth") ? view : "main";
    centerOpen = true;
  }

  // Open the control centre on the main view, scrolled to + highlighting the
  // given section (system | display | power | audio | calendar). Bar widgets
  // deep-link through this instead of just popping the panel open.
  function openCenterSection(section) {
    closeAllPopups();
    centerView = "main";
    centerSection = section;
    centerOpen = true;
  }

  // Esc inside the control centre: leave a sub-view, else close.
  function centerBack() {
    if (centerView !== "main") {
      centerView = "main";
      return;
    }
    centerOpen = false;
  }

  function toggleCheatsheet() {
    const wasOpen = cheatsheetOpen;
    closeAllPopups();
    if (!wasOpen)
      cheatsheetOpen = true;
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
    onTriggered: root.osdVisible = false
  }

  function showOsd(kind, value, text) {
    osdKind = kind;
    osdValue = Math.max(0, Math.min(1, value));
    osdText = text !== undefined ? text : Math.round(value * 100) + "%";
    osdVisible = true;
    osdTimer.restart();
  }
}
