{
  config,
  lib,
  pkgs,
}:

let
  kanata = (import ./kanata/kanata.nix { inherit pkgs; });
  openrgb = import ./openrgb.nix { inherit pkgs; };
  redirectLogs = name: cmd: "${cmd} >> /tmp/${name}.log 2>&1";
in
{
  # We use a list of attribute sets, rather than lib.mapAttrsToList, to preserve
  # the order.
  commands = map (app: redirectLogs app.name app.cmd) [
    {
      name = "kanata";
      cmd = kanata.cmd;
    }
    {
      name = "wallpaper";
      cmd = config.desktop.setWallpaperCmd;
    }
    {
      name = "openrgb";
      cmd = openrgb.cmd;
    }
    {
      name = "1password";
      cmd = "1password --silent";
    }
  ];
}
