import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.bar

// The single shared hover panel (BAR.md: one panel component). There is exactly
// one of these, instantiated by BarWindow. It is a static, full-width popup
// sitting just below the bar; the visible panel Rectangle slides and resizes
// between chips (driven by PanelController.activeChip), so moving from one
// module to the next is a fluid transition rather than a pop in/out.
//
// Why full width / why one static surface: Wayland cannot smoothly tween a
// popup's own position, so the moving part must live *inside* a static surface.
// The surface is transparent and a mask keeps everything but the visible panel
// click-through, so the width is an invisible coordinate space, not UI.
PopupWindow {
    id: root

    // The bar's content item; chips live in its coordinate space.
    required property Item barItem

    // The chip whose panel is shown (null while closing).
    readonly property Item chip: PanelController.activeChip
    readonly property bool shown: chip !== null
    // Retains the last chip so content/geometry stay put during the fade-out.
    property Item displayChip: null
    property bool opened: false
    property real targetX: 0

    onChipChanged: {
        if (!chip)
            return;
        displayChip = chip;
        var centre = chip.mapToItem(barItem, chip.width / 2, 0).x - Style.panelWidth / 2;
        // Keep the panel on screen, allowing for the concave wings that extend
        // Style.panelRadius past the body on each side.
        var margin = Style.panelGap + Style.panelRadius;
        var clamped = Math.max(margin, Math.min(barItem.width - Style.panelWidth - margin, centre));
        if (opened) {
            targetX = clamped; // switch between chips: animate the slide
        } else {
            xBehavior.enabled = false; // fresh open: appear in place, no slide-in
            targetX = clamped;
            xBehavior.enabled = true;
        }
        opened = true;
    }
    onShownChanged: if (!shown)
        opened = false

    anchor.item: barItem
    anchor.rect.x: 0
    anchor.rect.y: Style.barHeight
    color: "transparent"
    implicitHeight: Style.panelMaxHeight
    implicitWidth: barItem ? barItem.width : 0
    visible: shown || panel.opacity > 0.01

    // Only the visible panel takes input; the rest of the surface is transparent
    // and click-through.
    mask: Region {
        item: panel
    }

    function titleCase(s) {
        return s.replace(/\b\w/g, c => c.toUpperCase());
    }

    Item {
        id: panel

        readonly property Item chip: root.displayChip

        x: root.targetX
        y: 0
        width: Style.panelWidth
        implicitHeight: column.implicitHeight + Style.panelPadding * 2
        height: implicitHeight
        opacity: root.shown ? 1 : 0

        // The fluid transition: slide and resize between chips, fade in/out.
        Behavior on x {
            id: xBehavior
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
        }
        Behavior on implicitHeight {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 120
            }
        }

        // Panel background. The top corners scoop inward (concave): the top
        // edge is widest and the sides curve in to the body, so the panel reads
        // as flowing down out of the bar. Bottom corners round convex. Drawn
        // with Canvas because a Rectangle/Shape can't do concave corners; the
        // canvas is wider than the body so the outward "wings" aren't clipped.
        Canvas {
            id: bg
            readonly property real rt: Style.panelRadius // top scoop radius (config: bar.panel.radius)
            readonly property real rb: Style.panelRadius // bottom corner radius
            readonly property int pad: Math.ceil(rt) + 2 // slack for the wings

            x: -pad
            y: 0
            width: panel.width + pad * 2
            height: panel.height
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()

            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                ctx.translate(pad, 0);
                var W = panel.width, H = height, rt = bg.rt, rb = bg.rb;
                ctx.fillStyle = Style.panelColor;
                ctx.beginPath();
                ctx.moveTo(-rt, 0);
                ctx.lineTo(W + rt, 0);
                ctx.arc(W + rt, rt, rt, -Math.PI / 2, Math.PI, true);  // top-right concave
                ctx.lineTo(W, H - rb);
                ctx.arc(W - rb, H - rb, rb, 0, Math.PI / 2, false);    // bottom-right convex
                ctx.lineTo(rb, H);
                ctx.arc(rb, H - rb, rb, Math.PI / 2, Math.PI, false);  // bottom-left convex
                ctx.lineTo(0, rt);
                ctx.arc(-rt, rt, rt, 0, -Math.PI / 2, true);           // top-left concave
                ctx.closePath();
                ctx.fill();
            }
        }

        HoverHandler {
            onHoveredChanged: PanelController.setPanelHovered(hovered)
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
                    text: panel.chip?.panelTitle ?? ""
                }

                Text {
                    color: (panel.chip?.panelStateGood ?? false) ? Style.good : Style.panelText
                    font.family: Style.fontFamily
                    font.pixelSize: Style.panelFontSize
                    text: root.titleCase(panel.chip?.panelState ?? "")
                }
            }

            Loader {
                Layout.fillWidth: true
                active: panel.chip?.panelControls != null
                sourceComponent: panel.chip?.panelControls ?? null
                visible: status === Loader.Ready
            }
        }
    }
}
