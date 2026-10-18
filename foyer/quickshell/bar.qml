import Quickshell
import qs.bar

// Menu bar + notification server, one quickshell instance. See BAR.md.
Scope {
    NotificationCenter {
        id: notifs
    }

    Awake {
        id: awakeState
    }

    // Transient volume/brightness OSD (watches Pipewire + Brightness itself).
    Osd {}

    Variants {
        model: Quickshell.screens

        BarWindow {
            property var modelData
            awake: awakeState
            notifications: notifs
            screen: modelData
        }
    }
}
