{ pkgs, wallpaperName, ... }:
let
  wallpaper = (import ./wallpaper.nix { inherit pkgs; inherit wallpaperName; }).wallpaper;
in
{
  services.hyprpaper = {
    enable = false;
    settings = {
      ipc = "off";
      preload = [ wallpaper ];
      splash = false;
      wallpaper = [ ",${wallpaper}" ];
    };
  };
  services.swww.enable = true;
}
