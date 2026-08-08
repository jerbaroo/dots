import QtQuick
import qs.common

// A Rectangle whose colours ease instead of snapping. Use this anywhere a fill
// or border depends on state — `hovered ? a : b`, `active ? a : b` — which is
// every interactive surface in the shell. Doing it here means no call site
// needs a Behavior of its own, and hover feedback is consistent across the bar,
// the launcher and the notifications.
//
// Geometry is deliberately not animated: some of these are list delegates that
// are laid out, recycled and resized, and easing that would smear.
Rectangle {
    Behavior on color {
        CAnim {}
    }
    Behavior on border.color {
        CAnim {}
    }
}
