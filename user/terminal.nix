{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.desktop.terminal = {
    # Must match the package below.
    command = lib.mkOption {
      default = "${config.desktop.terminal.package}/bin/kitty";
      readOnly = true;
      type = lib.types.str;
    };
    # Must match the command above.
    package = lib.mkOption {
      default = config.desktop.kitty.package;
      readOnly = true;
      type = lib.types.package;
    };
  };
}
