{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = {
    desktop.audio = {
      guiCmd = lib.getExe pkgs.pwvucontrol;
      guiTitle = "Volume Control";
    };
    home.packages = [
      pkgs.dbus # TODO
      pkgs.gnugrep # TODO
      pkgs.playerctl
    ];
  };
  options.desktop.audio = {
    guiCmd = lib.mkOption {
      description = "Command to start the audio GUI.";
      readOnly = true;
      type = lib.types.str;
    };
    guiTitle = lib.mkOption {
      description = "Window title for the audio GUI.";
      readOnly = true;
      type = lib.types.str;
    };
  };
}
