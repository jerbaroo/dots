import QtQuick
import FoyerConfig 1.0

// Colour counterpart to Anim. Uses the enter timing and easing.
ColorAnimation {
    duration: Config.anim.enterMs
    easing.bezierCurve: Config.anim.enterCurve
    easing.type: Easing.Bezier
}
