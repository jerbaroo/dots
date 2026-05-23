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
      pkgs.dbus
      pkgs.gnugrep
      pkgs.playerctl
    ];
    # systemd.user.services.pause-on-bt-disconnect = {
    #   Unit = {
    #     Description = "Pause media player on Bluetooth disconnect";
    #     After = [ "dbus.socket" ];
    #   };
    #   Service = {
    #     ExecStart = ''
    #       ${pkgs.runtimeShell}/bin/sh -c '
    #         echo "Monitoring Bluetooth disconnects..."
    #         ${pkgs.dbus}/bin/busctl --user monitor org.bluez | while read -r line; do
    #           # Look for the signal that a device interface was removed
    #           if echo "$line" | ${pkgs.gnugrep}/bin/grep -q "InterfaceRemoved" && echo "$line" | ${pkgs.gnugrep}/bin/grep -q "org.bluez.Device1"; then
    #             echo "Bluetooth device disconnected, pausing media."
    #             ${pkgs.playerctl}/bin/playerctl pause
    #           fi
    #         done
    #       '
    #     '';
    #     Restart = "on-failure";
    #     RestartSec = "5";
    #   };
    #   Install = {
    #     WantedBy = [ "default.target" ];
    #   };
    # };
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
