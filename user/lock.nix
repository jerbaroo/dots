{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.desktop.lock = {
    cmd = lib.mkOption {
      default = "${lib.getExe config.programs.foyer.package} lock";
      type = lib.types.str;
    };
    timeout = lib.mkOption {
      default =
        let
          oneMinute = 60;
        in
        10 * oneMinute;
      description = "Time until system locks.";
      type = lib.types.ints.unsigned;
    };
  };
}
