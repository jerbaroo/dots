import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import qs.bar
import qs.common

// The single shared hover panel (BAR.md: one panel component). There is exactly
// one of these, instantiated by BarWindow. Unlike a normal popup it is *not* a
// separate surface: it renders inside the bar's own layer surface, in the empty
// (non-exclusive) space below the bar. That is deliberate — a separate xdg-popup
// surface gets its own blur pass, which both lags on first open (blur only lands
// once the surface maps) and reads as a discontinuity against the bar's glass.
// Living in the bar surface makes the blur one continuous region and removes the
// open delay.
//
// Three motions, in three separate places, none of which fades the glass:
//
//   open/close  — `reveal` grows the panel's height out of the bar strip, with
//                 the content clipped to it. The compositor only blurs above an
//                 alpha threshold, so the glass can never fade in; growing it
//                 from nothing means it is fully opaque (and so fully blurred)
//                 in every frame it is visible.
//   chip switch — the panel slides and resizes to the new chip (x, implicitHeight)
//                 while `swap` cross-fades the content at the midpoint of the
//                 travel, so the box arrives already showing the new module.
//   content     — a panel that resizes itself while open (a dropdown expanding)
//                 animates through the same implicitHeight Behavior.
//
// Wayland cannot smoothly tween a popup's position, so the moving part lives
// inside this static, full-width item.
Item {
    id: root

    // The bar's content item; chips live in its coordinate space.
    required property Item barItem

    // The chip whose panel is shown (null while closing, and null when the
    // active chip belongs to another monitor).
    //
    // PanelController is a singleton, so one chip is active across the whole
    // shell — which is right, only one panel should ever be open. But BarWindow
    // is instantiated per screen, so every monitor has its own HoverPanel
    // reading that one global. Each must therefore ignore a chip that is not
    // its own, or all of them mirror the same popup. It also keeps the
    // mapToItem below within a single window, where it is meaningful.
    readonly property Item chip: {
        const active = PanelController.activeChip;
        if (!active)
            return null;
        return active.Window.window === root.Window.window ? active : null;
    }
    readonly property bool shown: chip !== null
    // The moving panel. BarWindow's input mask reads this so the rest of the
    // surface stays click-through; its height is the animated one, so the mask
    // tracks the reveal rather than jumping ahead of it.
    readonly property alias panelItem: panel
    // Whether any part of the panel is on screen. The mask keys off the reveal
    // for the same reason the glass does: one property drives what is drawn and
    // what takes input, so the two cannot disagree.
    readonly property bool panelActive: panel.reveal > 0.01
    // Retains the last chip so content and geometry stay put while retracting,
    // and through the first half of a cross-fade.
    property Item displayChip: null
    property real targetX: 0

    onChipChanged: {
        if (!chip || chip === displayChip)
            return;
        const centre = chip.mapToItem(barItem, chip.width / 2, 0).x - Style.panelWidth / 2;
        // Keep the panel on screen, allowing for the concave wings that extend
        // Style.panelRadius past the body on each side.
        const margin = Style.panelGap + Style.panelRadius;
        targetX = Math.max(margin, Math.min(barItem.width - Style.panelWidth - margin, centre));
        if (panel.reveal > 0) {
            // Already on screen: slide there and cross-fade to the new content.
            swap.restart();
        } else {
            // Fully retracted: adopt the chip now so it is revealed with the
            // panel. The x and implicitHeight Behaviors are gated on the reveal,
            // so both snap here rather than animating from the last chip's.
            swap.stop();
            column.opacity = 1;
            displayChip = chip;
        }
    }
    // Abandon an in-flight swap rather than let it commit a null chip, which
    // would blank the content halfway through the retract.
    onShownChanged: if (!shown)
        swap.stop()

    function titleCase(s) {
        return s.replace(/\b\w/g, c => c.toUpperCase());
    }

    // Cross-fade between two chips' content, timed so the swap lands mid-slide.
    SequentialAnimation {
        id: swap

        Anim {
            target: column
            property: "opacity"
            to: 0
            family: Anim.EffectFast
        }
        ScriptAction {
            script: if (root.chip)
                root.displayChip = root.chip
        }
        Anim {
            target: column
            property: "opacity"
            to: 1
        }
    }

    Item {
        id: panel

        readonly property Item chip: root.displayChip
        // 0 fully retracted into the bar, 1 fully out. Drives height, so the
        // panel emerges rather than appearing; see the header comment. Not
        // readonly: the Behavior below writes it on the way to the bound value.
        property real reveal: root.shown ? 1 : 0

        x: root.targetX
        // Directly below the bar strip, flush against it so the glass is
        // continuous (the concave top corners flow down out of the bar).
        y: Style.barHeight
        width: Style.panelWidth
        implicitHeight: column.implicitHeight + Style.panelPadding * 2
        // Clamped: the spatial curve overshoots, so a closing panel's reveal
        // dips below zero on its way to rest.
        height: Math.max(0, implicitHeight * reveal)

        Behavior on reveal {
            Anim {
                family: Anim.Spatial
            }
        }
        // Both gated on being fully out: while the panel is emerging or
        // retracting its target geometry belongs to a chip it is not showing
        // yet, and animating towards that would overshoot the reveal.
        Behavior on x {
            enabled: panel.reveal >= 1
            Anim {
                family: Anim.Travel
            }
        }
        Behavior on implicitHeight {
            enabled: panel.reveal >= 1
            Anim {
                family: Anim.Spatial
            }
        }

        // Panel background. The top corners scoop inward (concave): the top
        // edge is widest and the sides curve in to the body, so the panel reads
        // as flowing down out of the bar. Bottom corners round convex. Drawn as
        // a Shape because a Rectangle can't do concave corners; unlike the
        // Canvas this replaced, its path is a set of bindings the scene graph
        // re-tessellates on the GPU, so it can follow the reveal every frame.
        Shape {
            id: bg

            // Horizontal slack for the wings, which reach a radius past the
            // body. Constant, so the item's own geometry never moves as the
            // drawn radius changes with the reveal.
            readonly property int slack: Style.panelRadius + 2
            // Body edges, in this item's coordinates.
            readonly property real l: slack
            readonly property real r: slack + panel.width
            // One radius for every corner, clamped so the top scoops and the
            // bottom rounds cannot overlap while the panel is still short. The
            // scoop opening up as the panel emerges is the point, not a
            // side effect.
            readonly property real rad: Math.min(Style.panelRadius, panel.height / 2)

            x: -slack
            y: 0
            width: panel.width + slack * 2
            height: panel.height
            preferredRendererType: Shape.CurveRenderer
            visible: height > 0

            ShapePath {
                fillColor: Style.panelColor
                strokeWidth: -1

                startX: bg.l - bg.rad
                startY: 0

                PathLine {
                    x: bg.r + bg.rad
                    y: 0
                }
                PathArc {
                    // Top-right, concave.
                    x: bg.r
                    y: bg.rad
                    radiusX: bg.rad
                    radiusY: bg.rad
                    direction: PathArc.Counterclockwise
                }
                PathLine {
                    x: bg.r
                    y: bg.height - bg.rad
                }
                PathArc {
                    // Bottom-right, convex.
                    x: bg.r - bg.rad
                    y: bg.height
                    radiusX: bg.rad
                    radiusY: bg.rad
                    direction: PathArc.Clockwise
                }
                PathLine {
                    x: bg.l + bg.rad
                    y: bg.height
                }
                PathArc {
                    // Bottom-left, convex.
                    x: bg.l
                    y: bg.height - bg.rad
                    radiusX: bg.rad
                    radiusY: bg.rad
                    direction: PathArc.Clockwise
                }
                PathLine {
                    x: bg.l
                    y: bg.rad
                }
                PathArc {
                    // Top-left, concave.
                    x: bg.l - bg.rad
                    y: 0
                    radiusX: bg.rad
                    radiusY: bg.rad
                    direction: PathArc.Counterclockwise
                }
            }
        }

        HoverHandler {
            onHoveredChanged: PanelController.setPanelHovered(hovered)
        }

        // Clipped to the panel body (not the wings, which the content never
        // reaches): the content is anchored to the top, so the reveal uncovers
        // it downwards as the panel emerges from the bar.
        Item {
            anchors.fill: parent
            clip: true

            ColumnLayout {
                id: column
                anchors.left: parent.left
                anchors.margins: Style.panelPadding
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: Style.panelSpacing
                // Only ever touched by the swap animation above; the panel
                // opening and closing is the reveal's job, not a fade's.

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
                        // Hidden (and space-free, being in a Layout) when the chip
                        // supplies a header control instead — e.g. a toggle.
                        visible: (panel.chip?.panelStateControl ?? null) === null
                        text: root.titleCase(panel.chip?.panelState ?? "")
                    }

                    Loader {
                        active: (panel.chip?.panelStateControl ?? null) !== null
                        sourceComponent: panel.chip?.panelStateControl ?? null
                        visible: active
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
}
