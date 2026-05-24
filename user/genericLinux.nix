{ config, lib, ... }:
{
  config.targets.genericLinux = {
    enable = config.desktop.genericLinux.enable;
    nixGL = {
      defaultWrapper = "mesa";
      packages = config.desktop.genericLinux.nixGL.packages;
    };
  };
  options.desktop.genericLinux = {
    enable = lib.mkOption { type = lib.types.bool; };
    nixGL.packages = lib.mkOption { type = lib.types.attrs; };
  };
}
