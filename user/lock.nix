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
  config = {
    home.packages = [
      # We make sure that, regardless of the locking program, it can be found
      # at the same command. TODO use CLI for this.
      (pkgs.writeShellScriptBin "os-lock" "exec ${config.desktop.lock.cmd}")
    ];
  };
}
