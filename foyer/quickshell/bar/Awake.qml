import QtQuick
import Quickshell
import Quickshell.Io

import FoyerConfig 1.0

// Shared "keep awake" state for the whole shell. One instance is created in
// bar.qml and handed to every per-monitor BarWindow (like NotificationCenter),
// so the mode and inhibitor processes are shared across monitors.
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

    // Both awake modes block suspend; the process releases its inhibitor on exit.
    Process {
        command: [Config.inhibitCommand, "--what=sleep", "--who=foyer", "--why=Keep awake", "--mode=block", Config.sleepCommand, "infinity"]
        running: root.mode >= 1
    }

    // No lock additionally pauses idle actions through logind, including screen-off.
    Process {
        command: [Config.inhibitCommand, "--what=idle", "--who=foyer", "--why=Keep awake without idle locking", "--mode=block", Config.sleepCommand, "infinity"]
        running: root.mode >= 2
    }
}
