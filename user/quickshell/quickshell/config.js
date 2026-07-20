.pragma library

const font = {
    family: "Cascadia Mono",
    pixelSize: {
        xlarge: 22,
        large: 20,
        medium: 18,
        small: 16,
        xsmall: 14,
    },
};

const spacing = {
    large: 32,
    medium: 16,
};

// Menu bar. Colors are not configured here: they all derive from the Theme
// module (see bar/Style.qml).
const bar = {
    height: 30,
    padding: 10,
    iconSize: 16,
    chip: {
        height: 26,
        paddingH: 12,
        radius: 5,
        gap: 8,
        contentGap: 5,
    },
    workspace: {
        gap: 5,
        minWidth: 40,
    },
    tray: {
        // System tray icons to hide, matched case-insensitively as a
        // substring of the item's tray id. Used to drop duplicates of modules
        // the bar already provides (e.g. blueman's bluetooth icon).
        exclude: ["blueman"],
    },
    dot: {
        size: 4,
        gap: 3,
    },
    panel: {
        width: 200,
        gap: 6,
        padding: 12,
        radius: 8,
        spacing: 8,
    },
    control: {
        height: 26,
        radius: 4,
        spacing: 4,
        padding: 8,
        infoSpacing: 3,
    },
    slider: {
        height: 16,
        trackHeight: 6,
    },
    toggle: {
        pillWidth: 22,
        pillHeight: 12,
        knobSize: 8,
        knobMargin: 2,
    },
    timing: {
        hoverMs: 100,
        pollMs: 3000,
        wifiPollMs: 10000,
        brightnessDebounceMs: 300,
    },
};

// App launcher. Sized relative to the screen, capped for large monitors.
const launcher = {
    widthFraction: 0.4,
    maxWidth: 640,
    heightFraction: 0.7,
    maxHeight: 960,
    padding: 16,
    radius: 8,
    iconSize: 64,
    searchHeight: 128,
    rowHeight: 96,
    textSpacing: 8,
};
