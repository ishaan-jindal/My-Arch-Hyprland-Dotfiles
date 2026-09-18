import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Networking
import Quickshell.Bluetooth
import "components"
import "popups"

// Quickshell entry point. See docs/QUICKSHELL.md.
ShellRoot {
  Bar {}
  NotificationPopups {}
  Launcher {
    id: launcher
  }
  SessionMenu {}
  ControlCenter {
    id: controlCenter
  }
  Osd {}
  KeybindCheatsheet {}
  Picker {
    id: picker
  }

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

    // qs ipc call shell toggleCenter
    function toggleCenter(): void {
      ShellState.toggleCenter();
    }

    // qs ipc call shell openCenterView wifi | bluetooth
    function openCenterView(view: string): void {
      ShellState.openCenterView(view);
    }

    // qs ipc call shell openCenterSection audio | system | display | power | calendar
    function openCenterSection(section: string): void {
      ShellState.openCenterSection(section);
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
        launcherOpen: ShellState.launcherOpen,
        launcherPage: ShellState.launcherPage,
        launcherItems: launcher.items.length,
        launcherFocus: launcher.inputFocus,
        pickerOpen: ShellState.pickerOpen,
        pickerTab: ShellState.pickerTab,
        pickerIndex: picker.pickerIndex,
        pickerCount: picker.pickerCount,
        pickerFocus: picker.wallpaperGridFocus,
        calendarSelected: Qt.formatDateTime(controlCenter.calendarSelected, "yyyy-MM-dd"),
        wifiListFocus: controlCenter.wifiListFocus,
        btListFocus: controlCenter.btListFocus,
        currentWallpaper: Theme.currentWallpaper,
        centerOpen: ShellState.centerOpen,
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
        btDevices: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.devices.values.length : 0,
        sessionOpen: ShellState.sessionOpen,
        cheatsheetOpen: ShellState.cheatsheetOpen
      });
    }

    // qs ipc call shell showOsd volume 0.42
    function showOsd(kind: string, value: real): void {
      ShellState.showOsd(kind, value, Math.round(value * 100) + "%");
    }
  }
}
