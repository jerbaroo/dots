import QtQuick
import Quickshell
import Quickshell.Io
import qs.bar

// Menu bar + notification server, one quickshell instance. See BAR.md.
Scope {
    id: root

    property bool barVisible: true

    IpcHandler {
        function setHidden(): void {
            root.barVisible = false;
        }
        function setShown(): void {
            root.barVisible = true;
        }
        function toggle(): void {
            root.barVisible = !root.barVisible;
        }

        target: "bar"
    }
    NotificationCenter {
        id: notifs
    }
    Awake {
        id: awakeState
    }

    // Transient volume/brightness OSD (watches Pipewire + Brightness itself).
    Osd {
    }
    Variants {
        model: Quickshell.screens

        BarWindow {
            property var modelData

            awake: awakeState
            notifications: notifs
            screen: modelData
            visible: root.barVisible
        }
    }
}
