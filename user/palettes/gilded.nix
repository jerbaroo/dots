# https://github.com/rccyx/osyx/blob/main/packages/flavors/palettes/gilded.toml
# Map Gilded's warm ANSI colors and UI shades onto the desktop's Catppuccin roles.
builtins.mapAttrs (_: hex: { inherit hex; }) {
  base = "#0b0d0a";
  blue = "#ca8732";
  crust = "#0b0d0a";
  flamingo = "#f0bf6b";
  green = "#ca8732";
  lavender = "#d19a45";
  mantle = "#17140e";
  maroon = "#c86b2b";
  mauve = "#a15c1d";
  overlay0 = "#9a7447";
  overlay1 = "#b86a22";
  overlay2 = "#ca8732";
  peach = "#c86b2b";
  pink = "#ca8732";
  red = "#ff6a3d";
  rosewater = "#fff1cf";
  sapphire = "#894418";
  sky = "#b86a22";
  subtext0 = "#d19a45";
  subtext1 = "#f0bf6b";
  surface0 = "#332618";
  surface1 = "#653714";
  surface2 = "#894418";
  teal = "#894418";
  text = "#efe2c7";
  yellow = "#d19a45";
}
