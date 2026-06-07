{
  config,
  lib,
  pkgs,
  ...
}:
let
  themeName = "Colloid-${pkgs.lib.strings.toSentenceCase config.desktop.theme.accent}-Dark-Catppuccin";
  themePkg = pkgs.colloid-gtk-theme.override {
    tweaks = [
      "black"
      "catppuccin"
      "normal"
      "float"
      "rimless"
    ];
    themeVariants = [ config.desktop.theme.accent ];
  };
in
{
  config = {
    # We use nix-catppuccin to style some apps. Notably not GTK.
    catppuccin = {
      accent = config.desktop.theme.accent;
      autoEnable = true;
      enable = true;
      flavor = config.desktop.theme.flavor;
    };

    # Cursors.
    # ls /etc/profiles/per-user/jer/share/icons
    catppuccin.cursors.enable = false;
    home.pointerCursor = {
      gtk.enable = true;
      name = "catppuccin-${config.desktop.theme.flavor}-${config.desktop.theme.accent}-cursors";
      package =
        pkgs.catppuccin-cursors."${config.desktop.theme.flavor}${pkgs.lib.strings.toSentenceCase config.desktop.theme.accent}";
      # x11.enable = true;
    };

    # GTK.
    catppuccin.gtk.icon.enable = false;
    gtk = {
      enable = true;
      # Icons.
      # ls /etc/profiles/per-user/jer/share/icons
      iconTheme = {
        name = "Papirus";
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
      type = lib.types.str;
    };
    palette = lib.mkOption {
      default =
        (pkgs.lib.importJSON (config.catppuccin.sources.palette + "/palette.json"))
        .${config.desktop.theme.flavor}.colors;
      description = "Palette of colours for the selected Catppuccin theme.";
      readOnly = true;
      type = lib.types.attrs;
    };
  };
}
