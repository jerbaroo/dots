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
  options.desktop.setWallpaperCmd = lib.mkOption {
    default = "${pkgs.awww}/bin/awww img ${wallpaperPath}";
    description = "Command to set the current wallpaper.";
    readOnly = true;
    type = lib.types.str;
  };
  options.desktop.wallpaper = lib.mkOption {
    default = toString wallpaperPath;
    description = "The wallpaper as a string.";
    readOnly = true;
    type = lib.types.str;
  };
  options.desktop.wallpaperName = lib.mkOption {
    default = "jellyfish-purple.jpg";
    description = "The filename of the wallpaper.";
    type = lib.types.str;
  };
  options.desktop.wallpaperBlurred = lib.mkOption {
    default = pkgs.runCommand "blur-image" {
      nativeBuildInputs = [ pkgs.imagemagick ];
    } "magick ${wallpaperPath} -blur 20x20 $out";
    description = "A derivation that produces the blurred wallpaper.";
    readOnly = true;
    type = lib.types.package;
  };
}
