{
  config,
  ghdashboardPort,
  pkgs,
  username,
}:
let
  ghdashboard = import ./ghdashboard.nix { inherit ghdashboardPort pkgs username; };
  kanata = (import ./kanata/kanata.nix { inherit pkgs; });
  openrgb = import ./openrgb.nix { inherit pkgs; };
in
{
  commands = [
    kanata.cmd
    config.desktop.setWallpaperCmd
    openrgb.cmd
    "ignis init >> /tmp/ignis.log 2>&1"
    "${ghdashboard.cmd}"
    "1password --silent"
  ];
}
