pragma Singleton
import QtQuick
import Quickshell
import qs.bar

// Coordinates the single shared hover panel (see HoverPanel.qml): which chip's
// panel is shown, with open/close grace timing so the cursor can travel between
// a chip and the panel, or between adjacent chips, without it flickering shut.
Singleton {
    id: root

    // The chip whose panel is displayed (null = hidden).
    property Item activeChip: null
    // The chip currently under the cursor that has a panel, or null.
    property Item hoveredChip: null
    // True while the cursor is over the shared panel itself.
    property bool panelHovered: false

    // Refresh hook (e.g. wifi scan) when a chip's panel becomes visible.
    onActiveChipChanged: if (activeChip)
        activeChip.panelOpening()

    // A chip reports the cursor entered it (only chips with a panel call this).
    function request(chip) {
        hoveredChip = chip;
        closeTimer.stop();
        if (activeChip !== null)
            activeChip = chip; // already open: switch instantly, the panel slides
        else
            openTimer.restart(); // closed: open after the hover delay
    }

    // A chip reports the cursor left it.
    function release(chip) {
        if (hoveredChip === chip)
            hoveredChip = null;
        closeTimer.restart();
    }

    // The shared panel reports the cursor entering/leaving it: entering keeps
    // it open, leaving starts the close grace period.
    function setPanelHovered(hovered) {
        panelHovered = hovered;
        if (hovered)
            closeTimer.stop();
        else
            closeTimer.restart();
    }

    Timer {
        id: openTimer
        interval: Style.hoverMs
        onTriggered: if (root.hoveredChip)
            root.activeChip = root.hoveredChip
    }

    Timer {
        id: closeTimer
        interval: Style.hoverMs
        onTriggered: if (!root.panelHovered && root.hoveredChip === null)
            root.activeChip = null
    }
}
