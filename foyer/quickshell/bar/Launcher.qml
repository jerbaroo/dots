pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

// Launches apps through hyprland's exec dispatcher (hyprglass Lua API), so
// commands support rule prefixes like "[float;center;...]" — the same
// mechanism the keybinds use.
Singleton {
    function app(cmd) {
        Hyprland.dispatch(`hl.dsp.exec_cmd("${cmd}")`);
    }
}
