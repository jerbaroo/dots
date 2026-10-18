import QtQuick
import Quickshell
import Quickshell.Io

import "../config.js" as Config

// Shared "keep awake" state for the whole shell. One instance is created in
// bar.qml and handed to every per-monitor BarWindow (like NotificationCenter),
// so the mode is consistent across monitors and a single inhibitor is held.
//
//   0 Normal   — system may sleep and lock as usual.
//   1 No sleep — suspend blocked, locking still happens.
//   2 No lock  — suspend, lock and screen-off all blocked.
Scope {
    id: root

    property int mode: 0

    // Per-mode presentation, indexed by `mode`. Symbolic mugs match the bar's
    // other monochrome icons; the chip's three dots show which mode is active.
    readonly property var modes: [
        {
            label: "Normal",
            icon: "my-caffeine-off-symbolic"
        },
        {
            label: "No sleep",
            icon: "my-caffeine-on-symbolic"
        },
        {
            label: "No lock",
            icon: "changes-allow-symbolic"
        }
    ]

    // Any non-Normal mode blocks every suspend path. Both hypridle's idle
    // timeout and Hyprland's lid switch call `systemctl suspend`, which a
    // block inhibitor makes refuse; locking is independent, so "No sleep"
    // still locks. Quickshell SIGTERMs the process when `running` goes false,
    // releasing the lock.
    Process {
        running: root.mode >= 1
        command: ["systemd-inhibit", "--what=sleep", "--who=menu-bar", "--why=Keep awake toggled from menu bar", "--mode=block", "sleep", "infinity"]
    }

    // "No lock" additionally drops a flag that hypridle checks before it locks,
    // shows its lock countdown, or blanks the screen (see hypridle.nix). The
    // path is the single source of truth from Nix, injected into config.js.
    function syncLockFlag() {
        Quickshell.execDetached(["sh", "-c", root.mode >= 2 ? `touch ${Config.inhibitLockPath}` : `rm -f ${Config.inhibitLockPath}`]);
    }

    onModeChanged: syncLockFlag()
    // Reset the flag to match mode 0 on (re)start.
    Component.onCompleted: syncLockFlag()
}
