pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.bar

// Monitor brightness over DDC (ddcutil). Reads once at startup; writes are
// debounced because ddcutil calls are slow. Hidden when unavailable.
Singleton {
    id: root

    // Percentage 0-100, or -1 while unknown / unavailable.
    property int value: -1
    readonly property bool available: value >= 0
    property int _max: 100

    function adjust(delta) {
        if (available)
            set(value + delta);
    }

    function set(v) {
        value = Math.max(0, Math.min(100, Math.round(v)));
        writeDebounce.restart();
    }

    Process {
        id: read
        command: ["sh", "-c", "command -v ddcutil > /dev/null && ddcutil --brief getvcp 10 || true"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                // Output: "VCP 10 C <current> <max>".
                const parts = text.trim().split(/\s+/);
                if (parts[0] === "VCP") {
                    root._max = Number(parts[4]) || 100;
                    root.value = Math.round(100 * Number(parts[3]) / root._max);
                }
            }
        }
    }

    Timer {
        id: writeDebounce
        interval: Style.brightnessDebounceMs
        onTriggered: Quickshell.execDetached(["ddcutil", "setvcp", "10", String(Math.round(root.value * root._max / 100))])
    }
}
