{
  config,
  lib,
  pkgs,
  ...
}:
let
  onChange = pkgs.writeShellScript "monitor-on-change" ''
    ${config.desktop.setWallpaperCmd}
    ${config.desktop.cli.ui.reload}
  '';
in
{
  options.desktop.monitor.onChange = lib.mkOption {
    default = onChange;
    description = "Command to run when connected monitors change.";
    readOnly = true;
    type = lib.types.package;
  };
}
