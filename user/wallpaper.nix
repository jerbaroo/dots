{
  config,
  lib,
  pkgs,
  ...
}:
let
  wallpaperPath = ./wallpapers/${config.desktop.wallpaperName};
in
{
  config = {
    desktop = {
      setWallpaperCmd = "${pkgs.awww}/bin/awww img ${wallpaperPath}";
      wallpaper = toString wallpaperPath;
      wallpaperBlurred = pkgs.runCommand "blur-image" {
        nativeBuildInputs = [ pkgs.imagemagick ];
      } "magick ${wallpaperPath} -blur 20x20 $out";
    };
  };
  options.desktop.setWallpaperCmd = lib.mkOption {
    description = "Command to set the current wallpaper.";
    readOnly = true;
    type = lib.types.str;
  };
  options.desktop.wallpaper = lib.mkOption {
    description = "The wallpaper as a string.";
    readOnly = true;
    type = lib.types.str;
  };
  options.desktop.wallpaperName = lib.mkOption {
    description = "The filename of the wallpaper.";
    type = lib.types.str;
  };
  options.desktop.wallpaperBlurred = lib.mkOption {
    description = "A derivation that produces the blurred wallpaper.";
    readOnly = true;
    type = lib.types.package;
  };
}
