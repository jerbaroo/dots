{
  accent,
  flavor,
  pkgs,
  ...
}:
{
  catppuccin = {
    accent = accent;
    enable = true;
    flavor = flavor;
  };
  programs.dconf.enable = true;
  programs.hyprland.enable = true;
  xdg.portal = {
    # For NixOS 24.05 and newer we must explicitly map portals. This tells the
    # system to use the GTK portal for GTK-specific settings.
    enable = true;
    extraPortals = [
      # pkgs.xdg-desktop-portal
      pkgs.xdg-desktop-portal-gtk
      # pkgs.xdg-desktop-portal-hyprland
    ];
    config.common = {
      default = [ "*" ];
      # "org.freedesktop.impl.portal.Settings" = [ "gtk" ];
    };
    # config.hyprland.default = [ "hyprland" "gtk" ];
  };
}
