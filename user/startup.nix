{
  ghdashboardPort,
  pkgs,
  username,
  wallpaperName,
}:
let
  ghdashboard = import ./ghdashboard.nix { inherit ghdashboardPort pkgs username; };
  kanata = (import ./kanata/kanata.nix { inherit pkgs; });
  openrgb = import ./openrgb.nix { inherit pkgs; };
  setWallpaperCmd = (import ./wallpaper.nix { inherit pkgs wallpaperName; }).setWallpaperCmd;
in
{
  commands = [
    kanata.cmd
    setWallpaperCmd
    openrgb.cmd
    "ignis init >> /tmp/ignis.log 2>&1"
    "${ghdashboard.cmd}"
    "1password --silent"
  ];
}
