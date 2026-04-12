{ pkgs, wallpaperName, ... }:
let
  wallpaperBlurred =
    (import ./wallpaper.nix {
      inherit pkgs;
      inherit wallpaperName;
    }).wallpaperBlurred;
  wallpaperBlurredPath = ".config/wallpaper-blurred.jpg";
in
{
  home.file.${wallpaperBlurredPath}.source = wallpaperBlurred;
}
