{ pkgs, wallpaperName, ... }:
let
  wallpaper = builtins.toString wallpaperPath;
  wallpaperPath = ./wallpapers/${wallpaperName};
in
{
  inherit wallpaper wallpaperPath;
  setWallpaperCmd = "${pkgs.awww}/bin/awww img ${wallpaperPath}";
  wallpaperBlurred = pkgs.runCommand "blur-image" {
    nativeBuildInputs = [ pkgs.imagemagick ];
  } "magick ${wallpaperPath} -blur 20x20 $out";
}
