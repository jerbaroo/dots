import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.bar

// The shared control library (BAR.md): each control is implemented once and
// reused by every panel. Modules may not define one-off controls; extend this
// library instead. Use as Controls.SliderRow, Controls.Dropdown, etc.
Item {
    component PanelText: Text {
        color: Style.panelText
        font.family: Style.fontFamily
        font.pixelSize: Style.panelFontSize
    }

    // Base for every clickable row: shared size, radius and hover feedback.
    component ControlRow: Rectangle {
        id: controlRow

        property bool active: false
        readonly property bool hovered: rowMouse.containsMouse
        signal clicked

        Layout.fillWidth: true
        color: hovered ? Style.controlHoverColor : active ? Style.controlActiveColor : Style.controlColor
        implicitHeight: Style.controlHeight
        radius: Style.controlRadius

        MouseArea {
            id: rowMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: controlRow.clicked()
        }
    }

    // Continuous 0..1 value. Used by: volume, brightness.
    component SliderRow: Item {
        id: slider

        property real value: 0
        signal moved(real value)

        Layout.fillWidth: true
        implicitHeight: Style.sliderHeight

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            color: Style.sliderTrack
            height: Style.sliderTrackHeight
            radius: height / 2
            width: parent.width

            Rectangle {
                color: Style.accent
                height: parent.height
                radius: parent.radius
                width: parent.width * Math.max(0, Math.min(1, slider.value))
            }
        }

        MouseArea {
            anchors.fill: parent
            onPositionChanged: mouse => {
                if (pressed)
                    slider.moved(Math.max(0, Math.min(1, mouse.x / width)));
            }
            onPressed: mouse => slider.moved(Math.max(0, Math.min(1, mouse.x / width)))
        }
    }

    // Closed row + ▾ that expands into an option list. Options are
    // { label, value, active }. Used by: volume output, wifi, bluetooth.
    component Dropdown: ColumnLayout {
        id: dropdown

        property string current: ""
        property bool open: false
        property var options: []
        signal selected(var value)

        spacing: Style.controlSpacing

        ControlRow {
            border.color: Style.controlBorder
            border.width: 1
            onClicked: dropdown.open = !dropdown.open

            PanelText {
                anchors.left: parent.left
                anchors.leftMargin: Style.controlPadding
                anchors.right: arrow.left
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                text: dropdown.current
            }

            PanelText {
                id: arrow
                anchors.right: parent.right
                anchors.rightMargin: Style.controlPadding
                anchors.verticalCenter: parent.verticalCenter
                color: Style.panelTextDim
                text: "▾"
            }
        }

        Repeater {
            model: dropdown.open ? dropdown.options : []

            ControlRow {
                id: option

                required property var modelData

                active: modelData.active
                onClicked: {
                    dropdown.open = false;
                    dropdown.selected(option.modelData.value);
                }

                PanelText {
                    anchors.left: parent.left
                    anchors.leftMargin: Style.controlPadding
                    anchors.right: parent.right
                    anchors.rightMargin: Style.controlPadding
                    anchors.verticalCenter: parent.verticalCenter
                    elide: Text.ElideRight
                    text: option.modelData.label
                }
            }
        }
    }

    // Vertical exclusive options, current highlighted. Options are
    // { label, value } with an optional icon name. Used by: perf mode, power.
    component ModeList: ColumnLayout {
        id: modeList

        property var current
        property var options: []
        signal selected(var value)

        spacing: Style.controlSpacing

        Repeater {
            model: modeList.options

            ControlRow {
                id: mode

                required property var modelData

                active: modelData.value === modeList.current
                border.color: active ? Style.good : "transparent"
                border.width: 1
                onClicked: modeList.selected(mode.modelData.value)

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: Style.controlPadding
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Style.controlSpacing

                    IconImage {
                        anchors.verticalCenter: parent.verticalCenter
                        implicitSize: Style.iconSize
                        visible: (mode.modelData.icon ?? "") !== ""
                        source: visible ? Quickshell.iconPath(mode.modelData.icon) : ""
                        // Tint the symbolic glyph white, as elsewhere.
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            brightness: 1
                            colorization: 1
                            colorizationColor: Style.panelText
                        }
                    }

                    PanelText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: mode.modelData.label
                    }
                }
            }
        }
    }

    // Labelled on/off switch. Used by: DND, wifi, bluetooth.
    component ToggleRow: ControlRow {
        id: toggle

        property bool checked: false
        property string label: ""
        signal toggled(bool checked)

        onClicked: toggle.toggled(!toggle.checked)

        PanelText {
            anchors.left: parent.left
            anchors.leftMargin: Style.controlPadding
            anchors.verticalCenter: parent.verticalCenter
            text: toggle.label
        }

        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: Style.controlPadding
            anchors.verticalCenter: parent.verticalCenter
            color: toggle.checked ? Style.good : Style.controlBorder
            height: Style.togglePillHeight
            radius: height / 2
            width: Style.togglePillWidth

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                color: Style.panelText
                height: Style.toggleKnobSize
                radius: height / 2
                width: Style.toggleKnobSize
                x: toggle.checked ? parent.width - width - Style.toggleKnobMargin : Style.toggleKnobMargin
            }
        }
    }

    // Read-only text rows. Used by: cpu, memory, battery, clock.
    component InfoLines: ColumnLayout {
        id: infoLines

        property var lines: []

        spacing: Style.infoSpacing

        Repeater {
            model: infoLines.lines

            PanelText {
                required property var modelData
                Layout.fillWidth: true
                color: Style.panelTextDim
                elide: Text.ElideRight
                text: modelData
            }
        }
    }
}
