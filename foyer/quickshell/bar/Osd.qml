import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import Quickshell.Widgets

import "../config.js" as Config
import qs.bar
import qs.common

// macOS-style on-screen display. A single transient card, bottom-centre, shown
// when volume or brightness changes *while no menu-bar popup is open* (if a
// popup is open the user already sees that slider). One shared component: only
// the icon and level differ between the two sources. One instance for the whole
// shell, created in bar.qml.
Scope {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink

    // Transient display state.
    property string glyph: ""
    property real level: 0 // 0..1
    property bool shown: false

    // Startup guard: the sink binding and the (slow, ddcutil) brightness read
    // fire value-changes as they initialise; those are not user actions, so we
    // suppress them. Volume settles within the timer; brightness is gated on
    // its first real reading instead, since ddcutil can take several seconds.
    property bool _started: false
    property bool _brightnessSeen: false

    function trigger(icon, value) {
        if (PanelController.activeChip !== null)
            return; // a menu-bar popup is open; it already shows the slider
        glyph = icon;
        level = Math.max(0, Math.min(1, value));
        shown = true;
        hideTimer.restart();
    }

    Component.onCompleted: startupTimer.start()

    Timer {
        id: startupTimer
        interval: 800
        onTriggered: root._started = true
    }

    Timer {
        id: hideTimer
        interval: Config.osd.hideMs
        onTriggered: root.shown = false
    }

    // Keep the default sink's volume/mute properties live.
    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    Connections {
        target: root.sink?.audio ?? null
        function onVolumeChanged() {
            root._volumeOsd();
        }
        function onMutedChanged() {
            root._volumeOsd();
        }
    }

    function _volumeOsd() {
        if (!root._started || !root.sink)
            return;
        const muted = root.sink.audio.muted;
        const vol = root.sink.audio.volume;
        const icon = muted ? "audio-volume-muted-symbolic" : vol < 0.34 ? "audio-volume-low-symbolic" : vol < 0.67 ? "audio-volume-medium-symbolic" : "audio-volume-high-symbolic";
        root.trigger(icon, muted ? 0 : vol);
    }

    Connections {
        target: Brightness
        function onValueChanged() {
            if (!Brightness.available)
                return;
            if (!root._brightnessSeen) {
                root._brightnessSeen = true; // first real reading = the initial ddcutil read
                return;
            }
            const v = Brightness.value / 100;
            const icon = v < 0.34 ? "display-brightness-low-symbolic" : v < 0.67 ? "display-brightness-medium-symbolic" : "display-brightness-high-symbolic";
            root.trigger(icon, v);
        }
    }

    PanelWindow {
        // Own blur namespace, faded in place, like the other popups (hyprland.nix).
        WlrLayershell.namespace: "quickshell-osd"

        anchors {
            left: true
            right: true
            top: true
        }
        color: "transparent"
        // A transient overlay: never reserve space, never take input.
        exclusionMode: ExclusionMode.Ignore
        focusable: false
        implicitHeight: Config.osd.height + Config.osd.margin
        mask: Region {}
        visible: root.shown

        // Frosted card, top-centre. Only this (tinted above the blur rule's
        // ignore_alpha) is blurred; the rest of the surface is transparent and
        // passes through.
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Config.osd.margin
            color: Config.glass
            height: Config.osd.height
            radius: Config.rounding
            width: Config.osd.width

            ColumnLayout {
                anchors.centerIn: parent
                spacing: Config.spacing.medium

                IconImage {
                    Layout.alignment: Qt.AlignHCenter
                    implicitSize: Config.iconSize.medium
                    source: root.glyph !== "" ? Quickshell.iconPath(root.glyph) : ""
                    // Tint the symbolic glyph to the text colour, as elsewhere.
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        brightness: 1
                        colorization: 1
                        colorizationColor: Config.text
                    }
                }

                // Level bar.
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    color: Config.surface0
                    implicitHeight: Config.osd.barHeight
                    // Span the (now wider) card, inset by a comfortable margin.
                    implicitWidth: Config.osd.width - 2 * Config.spacing.large
                    radius: height / 2

                    Rectangle {
                        color: Config.accent
                        height: parent.height
                        radius: parent.radius
                        width: parent.width * root.level

                        // The level arrives in discrete steps (a scroll notch,
                        // a brightness key), so easing between them reads as
                        // the value moving. Travel, not spatial: overshooting
                        // would show a level that was never set.
                        Behavior on width {
                            Anim {
                                family: Anim.Travel
                            }
                        }
                    }
                }
            }
        }
    }
}
