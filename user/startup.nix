{
  config,
  pkgs,
  username,
}:
let
  kanata = (import ./kanata/kanata.nix { inherit pkgs; });
  openrgb = import ./openrgb.nix { inherit pkgs; };
in
{
  commands = [
    kanata.cmd
    config.desktop.setWallpaperCmd
    openrgb.cmd
    "1password --silent"
  ];
}
