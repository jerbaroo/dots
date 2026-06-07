{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = {
    desktop.bluetooth = {
      guiCmd = "${pkgs.blueman}/bin/blueman-manager";
      guiTitle = "Bluetooth Manager";
    };
    home.packages = with pkgs; [ blueman ];
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
