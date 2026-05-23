{ config, ... }:
let
  wallpaperBlurredPath = ".config/wallpaper-blurred.jpg";
in
{
  home.file.${wallpaperBlurredPath}.source = config.desktop.wallpaperBlurred;
}
