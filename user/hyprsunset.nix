{ config, lib, ... }:
{
  config = lib.mkIf (config.desktop.monitor.temperature != null) {
    services.hyprsunset = {
      enable = true;
      extraArgs = [
        "-t"
        "${toString config.desktop.monitor.temperature}"
      ];
    };
  };
}
