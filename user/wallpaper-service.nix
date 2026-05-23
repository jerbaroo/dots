{ config, pkgs, ... }:
{
  services.awww.enable = true;
  services.hyprpaper = {
    enable = false;
    settings = {
      ipc = "off";
      preload = [ config.desktop.wallpaper ];
      splash = false;
      wallpaper = [ ",${config.desktop.wallpaper}" ];
    };
  };
}
