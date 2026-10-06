{ pkgs, ... }:
{
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config = {
      common.default = [ "gtk" ];
      hyprland = {
        default = [
          "hyprland"
          "gtk"
        ];
        # Explicitly tell Hyprland to handle what it's meant to handle.
        "org.freedesktop.portal.ScreenCast" = [ "hyprland" ];
        "org.freedesktop.portal.Screenshot" = [ "hyprland" ];
      };
    };
  };
}
