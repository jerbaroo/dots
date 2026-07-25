import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.bar

// The single shared hover panel (BAR.md: one panel component). There is exactly
// one of these, instantiated by BarWindow. Unlike a normal popup it is *not* a
// separate surface: it renders inside the bar's own layer surface, in the empty
// (non-exclusive) space below the bar. That is deliberate — a separate xdg-popup
// surface gets its own blur pass, which both lags on first open (blur only lands
// once the surface maps) and reads as a discontinuity against the bar's glass.
// Living in the bar surface makes the blur one continuous region and removes the
// open delay.
//
// The visible panel Rectangle slides and resizes between chips (driven by
// PanelController.activeChip), so moving from one module to the next is a fluid
// transition rather than a pop in/out. Wayland cannot smoothly tween a popup's
// position, so the moving part lives inside this static, full-width item.
Item {
    id: root

    // The bar's content item; chips live in its coordinate space.
    required property Item barItem

    // The chip whose panel is shown (null while closing).
    readonly property Item chip: PanelController.activeChip
    readonly property bool shown: chip !== null
    // The moving panel and whether it currently takes input (true while visible
    // or fading out). BarWindow's input mask reads these to keep the rest of the
    // surface click-through.
    readonly property alias panelItem: panel
    // Active while shown or while the content is still fading out. The glass
    // backdrop keys off this (not off a slow opacity ramp), so the blur is
    // present the instant content appears and stays until it is gone — no lag
    // where text shows over an as-yet-unblurred background. See panel below.
    readonly property bool panelActive: shown || column.opacity > 0.01
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

    function titleCase(s) {
        return s.replace(/\b\w/g, c => c.toUpperCase());
    }

    Item {
        id: panel

        readonly property Item chip: root.displayChip

        x: root.targetX
        // Directly below the bar strip, flush against it so the glass is
        // continuous (the concave top corners flow down out of the bar).
        y: Style.barHeight
        width: Style.panelWidth
        implicitHeight: column.implicitHeight + Style.panelPadding * 2
        height: implicitHeight
        // The panel itself never fades: its glass backdrop appears/disappears
        // with panelActive (so blur is not gated behind a slow ramp) and the
        // content fades on its own opacity below.

        // The fluid transition: slide and resize between chips.
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
            // On/off with the panel, not faded: the blur is applied by the
            // compositor only above an alpha threshold, so a slow opacity ramp
            // would make blur lag the (already visible) text. Snapping it keeps
            // the glass present the moment content shows and until it is gone.
            opacity: root.panelActive ? 1 : 0
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
            // The content fades over the (already-blurred) glass backdrop.
            opacity: root.shown ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 120
                }
            }

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
