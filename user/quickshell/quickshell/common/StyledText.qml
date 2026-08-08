import QtQuick
import qs.common

// The foreground half of the pattern StyledRect covers: a Text whose colour
// eases instead of snapping. Use it wherever a label's colour depends on state,
// so a label sitting on a StyledRect does not snap while its background fades.
Text {
    Behavior on color {
        CAnim {}
    }
}
