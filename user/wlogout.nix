{ pkgs, wallpaperName, ... }:
let
  # TODO move to os-commands module.
  os-logout-menu = pkgs.writeShellScriptBin "os-logout-menu" "ignis toggle-window ignis-logout-menu-0";
  wallpaperBlurred = (import ./wallpaper.nix { inherit pkgs; inherit wallpaperName; }).wallpaperBlurred;
  wallpaperBlurredPath = ".config/wallpaper-blurred.jpg";
in {
  home.file.${wallpaperBlurredPath}.source = wallpaperBlurred;
  home.packages = [ os-logout-menu ];
}
