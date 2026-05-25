{
  accent,
  flavor,
  pkgs,
  ...
}:
let
  themeName = "catppuccin-${flavor}-${accent}-standard+black,rimless";
  themePkg = pkgs.catppuccin-gtk.override {
    accents = [ "${accent}" ];
    tweaks = [
      "black"
      "rimless"
    ];
    variant = "${flavor}";
  };
in
{
  catppuccin = {
    accent = "${accent}";
    enable = true;
    flavor = "${flavor}";
    gtk.icon.enable = false;
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
