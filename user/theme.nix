{
  accent,
  flavor,
  pkgs,
  ...
}:
let
  themeName = "Colloid-${pkgs.lib.strings.toSentenceCase accent}-Dark-Catppuccin";
  themePkg = pkgs.colloid-gtk-theme.override {
    tweaks = [
      "black"
      "catppuccin"
      "normal"
      "float"
      "rimless"
    ];
    themeVariants = [ accent ];
  };
in
{
  # We use nix-catppuccin to style some apps. Notably not GTK.
  catppuccin = {
    inherit accent flavor;
    autoEnable = true;
    enable = true;
  };

  # Cursors.
  # ls /etc/profiles/per-user/jer/share/icons
  catppuccin.cursors.enable = false;
  home.pointerCursor = {
    gtk.enable = true;
    name = "catppuccin-${flavor}-${accent}-cursors";
    package = pkgs.catppuccin-cursors."${flavor}${pkgs.lib.strings.toSentenceCase accent}";
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
}
