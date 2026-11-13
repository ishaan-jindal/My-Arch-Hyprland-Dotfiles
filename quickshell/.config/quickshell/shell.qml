import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Networking
import Quickshell.Bluetooth
import "components"
import "popups"
import "island" as Isle

// Quickshell entry point. See docs/QUICKSHELL.md.
ShellRoot {
  Bar {}
  NotificationPopups {}

  IpcHandler {
    target: "shell"

    // qs ipc call shell toggleLauncher  (always the app launcher)
    function toggleLauncher(): void {
      ShellState.toggleLauncher("");
    }

    // qs ipc call shell openLauncher clipboard
    function openLauncher(page: string): void {
      ShellState.toggleLauncher(page);
    }

    // qs ipc call shell openPicker wallpapers (tab arg kept for compat)
    function openPicker(tab: string): void {
      ShellState.togglePicker(tab);
    }

    // qs ipc call shell toggleSession
    function toggleSession(): void {
      ShellState.toggleSession();
    }

    // qs ipc call shell toggleCenter — merged island hub (SUPER+C)
    function toggleCenter(): void {
      Isle.IslandState.toggleHub();
    }

    // qs ipc call shell toggleCalendar
    function toggleCalendar(): void {
      ShellState.toggleCalendar();
    }

    // qs ipc call shell openCenterView wifi — hub wifi list (or hub)
    function openCenterView(view: string): void {
      Isle.IslandState.openHub(view);
    }

    // qs ipc call shell openCenterSection audio — merged hub (sections merged)
    function openCenterSection(section: string): void {
      Isle.IslandState.openHub("");
    }

    // qs ipc call shell closeAll
    function closeAll(): void {
      ShellState.closeAllPopups();
    }

    // qs ipc call shell toggleDnd
    function toggleDnd(): void {
      ShellState.dnd = !ShellState.dnd;
    }

    // qs ipc call shell toggleKeybinds
    function toggleKeybinds(): void {
      ShellState.toggleCheatsheet();
    }

    // qs ipc call shell diagnostics
    function diagnostics(): string {
      return JSON.stringify({
        accent: Theme.palette.accent,
        bg: Theme.palette.bg,
        wallpaper: Theme.currentWallpaper,
        wallpaperCount: Theme.walls.length,
        screens: Quickshell.screens.length,
        workspaces: Hyprland.workspaces.values.length,
        cpu: Sys.cpu,
        memPct: Sys.memPct,
        temp: Sys.temp,
        brightness: Sys.brightness,
        powerProfile: Sys.powerProfile,
        nightLight: Sys.nightLight,
        sink: Sys.sinkName,
        volume: Math.round(Sys.volume * 100),
        muted: Sys.muted,
        sourceMuted: Sys.sourceMuted,
        hasBattery: Sys.hasBattery,
        batteryPct: Sys.batteryPct,
        trayItems: SystemTray.items.values.length,
        notifications: Notify.tracked.length,
        popups: Notify.popups.length,
        dnd: ShellState.dnd,
        islandMode: ShellState.islandMode,
        launcherPage: ShellState.launcherPage,
        currentWallpaper: Theme.currentWallpaper,
        centerView: ShellState.centerView,
        centerSection: ShellState.centerSection,
        wifiEnabled: Networking.wifiEnabled,
        wifiNetworks: (() => {
          const devs = Networking.devices.values;
          for (let i = 0; i < devs.length; i++)
            if (devs[i].type === DeviceType.Wifi)
              return devs[i].networks ? devs[i].networks.values.length : 0;
          return 0;
        })(),
        btAdapter: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.name : "",
        btDevices: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.devices.values.length : 0
      });
    }

    // qs ipc call shell showOsd volume 0.42
    function showOsd(kind: string, value: real): void {
      ShellState.showOsd(kind, value, Math.round(value * 100) + "%");
    }
  }

  IpcHandler {
    target: "island"

    // qs ipc call island toggle  (collapse, or open the hub)
    function toggle(): void {
      Isle.IslandState.toggle();
    }

    // qs ipc call island open hub  (hub | media force open; anything
    // else releases overrides and lets the live state show through)
    function open(state: string): void {
      Isle.IslandState.open(state);
    }

    // qs ipc call island hide  (back to idle, dismissing overlays)
    function hide(): void {
      Isle.IslandState.hide();
    }

    // qs ipc call island demo notification  (idle | activity | toast |
    // notification | urgent | media | hub — fake data, auto-clears)
    function demo(state: string): void {
      Isle.IslandState.demo(state);
    }
  }
}
