pragma Singleton
import QtQuick
import Quickshell
import Theme 0.1
import "../config.js" as Config

// The bar's visual constants (BAR.md: one variables block). All sizes, gaps
// and timings come from config.js; all colors derive from Theme.
Singleton {
    // Bar.
    readonly property int barHeight: Config.bar.height
    readonly property int barPadding: Config.bar.padding

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
    readonly property color chipColor: Qt.alpha(Theme.crust, 0.45)
    readonly property color chipColorDim: Qt.alpha(Theme.crust, 0.3)
    readonly property color chipBorder: Qt.alpha(Theme.text, 0.28)
    readonly property color chipBorderDim: Qt.alpha(Theme.text, 0.15)
    readonly property color accent: Theme.accent
    readonly property color text: Theme.text
    readonly property color textDim: Qt.alpha(Theme.text, 0.55)
    readonly property color good: Theme.accent
    readonly property color dotOff: Qt.alpha(Theme.text, 0.35)
    readonly property string fontFamily: Config.font.family
    readonly property int fontSize: Config.font.pixelSize.small
    readonly property int iconSize: Config.bar.iconSize

    // Hover panels.
    readonly property int panelWidth: Config.bar.panel.width
    readonly property int panelGap: Config.bar.panel.gap
    readonly property int panelPadding: Config.bar.panel.padding
    readonly property int panelRadius: Config.bar.panel.radius
    readonly property int panelSpacing: Config.bar.panel.spacing
    readonly property int panelFontSize: Config.font.pixelSize.small
    readonly property color panelColor: Theme.mantle
    readonly property color panelText: Theme.text
    readonly property color panelTextDim: Theme.subtext0

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
    readonly property color controlColor: Theme.surface0
    readonly property color controlActiveColor: Theme.surface1
    readonly property color controlHoverColor: Theme.surface2
    readonly property color controlBorder: Theme.overlay0
    readonly property color sliderTrack: Theme.surface1

    // Timings.
    readonly property int hoverMs: Config.bar.timing.hoverMs
    readonly property int pollMs: Config.bar.timing.pollMs
    readonly property int wifiPollMs: Config.bar.timing.wifiPollMs
    readonly property int brightnessDebounceMs: Config.bar.timing.brightnessDebounceMs
}
