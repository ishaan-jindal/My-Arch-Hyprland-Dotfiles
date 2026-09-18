pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

// Centralised system state polling + native service bindings.
//
// Everything is polled here exactly once and consumed by the bar widgets,
// so adding more widgets never multiplies process wakeups.
Singleton {
  id: root

  readonly property string home: Quickshell.env("HOME") || ""

  // ---------------------------------------------------------------------
  // CPU (delta of /proc/stat samples)
  // ---------------------------------------------------------------------
  property real cpu: 0
  property var lastCpuSample: null

  Process {
    id: cpuProc
    command: ["cat", "/proc/stat"]

    stdout: StdioCollector {
      onStreamFinished: root.updateCpu(this.text)
    }
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: cpuProc.running = true
  }

  function updateCpu(text) {
    const fields = text.split("\n")[0].trim().split(/\s+/);
    if (fields[0] !== "cpu")
      return;
    let total = 0;
    for (let i = 1; i < fields.length; i++)
      total += Number(fields[i]);
    const idle = Number(fields[4]) + Number(fields[5]);
    if (lastCpuSample && total > lastCpuSample.total) {
      const dTotal = total - lastCpuSample.total;
      const dIdle = idle - lastCpuSample.idle;
      cpu = Math.max(0, Math.min(100, Math.round(100 * (1 - dIdle / dTotal))));
    }
    lastCpuSample = { total: total, idle: idle };
  }

  // ---------------------------------------------------------------------
  // Memory (/proc/meminfo)
  // ---------------------------------------------------------------------
  property real memUsed: 0   // GiB
  property real memTotal: 0  // GiB
  property int memPct: 0

  Process {
    id: memProc
    command: ["cat", "/proc/meminfo"]

    stdout: StdioCollector {
      onStreamFinished: root.updateMem(this.text)
    }
  }

  Timer {
    interval: 3000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: memProc.running = true
  }

  function updateMem(text) {
    let total = 0;
    let available = 0;
    const lines = text.split("\n");
    for (let i = 0; i < lines.length; i++) {
      const m = lines[i].match(/^(\w+):\s+(\d+)/);
      if (!m)
        continue;
      if (m[1] === "MemTotal")
        total = Number(m[2]);
      else if (m[1] === "MemAvailable")
        available = Number(m[2]);
    }
    if (total <= 0)
      return;
    memTotal = total / 1048576;
    memUsed = (total - available) / 1048576;
    memPct = Math.round(100 * (total - available) / total);
  }

  // ---------------------------------------------------------------------
  // Temperature (hottest hwmon sensor, °C)
  // ---------------------------------------------------------------------
  property real temp: 0

  Process {
    id: tempProc
    command: [
      "sh", "-c",
      "best=0; for f in /sys/class/hwmon/hwmon*/temp*_input; do " +
      "[ -r \"$f\" ] || continue; v=$(cat \"$f\" 2>/dev/null) || continue; " +
      "case \"$v\" in ''|*[!0-9]*) continue;; esac; " +
      "[ \"$v\" -gt \"$best\" ] && best=$v; done; " +
      "awk -v v=\"$best\" 'BEGIN{printf \"%.1f\", v/1000}'"
    ]

    stdout: StdioCollector {
      onStreamFinished: root.temp = Number(this.text) || 0
    }
  }

  Timer {
    interval: 4000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: tempProc.running = true
  }

  // ---------------------------------------------------------------------
  // Backlight (brightnessctl, mirrors the Waybar backlight module)
  // ---------------------------------------------------------------------
  property int brightness: 0 // 0..100

  Process {
    id: brightProc
    command: ["brightnessctl", "-m"]

    stdout: StdioCollector {
      onStreamFinished: {
        const line = this.text.trim().split("\n")[0];
        const fields = line.split(",");
        if (fields.length >= 4) {
          const pct = parseInt(fields[3]);
          if (!isNaN(pct))
            root.brightness = Math.max(0, Math.min(100, pct));
        }
      }
    }
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: brightProc.running = true
  }

  function setBrightness(pct) {
    const target = Math.max(0, Math.min(100, Math.round(pct)));
    // Optimistic update so sliders react instantly; the poll confirms it.
    // NOTE: no -e (exponential) flag — it maps set% to a different raw value
    // than the linear readback, which made the UI disagree with hardware.
    brightness = target;
    Quickshell.execDetached({
      command: ["brightnessctl", "-n2", "set", target + "%"]
    });
    refreshTimer.restart();
  }

  // Confirms an optimistic setBrightness once the daemon has applied it,
  // instead of waiting for the next poll tick.
  Timer {
    id: refreshTimer
    interval: 250
    onTriggered: brightProc.running = true
  }

  // ---------------------------------------------------------------------
  // Power profile (power-profiles-daemon)
  // ---------------------------------------------------------------------
  property string powerProfile: "balanced"

  Process {
    id: profileProc
    command: ["powerprofilesctl", "get"]

    stdout: StdioCollector {
      onStreamFinished: root.powerProfile = this.text.trim() || "balanced"
    }
  }

  Timer {
    interval: 5000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: profileProc.running = true
  }

  function setPowerProfile(profile) {
    Quickshell.execDetached({ command: ["powerprofilesctl", "set", profile] });
  }

  // ---------------------------------------------------------------------
  // Night light (hyprsunset)
  // ---------------------------------------------------------------------
  property bool nightLight: false

  Process {
    id: nightProc
    command: ["sh", "-c", "pgrep -x hyprsunset >/dev/null && echo on || echo off"]

    stdout: StdioCollector {
      onStreamFinished: root.nightLight = this.text.trim() === "on"
    }
  }

  Timer {
    interval: 5000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: nightProc.running = true
  }

  // ---------------------------------------------------------------------
  // Audio (Pipewire)
  // ---------------------------------------------------------------------
  PwObjectTracker {
    objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
  }

  readonly property var sink: Pipewire.defaultAudioSink
  readonly property var source: Pipewire.defaultAudioSource

  readonly property var sinkAudio: sink && sink.audio ? sink.audio : null
  readonly property var sourceAudio: source && source.audio ? source.audio : null

  readonly property real volume: sinkAudio ? sinkAudio.volume : 0
  readonly property bool muted: sinkAudio ? sinkAudio.muted : false
  readonly property bool sourceMuted: sourceAudio ? sourceAudio.muted : false

  readonly property string sinkName: sink ? (sink.description || sink.name || "") : ""

  function setVolume(v) {
    if (sinkAudio)
      sinkAudio.volume = Math.max(0, Math.min(1, v));
  }

  function toggleMute() {
    if (sinkAudio)
      sinkAudio.muted = !sinkAudio.muted;
  }

  function toggleSourceMute() {
    if (sourceAudio)
      sourceAudio.muted = !sourceAudio.muted;
  }

  // ---------------------------------------------------------------------
  // Battery (UPower)
  // ---------------------------------------------------------------------
  readonly property var battery: UPower.displayDevice

  readonly property bool hasBattery: battery && battery.ready && battery.isLaptopBattery
  // Quickshell reports `percentage` as a 0..1 fraction; tolerate both scales.
  readonly property real batteryFraction: hasBattery
    ? (battery.percentage <= 1 ? battery.percentage : battery.percentage / 100)
    : 0
  readonly property int batteryPct: hasBattery ? Math.round(batteryFraction * 100) : 0
  readonly property bool batteryCharging: hasBattery
    && (battery.state === UPowerDeviceState.Charging
      || battery.state === UPowerDeviceState.PendingCharge
      || battery.state === UPowerDeviceState.FullyCharged)
  readonly property real batterySecondsLeft: hasBattery ? Math.max(0, battery.timeToEmpty) : 0
  readonly property real batterySecondsFull: hasBattery ? Math.max(0, battery.timeToFull) : 0

  function batteryTimeText() {
    if (!hasBattery)
      return "";
    if (batteryCharging) {
      if (batterySecondsFull <= 0)
        return "Full";
      return "Full in " + formatDuration(batterySecondsFull);
    }
    if (batterySecondsLeft <= 0)
      return "";
    return formatDuration(batterySecondsLeft) + " left";
  }

  function formatDuration(seconds) {
    const total = Math.round(seconds);
    const h = Math.floor(total / 3600);
    const m = Math.floor((total % 3600) / 60);
    if (h > 0)
      return h + "h " + m + "m";
    if (m > 0)
      return m + "m";
    return total + "s";
  }

  // ---------------------------------------------------------------------
  // OSD glue
  //
  // Volume/brightness/mute changes made anywhere (media keys, wpctl,
  // pavucontrol, this shell) raise the OSD, exactly like the old
  // notify-send feedback loop - but the *first* values after startup only
  // prime the state and never pop the OSD.
  // ---------------------------------------------------------------------
  property bool osdWarmup: false

  Timer {
    interval: 1500
    running: true
    onTriggered: root.osdWarmup = true
  }

  onVolumeChanged: {
    if (osdWarmup)
      ShellState.showOsd("volume", volume, muted ? "Muted" : Math.round(volume * 100) + "%");
  }

  onMutedChanged: {
    if (osdWarmup)
      ShellState.showOsd("volume", muted ? 0 : volume, muted ? "Muted" : Math.round(volume * 100) + "%");
  }

  onSourceMutedChanged: {
    if (osdWarmup)
      ShellState.showOsd("mic", sourceMuted ? 0 : 1, sourceMuted ? "Mic muted" : "Mic on");
  }

  property int lastOsdBrightness: -1

  onBrightnessChanged: {
    if (!osdWarmup)
      return;
    if (brightness === lastOsdBrightness)
      return;
    lastOsdBrightness = brightness;
    ShellState.showOsd("brightness", brightness / 100, brightness + "%");
  }
}
