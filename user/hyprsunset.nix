{ config, lib, ... }:
{
  options.desktop.hyprsunset.temperature = lib.mkOption {
    type = lib.types.nullOr (lib.types.ints.between 1000 10000);
  };
  config = lib.mkIf (config.desktop.hyprsunset.temperature != null) {
    services.hyprsunset = {
      enable = true;
      extraArgs = [
        "-t"
        "${toString config.desktop.hyprsunset.temperature}"
      ];
    };
  };
}
