{
  config,
  lib,
  pkgs,
  ...
}:
let
  palettes = import ./palettes;
  themeAccent =
    {
      peach = "orange";
      lavender = "purple";
      sapphire = "teal";
    }
    .${config.desktop.theme.accent} or config.desktop.theme.accent;
  themeName = "Colloid-${pkgs.lib.strings.toSentenceCase themeAccent}-Dark-Catppuccin";
  colloid = pkgs.colloid-gtk-theme.override {
    tweaks = [
      "black"
      "catppuccin"
      "normal"
      "float"
      "rimless"
    ];
    themeVariants = [ themeAccent ];
  };
  # Colloid compiles the flavour's colours into its stylesheets and SVG assets,
  # so GTK does not follow desktop.theme.palette (see paletteChanges below).
  # Rewrite the colours that differ.
  #
  # Only regular files are touched: each variant's gtk.css is a relative symlink
  # into the shared stylesheets, which stays valid inside the copy and picks up
  # the rewritten content, so editing it too would only turn the link into a
  # duplicate. Nothing to rewrite means the original package, untouched.
  themePkg =
    if config.desktop.theme.paletteChanges == { } then
      colloid
    else
      pkgs.runCommandLocal "${colloid.name}-repalette" { } ''
        cp -r ${colloid} $out
        chmod -R u+w $out
        find $out -type f \( -name '*.css' -o -name '*.svg' -o -name 'gtkrc' \) -print0 \
          | xargs -0 --no-run-if-empty sed -i ${
            lib.concatMapStringsSep " " (colour: "-e 's/${colour.from}/${colour.to}/gI'") (
              lib.attrValues config.desktop.theme.paletteChanges
            )
          }
      '';
  # OLED overrides (mocha only).
  oledOverrides = {
    base = {
      hex = "#000000";
      rgb = {
        r = 0;
        g = 0;
        b = 0;
      };
      hsl = {
        h = 0;
        s = 0.0;
        l = 0.0;
      };
      oklch = {
        l = 0.0;
        c = 0.0;
        h = 0.0;
      };
    };
    mantle = {
      hex = "#010101";
      rgb = {
        r = 1;
        g = 1;
        b = 1;
      };
      hsl = {
        h = 0;
        s = 0.0;
        l = 0.00392156862745098;
      };
      oklch = {
        l = 0.06720461569746487;
        c = 0.0;
        h = 0.0;
      };
    };
    crust = {
      hex = "#020202";
      rgb = {
        r = 2;
        g = 2;
        b = 2;
      };
      hsl = {
        h = 0;
        s = 0.0;
        l = 0.00784313725490196;
      };
      oklch = {
        l = 0.0846725099673314;
        c = 0.0;
        h = 0.0;
      };
    };
  };
in
{
  config = {
    home.pointerCursor = {
      enable = true;
      gtk.enable = true;
      name = "catppuccin-mocha-${config.desktop.theme.accent}-cursors";
      package =
        pkgs.catppuccin-cursors."mocha${pkgs.lib.strings.toSentenceCase config.desktop.theme.accent}";
      # x11.enable = true;
    };

    # GTK.
    gtk = {
      enable = true;
      # Icons.
      # ls /etc/profiles/per-user/jer/share/icons
      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };
      gtk4.extraConfig = {
        gtk-application-prefer-dark-theme = 1;
      };
      # GTK Theme.
      # ls /etc/profiles/per-user/jer/share/themes
      theme = {
        name = themeName;
        package = themePkg;
      };
    };
    xdg.configFile = {
      "gtk-4.0/assets".source = "${themePkg}/share/themes/${themeName}/gtk-4.0/assets";
      "gtk-4.0/gtk.css".source = "${themePkg}/share/themes/${themeName}/gtk-4.0/gtk.css";
    };
  };
  options.desktop.theme = {
    accent = lib.mkOption {
      type = lib.types.str;
    };
    colorSchemes = lib.mkOption {
      description = "iTerm color schemes, for terminal themeing.";
      type = lib.types.attrs;
    };
    flavor = lib.mkOption {
      description = "Desktop color palette.";
      type = lib.types.enum (builtins.attrNames palettes);
    };
    oled = lib.mkOption {
      default = true;
      description = "Darken the palette's backgrounds for OLED panels.";
      type = lib.types.bool;
    };
    palette = lib.mkOption {
      default =
        let
          upstream = palettes.${config.desktop.theme.flavor};
        in
        if config.desktop.theme.oled then
          upstream // lib.mapAttrs (name: override: upstream.${name} // override) oledOverrides
        else
          upstream;
      description = "Colors from the selected desktop palette, including OLED overrides.";
      readOnly = true;
      type = lib.types.attrs;
    };
    paletteChanges = lib.mkOption {
      default =
        let
          upstream = palettes.mocha;
        in
        lib.filterAttrs (_: colour: colour.from != colour.to) (
          lib.mapAttrs (name: colour: {
            from = lib.toLower colour.hex;
            to = lib.toLower config.desktop.theme.palette.${name}.hex;
          }) upstream
        );
      description = "Calculated list of changes to apply to the palette";
      readOnly = true;
      type = lib.types.attrs;
    };
  };
}
