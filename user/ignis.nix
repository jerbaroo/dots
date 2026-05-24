{
  accent,
  config,
  ignis,
  ignisPath,
  palette,
  pkgs,
  ...
}:
{
  barRegex = "^(ignis-bar-.*)$";
  hm = {
    home.file.${ignisPath} = {
      recursive = true;
      source = ./ignis;
    };
    # Write command paths to a fixed location, to be picked up at run-time.
    home.file."${ignisPath}/nix_paths.py".text = ''
      AUDIO_GUI_CMD="${config.desktop.audio.guiCmd}"
      BLUETOOTH_GUI_CMD="${config.desktop.bluetooth.guiCmd}"
      DESK_CMD="${pkgs.idasen}/bin/idasen"
      POWER_PROFILES_CMD="${pkgs.power-profiles-daemon}/bin/powerprofilesctl"
    '';
    # Write theme colours to a fixed location, to be picked up at run-time.
    home.file."${ignisPath}/colors.scss".text = ''
      $accent: ${palette.${accent}.hex};
      $base: ${palette.base.hex};
      $crust: ${palette.crust.hex};
      $mantle: ${palette.mantle.hex};
      $red: ${palette.red.hex};
      $yellow: ${palette.yellow.hex};
    '';
    programs.ignis = {
      enable = true;
      extraPackages = with pkgs; [
        gnome-bluetooth
        libnotify
        power-profiles-daemon
      ];
      sass = {
        enable = true;
        useDartSass = true;
      };
      services = {
        audio.enable = true;
        bluetooth.enable = true;
        # recorder.enable = true;
        # network.enable = true;
      };
    };
    # When starting ignis via hyprland hook, the GTK theme was not being applied
    # due to what seemed to be an XDG portal permission issue.
    systemd.user.services.ignis = {
      Unit = {
        After = [
          "graphical-session.target"
          "xdg-desktop-portal.service"
        ];
        Description = "Ignis Shell";
        BindsTo = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${config.programs.ignis.finalPackage}/bin/ignis init";
        Restart = "on-failure";
      };
      # Ready to run on graphical session start, but still needs to wait on
      # targets in "After".
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
