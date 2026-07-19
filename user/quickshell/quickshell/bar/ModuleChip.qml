import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import qs.bar

// The one module implementation (BAR.md). Every bar element is one of these;
// modules differ only in the configuration below. Missing fields no-op.
Rectangle {
    id: chip

    // Chip contents.
    property string icon: "" // Icon theme name, tinted to the text color.
    property string iconSource: "" // Raw image URL, untinted (e.g. tray icons).
    property string value: ""
    property int dotIndex: -1 // Perf mode dots; -1 hides them.
    property bool bold: false
    property bool dim: false // Off / disconnected state.
    property bool accent: false // Active workspace border.
    // Verbs. Unset fields do nothing.
    signal clicked
    signal scrolled(bool up)
    signal rightClicked
    property string rightClickApp: ""
    // Hover panel spec (data only; empty title = no panel).
    property string panelTitle: ""
    property string panelState: ""
    property bool panelStateGood: false
    property Component panelControls: null
    signal panelOpening // Refresh hook, e.g. wifi scan.

    readonly property bool wantsPanel: panelTitle !== "" && (mouseArea.containsMouse || panel.hovered)

    // Minimum chip width; content stays centered (e.g. workspace chips).
    property int minWidth: 0

    border.color: accent ? Style.accent : dim ? Style.chipBorderDim : Style.chipBorder
    border.width: 1
    color: dim ? Style.chipColorDim : Style.chipColor
    implicitHeight: Style.chipHeight
    implicitWidth: Math.max(minWidth, row.implicitWidth + Style.chipPaddingH * 2)
    radius: Style.chipRadius

    onWantsPanelChanged: {
        if (wantsPanel) {
            closeTimer.stop();
            if (!panel.visible)
                openTimer.restart();
        } else {
            openTimer.stop();
            closeTimer.restart();
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Style.chipContentGap

        IconImage {
            anchors.verticalCenter: parent.verticalCenter
            implicitSize: Style.iconSize
            // Tint themed icons: brightness lifts the (often dark grey)
            // symbolic glyph to full white, colorization then applies the
            // text color. Raw iconSource images are shown untinted.
            layer.enabled: chip.iconSource === ""
            layer.effect: MultiEffect {
                brightness: 1
                colorization: 1
                colorizationColor: Style.text
            }
            opacity: chip.dim ? 0.5 : 1
            source: chip.iconSource !== "" ? chip.iconSource : chip.icon !== "" ? Quickshell.iconPath(chip.icon) : ""
            visible: source != ""
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            color: chip.dim ? Style.textDim : Style.text
            font.bold: chip.bold
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSize
            text: chip.value
            visible: chip.value !== ""
        }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.dotGap
            visible: chip.dotIndex >= 0

            Repeater {
                model: 3

                Rectangle {
                    required property int index
                    anchors.verticalCenter: parent.verticalCenter
                    color: index === chip.dotIndex ? Style.good : Style.dotOff
                    height: Style.dotSize
                    radius: height / 2
                    width: Style.dotSize
                }
            }
        }
    }

    MouseArea {
        id: mouseArea
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        anchors.fill: parent
        hoverEnabled: true
        onClicked: event => {
            if (event.button === Qt.RightButton) {
                if (chip.rightClickApp !== "")
                    Launcher.app(chip.rightClickApp);
                chip.rightClicked();
            } else {
                chip.clicked();
            }
        }
        onWheel: event => chip.scrolled(event.angleDelta.y > 0)
    }

    HoverPanel {
        id: panel
        chipItem: chip
        controls: chip.panelControls
        stateGood: chip.panelStateGood
        stateText: chip.panelState
        title: chip.panelTitle
    }

    // Hover verb: open after a delay; grace period lets the cursor travel
    // from chip to panel before it closes.
    Timer {
        id: openTimer
        interval: Style.hoverOpenMs
        onTriggered: {
            chip.panelOpening();
            panel.visible = true;
        }
    }

    Timer {
        id: closeTimer
        interval: Style.hoverCloseMs
        onTriggered: panel.visible = false
    }
}
