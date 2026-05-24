{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = {
    desktop.audio = {
      guiCmd = "ghostty --title=${config.desktop.audio.guiTitle} -e ${pkgs.wiremix}/bin/wiremix --tab output";
      guiTitle = "wiremix";
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
