.pragma library

// Raw Hyprland configuration values, substituted by Nix.
const hyprlandBorderSize = @hyprlandBorderSize@;
const hyprlandGap = @hyprlandGap@;
const hyprlandRounding = @hyprlandRounding@;

// Flag file whose presence suppresses hypridle locking / screen-off. Shared
// with hypridle.nix (single source: desktop.lock.inhibitPath); the menu bar's
// "No lock" mode (see bar/Awake.qml) drops it.
const inhibitLockPath = "@inhibitLockPath@";

// Quickshell-specific translations of the Hyprland values above.
const borderSize = hyprlandBorderSize;
const gap = 2 * hyprlandGap;
const rounding = hyprlandRounding;

const shellFontSize = @shellFontSize@;
const font = {
    family: "@shellFontName@",
    pixelSize: {
        xlarge: shellFontSize + 6,
        large: shellFontSize + 4,
        medium: shellFontSize + 2,
        small: shellFontSize,
        xsmall: shellFontSize - 2,
    },
};
const spacing = {
    large: 32,
    medium: 16,
};

const iconSize = {
    small: 16,
    medium: 32,
    large: 64,
};

// Motion. Every animation belongs to one of three families (see bar/Anim.qml).
// The split between the two geometric families is the important one: they are
// different kinds of movement and want opposite curves.
//
//   spatial — geometry that materialises: the panel's reveal and its resize.
//             Overshoots, so the panel reads as arriving with some mass.
//   travel  — geometry that tracks the cursor: the panel sliding between
//             chips. Decelerates onto its target with no overshoot — you are
//             already looking at the destination chip, so a bounce past it
//             reads as imprecision rather than momentum.
//   effect  — opacity and colour. Short and monotonic; an overshooting fade
//             would flash past full opacity.
//
// Curves are cubic bezier control points in QML's easing.bezierCurve form,
// [x1, y1, x2, y2, 1, 1]. These are Material 3's "expressive" curves; the
// y > 1 in the spatial curve is the overshoot. Durations are shorter than M3's
// because the bar's popups travel a chip's width, not a screen's.
const anim = {
    spatialMs: 280,
    spatialCurve: [0.38, 1.21, 0.22, 1, 1, 1],
    travelMs: 200,
    travelCurve: [0.05, 0.7, 0.1, 1, 1, 1],
    effectMs: 150,
    effectCurve: [0.34, 0.8, 0.34, 1, 1, 1],
    // The leading half of a two-part transition, e.g. the fade-out of a
    // content swap: quicker than the fade-in, so the panel is never empty for
    // long.
    effectFastMs: 100,
};

// Colours (Catppuccin palette, substituted by Nix).
const accent = "@accent@";
const base = "@base@";
const crust = "@crust@";
const mantle = "@mantle@";
const overlay0 = "@overlay0@";
const overlay1 = "@overlay1@";
const overlay2 = "@overlay2@";
const red = "@red@";
const text = "@text@";
const subtext0 = "@subtext0@";
const subtext1 = "@subtext1@";
const surface0 = "@surface0@";
const surface1 = "@surface1@";
const surface2 = "@surface2@";
const yellow = "@yellow@";

// Overlay a "#RRGGBB" colour at alpha `a`, returning QML's "#AARRGGBB" form. A
// .pragma library cannot call Qt.alpha, so we build the string directly.
function withAlpha(hex, a) {
    const aa = ("0" + Math.round(a * 255).toString(16)).slice(-2);
    return "#" + aa + hex.slice(1);
}

// Semantic colour aliases (single source for each).
// TODO improve these names.
const field = base;
const glassTint = 0.35;
const glass = withAlpha(crust, glassTint);
const panelGlass = withAlpha(mantle, glassTint);

// Menu bar.
//
// Geometry invariant: chips are centred vertically, so the margin above/below
// a chip is (barHeight − chipHeight) / 2. We keep the gap between chips equal
// to that margin by deriving chipGap from it. Increasing chipHeight pads the
// buttons more (bar height fixed).
const barHeight = 42;
const chipHeight = 30;
const chipGap = (barHeight - chipHeight) / 2;

const bar = {
    height: barHeight,
    padding: 10,
    iconSize: iconSize.small,
    chip: {
        height: chipHeight,
        paddingH: 14,
        radius: rounding,
        gap: chipGap,
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
        width: 260,
        gap: 6,
        padding: 12,
        radius: rounding,
        spacing: 8,
        // Height of the shared, full-width popup container the visible panel
        // slides within. Generous so no panel is clipped; the empty area is
        // transparent and click-through.
        maxHeight: 600,
    },
    control: {
        height: 26,
        radius: rounding,
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

// App launcher.
const launcher = {
    widthFraction: 0.4,
    maxWidth: 640,
    heightFraction: 0.7,
    maxHeight: 960,
    padding: 16,
    radius: rounding,
    iconSize: iconSize.large,
    searchHeight: 128,
    rowHeight: 96,
    textSpacing: 8,
};

// Notifications (individual and notification center).
const notification = {
    top: barHeight + 2 * gap,
    right: 2 * gap,
    radius: rounding,
};

// On-screen display: the transient volume/brightness card.
const osd = {
    barHeight: 6,
    height: 128,
    margin: 96,
    hideMs: 1200,
    width: 256,
};
