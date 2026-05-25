{
  config,
  lib,
  pkgs,
  ...
}:

let
  # We use a list of attribute sets, rather than lib.mapAttrsToList, to preserve
  # the order.
  commands = [
    {
      cmd = _: config.desktop.kanata.command;
      name = "kanata";
    }
    {
      cmd = _: config.desktop.setWallpaperCmd;
      name = "wallpaper";
    }
  ];
  redirectLogs = name: cmd: "${cmd config} >> /tmp/${name}.log 2>&1";
in
{
  options.desktop.startup.allCommands = lib.mkOption {
    default = map (app: redirectLogs app.name app.cmd) (
      commands ++ config.desktop.startup.extraCommands
    );
    description = "All commands to run after the graphical session target.";
    readOnly = true;
    type = lib.types.listOf lib.types.str;
  };
  options.desktop.startup.extraCommands = lib.mkOption {
    default = [ ];
    description = "Extra commands to run after the graphical session target";
    type = lib.types.listOf lib.types.attrs;
  };
}
