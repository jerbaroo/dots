{
  os-cli,
  pkgs,
  wallpaperName,
}:
let
  onChange = pkgs.writeShellScript "monitor-on-change" ''
    ${setWallpaperCmd}
    ${os-cli.ui-reload}
  '';
  setWallpaperCmd = (import ./wallpaper.nix { inherit pkgs wallpaperName; }).setWallpaperCmd;
in
{
  inherit onChange;
}
