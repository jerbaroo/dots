pragma Singleton
import QtQuick
import Quickshell
import "../config.js" as Config

// The bar's visual constants (BAR.md: one variables block). All sizes, gaps,
// timings and colors come from config.js.
Singleton {
    // Bar.
    readonly property color barColor: Config.glass
    readonly property int barHeight: Config.bar.height
    readonly property int barPadding: Config.bar.padding
    // Border width matching Hyprland's window borders (see hyprland.nix).
    readonly property int borderSize: Config.borderSize

    // Chips.
    readonly property int chipHeight: Config.bar.chip.height
    readonly property int chipPaddingH: Config.bar.chip.paddingH
    readonly property int chipRadius: Config.bar.chip.radius
    readonly property int chipGap: Config.bar.chip.gap
    readonly property int chipContentGap: Config.bar.chip.contentGap
    readonly property int workspaceGap: Config.bar.workspace.gap
    readonly property int workspaceMinWidth: Config.bar.workspace.minWidth
    readonly property var trayExclude: Config.bar.tray.exclude
    readonly property int dotSize: Config.bar.dot.size
    readonly property int dotGap: Config.bar.dot.gap
    readonly property color chipColor: Config.glass
    readonly property color chipColorDim: Config.glass
    readonly property color chipBorder: Qt.alpha(Config.text, 0.28)
    readonly property color chipBorderDim: Qt.alpha(Config.text, 0.15)
    readonly property color accent: Config.accent
    readonly property color text: Config.text
    readonly property color textDim: Qt.alpha(Config.text, 0.55)
    readonly property color good: Config.accent
    readonly property color dotOff: Qt.alpha(Config.text, 0.35)
    readonly property string fontFamily: Config.font.family
    readonly property int fontSize: Config.font.pixelSize.small
    readonly property int iconSize: Config.bar.iconSize

    // Hover panels.
    readonly property int panelWidth: Config.bar.panel.width
    readonly property int panelGap: Config.bar.panel.gap
    readonly property int panelPadding: Config.bar.panel.padding
    readonly property int panelRadius: Config.bar.panel.radius
    readonly property int panelSpacing: Config.bar.panel.spacing
    readonly property int panelMaxHeight: Config.bar.panel.maxHeight
    readonly property int panelFontSize: Config.font.pixelSize.small
    readonly property color panelColor: Config.panelGlass
    readonly property color panelText: Config.text
    readonly property color panelTextDim: Config.subtext0

    // Controls.
    readonly property int controlHeight: Config.bar.control.height
    readonly property int controlRadius: Config.bar.control.radius
    readonly property int controlSpacing: Config.bar.control.spacing
    readonly property int controlPadding: Config.bar.control.padding
    readonly property int infoSpacing: Config.bar.control.infoSpacing
    readonly property int sliderHeight: Config.bar.slider.height
    readonly property int sliderTrackHeight: Config.bar.slider.trackHeight
    readonly property int togglePillWidth: Config.bar.toggle.pillWidth
    readonly property int togglePillHeight: Config.bar.toggle.pillHeight
    readonly property int toggleKnobSize: Config.bar.toggle.knobSize
    readonly property int toggleKnobMargin: Config.bar.toggle.knobMargin
    // Resting input/field background, shared with the app launcher (Config.field).
    // Active/hover step up the palette ramp from it for subtle feedback.
    readonly property color controlColor: Config.field
    readonly property color controlActiveColor: Config.surface0
    readonly property color controlHoverColor: Config.surface1
    readonly property color controlBorder: Config.overlay0
    readonly property color sliderTrack: Config.surface1

    // Motion lives in common/Anim.qml, which reads config.js directly — it is
    // shell-wide, not bar-specific, and the launcher is a separate quickshell
    // instance that cannot import this module.

    // Timings.
    readonly property int hoverMs: Config.bar.timing.hoverMs
    readonly property int pollMs: Config.bar.timing.pollMs
    readonly property int wifiPollMs: Config.bar.timing.wifiPollMs
    readonly property int brightnessDebounceMs: Config.bar.timing.brightnessDebounceMs
}
