import Quickshell
import qs.bar

// Menu bar + notification server, one quickshell instance. See BAR.md.
Scope {
    NotificationCenter {
        id: notifs
    }

    Variants {
        model: Quickshell.screens

        BarWindow {
            property var modelData
            notifications: notifs
            screen: modelData
        }
    }
}
