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
    iconSize: 16,
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
    iconSize: 64,
    searchHeight: 128,
    rowHeight: 96,
    textSpacing: 8,
};

// Notifications (individual and notification center).
// Inset from the screen edges = Hyprland's gaps_out (gap * 2), so the panels
// align with the tiled-window area; 'top' additionally clears the menu bar.
const notification = {
    top: barHeight + 2 * gap,
    right: 2 * gap,
    radius: rounding,
};
