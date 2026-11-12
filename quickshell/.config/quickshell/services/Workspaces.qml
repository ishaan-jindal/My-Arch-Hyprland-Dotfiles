pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// Thin facade over Quickshell.Hyprland. focusedWorkspace is reliable;
// activeToplevel is often null on this build, so nothing here depends on it.
Singleton {
  id: root

  readonly property int activeId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1

  readonly property var ids: {
    const out = [];
    const all = Hyprland.workspaces.values;
    for (let i = 0; i < all.length; i++) {
      if (all[i].id > 0)
        out.push(all[i].id);
    }
    return out.sort((a, b) => a - b);
  }

  function switchTo(id) {
    // Legacy "workspace N" dispatch strings fail on Hyprland 0.57 (Lua config
    // provider); only the hl.dsp expression form works.
    Hyprland.dispatch("hl.dsp.focus({workspace=" + id + "})");
  }
}
