{
  config,
  lib,
  pkgs,
  ...
}:
let
  package = pkgs.overskride;
in
{
  config = {
    desktop.bluetooth = {
      guiCmd = lib.getExe package;
      guiTitle = "Bluetooth Manager";
    };
    home.packages = [ package ];
    # services.blueman-applet.enable = true;
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
