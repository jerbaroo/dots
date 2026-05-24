{
  config,
  lib,
  pkgs,
}:

let
  redirectLogs = name: cmd: "${cmd} >> /tmp/${name}.log 2>&1";
in
{
  # We use a list of attribute sets, rather than lib.mapAttrsToList, to preserve
  # the order.
  commands = map (app: redirectLogs app.name app.cmd) [
    {
      cmd = config.desktop.kanata.command;
      name = "kanata";
    }
    {
      cmd = config.desktop.setWallpaperCmd;
      name = "wallpaper";
    }
    {
      cmd = config.desktop.openrgb.command;
      name = "openrgb";
    }
    {
      cmd = "1password --silent";
      name = "1password";
    }
  ];
}
