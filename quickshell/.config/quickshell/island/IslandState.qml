pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Notifications
import ".."
import "../services" as Svc

// Dynamic Island state brain, bound to the services/Config contract.
//
// UI (island/Island.qml) reads ONLY this singleton (+ IslandTheme).
//
// Contract covered:
//   Media{hasPlayer,isPlaying,title,artist,artUrl,position,length,
//     positionSupported,canSeek,canGoNext,canGoPrevious,playerLabel,
//     playerCount,togglePlaying(),next(),previous(),seekTo(x),cyclePlayer()}
//   Audio{volume,muted,setVolume(v),toggleMute()}
//   Brightness{level,available,setLevel(v)}
//   Battery{percent,charging,available}
//   Network{wifiEnabled,ssid,toggleWifi()}
//   Bluetooth{enabled,toggleEnabled()}
//   Workspaces{activeId,ids,switchTo(id)}
//   Notifs{dnd,toggleDnd()}
//   Config{reduceMotion,enableNotifications,showOnAllMonitors,
//     autoDismissMs,notifDismissMs}
Singleton {
  id: state

  // ---------------------------------------------------------------
  // Config (live singleton)
  // ---------------------------------------------------------------
  readonly property bool reduceMotion: Config.reduceMotion
  readonly property bool enableNotifications: Config.enableNotifications
  readonly property bool showOnAllMonitors: Config.showOnAllMonitors
  readonly property int autoDismissMs: Config.autoDismissMs
  readonly property int notifDismissMs: Config.notifDismissMs

  // ---------------------------------------------------------------
  // Clock (minute precision — no per-second timer while idle)
  // ---------------------------------------------------------------
  SystemClock {
    id: wallClock
    precision: SystemClock.Minutes
  }
  readonly property string timeText: wallClock.date ? Qt.formatDateTime(wallClock.date, "HH:mm") : ""
  readonly property string dateText: wallClock.date ? Qt.formatDateTime(wallClock.date, "ddd d MMM") : ""
  readonly property string fullDate: wallClock.date ? Qt.formatDateTime(wallClock.date, "dddd, d MMMM") : ""

  // ---------------------------------------------------------------
  // Media (live services/Media facade over Mpris)
  // ---------------------------------------------------------------
  readonly property var players: Svc.Media.players
  readonly property int playerCount: players ? players.length : 0
  readonly property var player: Svc.Media.player
  readonly property int playerPos: {
    const ps = state.players;
    const p = state.player;
    if (!ps || !p)
      return 0;
    return ps.indexOf(p) + 1;
  }

  readonly property bool demoMedia: state.demoKind === "media" || state.demoKind === "activity"
  readonly property bool hasPlayer: state.demoMedia ? true : Svc.Media.hasPlayer
  readonly property bool isPlaying: state.demoMedia ? !state.demoPaused : Svc.Media.isPlaying

  readonly property string title: state.demoMedia ? "Midnight City" : Svc.Media.title
  readonly property string artist: state.demoMedia ? "M83" : Svc.Media.artist
  readonly property string artUrl: state.demoMedia ? "" : Svc.Media.artUrl
  readonly property string playerLabel: state.demoMedia ? "Demo" : Svc.Media.playerLabel

  readonly property real length: state.demoMedia ? 243 : Svc.Media.length
  // Length may be 0 while positionSupported is true — every division
  // of position/length is guarded at the call site.
  readonly property bool positionSupported: state.demoMedia ? true : Svc.Media.positionSupported
  readonly property bool canSeek: state.demoMedia ? true : Svc.Media.canSeek
  readonly property bool canGoNext: state.demoMedia ? true : Svc.Media.canGoNext
  readonly property bool canGoPrevious: state.demoMedia ? true : Svc.Media.canGoPrevious

  function togglePlaying() {
    if (state.demoMedia) {
      state.demoPaused = !state.demoPaused;
      return;
    }
    Svc.Media.togglePlaying();
  }

  function next() {
    if (state.demoMedia)
      return;
    Svc.Media.next();
  }

  function previous() {
    if (state.demoMedia)
      return;
    Svc.Media.previous();
  }

  function cyclePlayer() {
    if (state.demoMedia)
      return;
    Svc.Media.cyclePlayer();
    state.markPos();
  }

  // Seek position: Mpris position does not tick on its own, so the UI
  // advances a local base between reads (1s ticker, media face only).
  property real posBase: 0
  property double posStamp: 0
  property real shownPos: 0

  function markPos() {
    state.posBase = state.demoMedia ? state.demoPos : Svc.Media.position;
    state.posStamp = Date.now();
    state.shownPos = state.posBase;
  }

  function tickSeek() {
    if (state.demoMedia) {
      state.demoPos = Math.min(243, state.demoPos + 1);
      state.shownPos = state.demoPos;
      return;
    }
    if (!state.isPlaying || state.length <= 0)
      return;
    state.shownPos = Math.min(state.length, state.posBase + (Date.now() - state.posStamp) / 1000);
  }

  function seekTo(x) {
    const v = Math.max(0, Math.min(state.length, x));
    // Hard API fact: no setPosition() — the facade assigns position.
    // The write is async: track the target locally, don't re-read.
    if (state.demoMedia) {
      state.demoPos = v;
      state.markPos();
    } else {
      Svc.Media.seekTo(v);
      state.posBase = v;
      state.posStamp = Date.now();
      state.shownPos = v;
    }
  }

  function fmtDur(secs) {
    const s = Math.max(0, Math.floor(secs));
    return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
  }

  onIsPlayingChanged: state.markPos()
  onPlayerChanged: state.markPos()

  // Server-side position jumps (track change, remote seek) rebase the
  // local ticker. Null target is fine — Connections stays inactive.
  Connections {
    target: Svc.Media.player
    function onPositionChanged() {
      state.markPos();
    }
  }

  // ---------------------------------------------------------------
  // Audio / Brightness / Battery (live services facades over Sys)
  // ---------------------------------------------------------------
  readonly property real volume: Svc.Audio.volume
  readonly property bool muted: Svc.Audio.muted

  function setVolume(v) {
    Svc.Audio.setVolume(Math.max(0, Math.min(1, v)));
  }
  function nudgeVolume(d) {
    state.setVolume(state.volume + d);
  }
  function toggleMute() {
    Svc.Audio.toggleMute();
  }

  readonly property real level: Svc.Brightness.level
  readonly property bool levelAvailable: Svc.Brightness.available

  function setLevel(v) {
    Svc.Brightness.setLevel(Math.max(0, Math.min(1, v)));
  }
  function nudgeLevel(d) {
    state.setLevel(state.level + d);
  }

  readonly property int percent: Svc.Battery.percent
  readonly property bool charging: Svc.Battery.charging
  readonly property bool battAvailable: Svc.Battery.available
  readonly property string battTimeText: Svc.Battery.timeText
  readonly property int battLevel: Math.max(0, Math.min(10, Math.floor(state.percent / 10)))
  readonly property string battGlyph: state.charging ? Icons.battCharging : Icons.battery[state.battLevel]
  readonly property string volGlyph: state.muted ? Icons.audioMuted
    : state.volume < 0.34 ? Icons.volLow : state.volume < 0.67 ? Icons.volMid : Icons.volHigh

  // OSD toast icon/label (same derivation as the legacy OsdBody).
  function osdIcon() {
    if (ShellState.osdKind === "brightness") {
      const idx = Math.max(0, Math.min(Icons.brightness.length - 1,
        Math.floor(ShellState.osdValue * Icons.brightness.length - 0.0001)));
      return Icons.brightness[idx];
    }
    if (ShellState.osdKind === "mic")
      return ShellState.osdValue <= 0.001 ? Icons.micOff : Icons.mic;
    return state.volGlyph;
  }

  function osdLabel() {
    if (ShellState.osdKind === "brightness")
      return "Brightness  " + ShellState.osdText;
    if (ShellState.osdKind === "mic")
      return ShellState.osdText;
    return ShellState.osdText === "Muted" ? "Muted" : "Volume  " + ShellState.osdText;
  }

  // ---------------------------------------------------------------
  // Network / Bluetooth (live services facades)
  // ---------------------------------------------------------------
  readonly property bool wifiEnabled: Svc.Network.wifiEnabled
  readonly property string ssid: Svc.Network.ssid

  function toggleWifi() {
    Svc.Network.toggleWifi();
  }

  readonly property bool btEnabled: Svc.Bluetooth.enabled

  // Connected device name for the toggle sublabel ("" when none).
  readonly property string btDevice: {
    const a = Svc.Bluetooth.adapter;
    if (!a || !a.devices)
      return "";
    const ds = a.devices.values;
    for (let i = 0; i < ds.length; i++)
      if (ds[i] && ds[i].connected)
        return ds[i].name || "";
    return "";
  }

  function toggleBluetooth() {
    Svc.Bluetooth.toggleEnabled();
  }

  // ---------------------------------------------------------------
  // Workspaces (live services facade; dispatch uses the Lua form
  // this Hyprland build requires)
  // ---------------------------------------------------------------
  readonly property var wsIds: Svc.Workspaces.ids

  function switchWs(id) {
    Svc.Workspaces.switchTo(id);
  }

  // ---------------------------------------------------------------
  // Notifs (live services facade over Notify + ShellState.dnd)
  // ---------------------------------------------------------------
  readonly property bool dnd: Svc.Notifs.dnd

  function toggleDnd() {
    Svc.Notifs.toggleDnd();
  }

  // ---------------------------------------------------------------
  // Merged hub (SUPER+C control centre): sub-view, live stats, actions
  // ---------------------------------------------------------------
  property string hubView: "" // "" | "wifi" | "bluetooth"

  // CPU/RAM/temp reuse Sys's already-running pollers — no new pollers.
  readonly property int cpuPct: Math.round(Sys.cpu)
  readonly property int memPct: Sys.memPct
  readonly property string memStr: Sys.memUsed.toFixed(1) + " / " + Sys.memTotal.toFixed(1) + " GB"
  readonly property int tempC: Math.round(Sys.temp)

  // One-shot reads, refreshed every time the hub opens.
  property string uptimeStr: ""
  property int diskPct: 0
  property string diskStr: ""
  property string cpuGhz: ""
  property string fanStr: ""
  property string kbLayout: ""
  property string netStr: "↓ —  ↑ —"
  property double prevRx: -1
  property double prevTx: -1
  property double prevNetT: 0

  function setHubView(v) {
    const want = (v === "wifi" || v === "bluetooth") ? v : "";
    state.hubView = want;
    // WifiPanel/BluetoothPanel gate keyboard on ShellState.centerView.
    if (ShellState.centerView !== (want === "" ? "main" : want))
      ShellState.centerView = want === "" ? "main" : want;
  }

  function openHub(view) {
    if (state.legacyActive)
      ShellState.closeAllPopups();
    state.demoKind = "";
    state.clearToast();
    state.setHubView(view || "");
    state.userFace = "hub";
    state.markPos();
    state.refreshHubStats();
  }

  function toggleHub() {
    if (state.userFace === "hub" && state.hubView === "")
      state.hide();
    else
      state.openHub("");
  }

  // Hub quick actions — every binary below was verified on this box.
  function shotScreen() {
    Quickshell.execDetached({
      command: ["hyprshot", "-m", "region", "-o", Quickshell.env("HOME") + "/Pictures/"]
    });
  }

  function toggleRecord() {
    Quickshell.execDetached({
      command: ["sh", "-c", "if pgrep -x gpu-screen-recorder >/dev/null; then pkill -x gpu-screen-recorder; else gpu-screen-recorder -w screen -f \"$HOME/Videos/rec_$(date +%Y%m%d-%H%M%S).mp4\" >/dev/null 2>&1 & fi"]
    });
  }

  function pickColor() {
    Quickshell.execDetached({ command: ["hyprpicker", "-a"] });
  }

  function toggleNight() {
    Theme.toggleNightLight();
  }

  function lockScreen() {
    Quickshell.execDetached({ command: ["hyprlock"] });
  }

  function suspendNow() {
    Quickshell.execDetached({ command: ["systemctl", "suspend"] });
  }

  function openSession() {
    ShellState.toggleSession();
  }

  function refreshHubStats() {
    uptimeProc.running = true;
    diskProc.running = true;
    ghzProc.running = true;
    fanProc.running = true;
    kbProc.running = true;
  }

  function pollNet() {
    if (!netProc.running)
      netProc.running = true;
  }

  function fmtRate(bps) {
    if (bps >= 1000000)
      return (bps / 1000000).toFixed(1) + "M";
    if (bps >= 1000)
      return Math.round(bps / 1000) + "K";
    return Math.round(bps) + "B";
  }

  function parseUptime(text) {
    const secs = Math.floor(Number(String(text).trim().split(/\s+/)[0]) || 0);
    const h = Math.floor(secs / 3600), m = Math.floor((secs % 3600) / 60);
    state.uptimeStr = h > 0 ? "Up " + h + "h " + m + "m" : "Up " + m + "m";
  }

  function parseDisk(text) {
    const f = String(text).trim().split(/\s+/);
    if (f.length < 3)
      return;
    state.diskStr = f[1].replace(/G$/, "") + " / " + f[0].replace(/G$/, "") + " GB";
    const p = parseInt(f[2]);
    if (!isNaN(p))
      state.diskPct = Math.max(0, Math.min(100, p));
  }

  function parseNetDev(text) {
    let rx = 0, tx = 0;
    const lines = String(text).split("\n");
    for (let i = 0; i < lines.length; i++) {
      const m = lines[i].match(/^\s*([^:]+):\s*(.*)$/);
      if (!m || m[1] === "lo")
        continue;
      const f = m[2].trim().split(/\s+/);
      if (f.length < 9)
        continue;
      rx += Number(f[0]) || 0;
      tx += Number(f[8]) || 0;
    }
    const now = Date.now();
    if (state.prevRx >= 0 && now > state.prevNetT) {
      const dt = (now - state.prevNetT) / 1000;
      state.netStr = "↓ " + state.fmtRate((rx - state.prevRx) / dt)
        + "  ↑ " + state.fmtRate((tx - state.prevTx) / dt);
    }
    state.prevRx = rx;
    state.prevTx = tx;
    state.prevNetT = now;
  }

  function parseKb(text) {
    try {
      const o = JSON.parse(text);
      const kbs = o.keyboards || [];
      let kb = null;
      for (let i = 0; i < kbs.length; i++)
        if (kbs[i].main) {
          kb = kbs[i];
          break;
        }
      if (!kb && kbs.length > 0)
        kb = kbs[0];
      const layout = kb ? (kb.active_keymap || "") : "";
      const m = String(layout).match(/\(([^)]+)\)/);
      state.kbLayout = m ? m[1] : "";
    } catch (e) {
      state.kbLayout = "";
    }
  }

  // One-shot collectors: fire on hub open only, never poll.
  Process {
    id: uptimeProc
    command: ["cat", "/proc/uptime"]
    stdout: StdioCollector {
      onStreamFinished: state.parseUptime(this.text)
    }
  }

  Process {
    id: diskProc
    command: ["sh", "-c", "df -B1G / | awk 'NR==2{print $2, $3, $5}'"]
    stdout: StdioCollector {
      onStreamFinished: state.parseDisk(this.text)
    }
  }

  Process {
    id: ghzProc
    command: ["sh", "-c", "cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null || true"]
    stdout: StdioCollector {
      onStreamFinished: {
        const khz = Number(String(this.text).trim()) || 0;
        state.cpuGhz = khz > 0 ? (khz / 1000000).toFixed(1) + " GHz" : "";
      }
    }
  }

  Process {
    id: fanProc
    command: ["sh", "-c", "for f in /sys/class/hwmon/hwmon*/fan*_input; do [ -r \"$f\" ] && { cat \"$f\"; break; }; done 2>/dev/null || true"]
    stdout: StdioCollector {
      onStreamFinished: {
        const rpm = parseInt(String(this.text).trim());
        state.fanStr = !isNaN(rpm) && rpm > 0 ? rpm + " rpm" : "";
      }
    }
  }

  Process {
    id: kbProc
    command: ["hyprctl", "devices", "-j"]
    stdout: StdioCollector {
      onStreamFinished: state.parseKb(this.text)
    }
  }

  Process {
    id: netProc
    command: ["cat", "/proc/net/dev"]
    stdout: StdioCollector {
      onStreamFinished: state.parseNetDev(this.text)
    }
  }
  // ---------------------------------------------------------------
  // Toast + notification state
  // ---------------------------------------------------------------
  property string userFace: ""   // "" | "hub" | "media"

  property bool wsToastActive: false

  Timer {
    id: wsToastTimer
    interval: state.autoDismissMs
    onTriggered: state.wsToastActive = false
  }

  function clearToast() {
    wsToastTimer.stop();
    state.wsToastActive = false;
  }

  // Workspace switch raises a transient ws-dot toast (no cheap
  // sources exist for caps-lock or recording — those are skipped).
  Connections {
    target: Hyprland
    function onFocusedWorkspaceChanged() {
      if (state.demoKind !== "")
        return;
      state.wsToastActive = true;
      wsToastTimer.restart();
    }
  }

  readonly property var latestNotif: Svc.Notifs.popup

  // Demo notification (demo("notification") / demo("urgent")).
  readonly property var demoNotifObj: ({
    appName: "Messages",
    summary: "Ava Thompson",
    body: "Running late — start without me, I'll join at 7.",
    urgency: state.demoKind === "urgent" ? 2 : 1,
    demo: true
  })

  // Live notifications render in the top-right popup stack, never in
  // the island (no double-display). Demo path stays for testing.
  readonly property var notifToShow: (state.demoKind === "notification" || state.demoKind === "urgent")
    ? state.demoNotifObj : null

  readonly property bool notifUrgent: {
    const n = state.notifToShow;
    if (!n)
      return false;
    return n.urgency === NotificationUrgency.Critical || n.urgency === 2;
  }

  function notifLifeMs(n) {
    if (!n)
      return 0;
    if (n.expireTimeout === 0)
      return 0; // 0 means never — persistent notifications stay
    if (n.expireTimeout > 0)
      return n.expireTimeout;
    if (state.notifUrgent)
      return 0; // urgent red: no auto-dismiss
    return state.notifDismissMs;
  }

  property int notifRemaining: 0
  property double notifStamp: 0
  property bool notifHover: false

  onNotifToShowChanged: state.armNotif()

  function armNotif() {
    notifTimer.stop();
    const n = state.notifToShow;
    if (!n)
      return;
    const life = state.notifLifeMs(n);
    if (life <= 0)
      return;
    state.notifRemaining = life;
    state.notifStamp = Date.now();
    if (state.notifHover)
      return; // hovered: hold the full life, the resume path restarts
    notifTimer.interval = life;
    notifTimer.start();
  }

  Timer {
    id: notifTimer
    onTriggered: {
      const n = state.notifToShow;
      if (n && !n.demo) {
        Notify.untrack(n);
        n.expire();
      } else if (n && n.demo) {
        state.demoKind = "";
      }
    }
  }

  // Hover pauses the auto-dismiss clock (deadline bookkeeping, no restart).
  onNotifHoverChanged: {
    if (!state.notifToShow || state.notifUrgent)
      return;
    if (state.notifHover) {
      state.notifRemaining = Math.max(1, Math.round(state.notifRemaining - (Date.now() - state.notifStamp)));
      notifTimer.stop();
    } else {
      state.notifStamp = Date.now();
      notifTimer.interval = state.notifRemaining;
      notifTimer.start();
    }
  }

  // Click = default action, then dismiss (mirrors the popup stack).
  function notifActivate() {
    const n = state.notifToShow;
    if (!n)
      return;
    if (n.demo) {
      state.demoKind = "";
      return;
    }
    const acts = n.actions || [];
    for (let i = 0; i < acts.length; i++) {
      if (acts[i] && acts[i].identifier === "default") {
        try {
          acts[i].invoke();
        } catch (e) {}
        Notify.untrack(n);
        return;
      }
    }
    Notify.dismiss(n);
  }

  function notifClose() {
    const n = state.notifToShow;
    if (!n)
      return;
    if (n.demo)
      state.demoKind = "";
    else
      Notify.dismiss(n);
  }

  // ---------------------------------------------------------------
  // Display priority + expansion
  // ---------------------------------------------------------------
  readonly property var legacyModes: ["controls", "launcher", "picker", "session", "keys", "calendar"]
  readonly property bool legacyActive: state.legacyModes.indexOf(ShellState.islandMode) !== -1
  readonly property string legacyMode: state.legacyActive ? ShellState.islandMode : ""
  readonly property bool osdMode: ShellState.islandMode === "osd"

  // notification > toast > user-expanded > idle. Media never
  // auto-shows (no now-playing indicator): the clock stays put while
  // music plays; media lives in the user-opened hub/media views.
  // A legacy pane always wins (user intent); a toast never preempts
  // a user-expanded view; a notification does.
  readonly property string display: {
    if (state.legacyActive)
      return "legacy";
    if (state.demoKind !== "")
      return "demo:" + state.demoKind;
    if (state.notifToShow)
      return "notification";
    if (state.userFace !== "")
      return state.userFace;
    if (ShellState.osdVisible || state.wsToastActive)
      return "toast";
    return "idle";
  }

  // Only a truly expanded face holds the grab/focus: a notification
  // preempting the hub must not leave grab + Exclusive on nothing.
  readonly property bool expanded: state.legacyActive
    || state.display === "hub" || state.display === "media"

  function collapse() {
    state.userFace = "";
    state.hubView = "";
    state.demoKind = "";
    state.clearToast();
    if (ShellState.islandMode !== "")
      ShellState.closeAllPopups();
  }

  // Left click always opens the hub — never the media view.
  function toggleView() {
    if (state.userFace !== "" || state.legacyActive) {
      state.collapse();
      return;
    }
    if (state.demoKind !== "")
      state.demoKind = "";
    state.clearToast();
    if (ShellState.islandMode !== "")
      ShellState.closeAllPopups();
    state.userFace = "hub";
    state.markPos();
  }

  // ---------------------------------------------------------------
  // Demo (fake data, auto-clears after 6s)
  // ---------------------------------------------------------------
  property string demoKind: "" // idle|activity|toast|notification|urgent|media|hub
  property bool demoPaused: false
  property real demoPos: 87

  Timer {
    id: demoTimer
    interval: 6000
    onTriggered: state.demoKind = ""
  }

  function demo(kind) {
    const k = (kind || "").toLowerCase();
    if (["idle", "activity", "toast", "notification", "urgent", "media", "hub"].indexOf(k) === -1)
      return;
    state.userFace = "";
    if (ShellState.islandMode !== "")
      ShellState.closeAllPopups();
    state.demoKind = k;
    state.demoPaused = false;
    state.demoPos = 87;
    state.markPos();
    state.armNotif();
    demoTimer.restart();
  }

  // ---------------------------------------------------------------
  // IPC entry points (qs ipc call island …)
  // ---------------------------------------------------------------
  function toggle() {
    if (state.expanded || state.legacyActive) {
      state.collapse();
      return;
    }
    state.openHub("");
  }

  function show(s) {
    const k = (s || "").toLowerCase();
    if (k === "hub") {
      state.openHub("");
    } else if (k === "media") {
      if (ShellState.islandMode !== "")
        ShellState.closeAllPopups();
      state.demoKind = "";
      state.userFace = k;
      state.markPos();
    } else {
      // idle/activity/toast/notification: release overrides and let
      // the live state show through.
      state.userFace = "";
      state.demoKind = "";
    }
  }

  function hide() {
    const n = state.notifToShow;
    state.userFace = "";
    state.hubView = "";
    state.demoKind = "";
    state.clearToast();
    if (n && !n.demo)
      Notify.dismiss(n);
    if (ShellState.islandMode !== "")
      ShellState.closeAllPopups();
  }
}
