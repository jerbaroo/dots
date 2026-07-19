import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.bar

// The one hover panel component (BAR.md): fixed width, title left, state
// right, then 0..n control rows supplied as data. Modules cannot render
// arbitrary panel markup; they only fill these fields.
PopupWindow {
    id: panel

    required property Item chipItem
    property string title: ""
    property string stateText: ""
    property bool stateGood: false
    property Component controls: null
    readonly property bool hovered: hoverHandler.hovered

    anchor.adjustment: PopupAdjustment.SlideX
    anchor.item: chipItem
    anchor.rect.x: chipItem.width / 2 - Style.panelWidth / 2
    anchor.rect.y: chipItem.height + Style.panelGap
    color: "transparent"
    implicitHeight: body.implicitHeight
    implicitWidth: Style.panelWidth
    visible: false

    Rectangle {
        id: body
        anchors.fill: parent
        color: Style.panelColor
        implicitHeight: column.implicitHeight + Style.panelPadding * 2
        radius: Style.panelRadius

        HoverHandler {
            id: hoverHandler
        }

        ColumnLayout {
            id: column
            anchors.left: parent.left
            anchors.margins: Style.panelPadding
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: Style.panelSpacing

            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    color: Style.panelText
                    elide: Text.ElideRight
                    font.bold: true
                    font.family: Style.fontFamily
                    font.pixelSize: Style.panelFontSize
                    text: panel.title
                }

                Text {
                    color: panel.stateGood ? Style.good : Style.panelText
                    font.family: Style.fontFamily
                    font.pixelSize: Style.panelFontSize
                    text: panel.stateText
                }
            }

            Loader {
                Layout.fillWidth: true
                active: panel.controls !== null
                sourceComponent: panel.controls
                visible: status === Loader.Ready
            }
        }
    }
}
