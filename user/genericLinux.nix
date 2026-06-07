{ config, lib, ... }:
{
  config.targets.genericLinux = {
    enable = config.desktop.genericLinux.enable;
    nixGL.packages = config.desktop.genericLinux.nixGL.packages;
  };
  # This indirection ensures we require the options, since they are used above.
  options.desktop.genericLinux = {
    enable = lib.mkOption {
      type = lib.types.bool;
    };
    nixGL.packages = lib.mkOption {
      type = lib.types.nullOr lib.types.attrs;
    };
  };
}
