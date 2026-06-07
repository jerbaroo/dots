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
  options.desktop.monitor = {
    hdr.auto = lib.mkOption {
      default = true;
      description = "Enable auto HDR.";
      type = lib.types.bool;
    };
    onChange = lib.mkOption {
      default = onChange;
      description = "Command to run when connected monitors change.";
      readOnly = true;
      type = lib.types.package;
    };
    temperature = lib.mkOption {
      default = 5500;
      description = "Temperature ";
      type = lib.types.nullOr (lib.types.ints.between 1000 10000);
    };
  };
}
