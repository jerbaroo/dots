{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = {
    desktop.bluetooth = {
      guiCmd = "ghostty --title=${config.desktop.bluetooth.guiTitle} -e ${pkgs.bluetui}/bin/bluetui";
      guiTitle = "bluetui";
    };
    # Blueman is a reliable fallback.
    home.packages = with pkgs; [ blueman ];
    # Daemon required for blueman.
    services.blueman-applet.enable = true;
  };
  options.desktop.bluetooth = {
    guiCmd = lib.mkOption {
      description = "Command to start the bluetooth GUI.";
      readOnly = true;
      type = lib.types.str;
    };
    guiTitle = lib.mkOption {
      description = "Window title for the bluetooth GUI.";
      readOnly = true;
      type = lib.types.str;
    };
  };
}
