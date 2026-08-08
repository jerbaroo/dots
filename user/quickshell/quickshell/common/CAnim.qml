import QtQuick
import "../config.js" as Config

// Colour counterpart to Anim. Always the effect family: a colour has no
// position, so the spatial/travel distinction is meaningless for it.
ColorAnimation {
    duration: Config.anim.effectMs
    easing.bezierCurve: Config.anim.effectCurve
    easing.type: Easing.Bezier
}
