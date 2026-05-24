{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = {
    home.file.${config.desktop.ignis.configDir.path} = {
      recursive = true;
      source = ./ignis;
    };
    # Write command paths to a fixed location, to be picked up at run-time.
    home.file."${config.desktop.ignis.configDir.path}/nix_paths.py".text = ''
      AUDIO_GUI_CMD="${config.desktop.audio.guiCmd}"
      BLUETOOTH_GUI_CMD="${config.desktop.bluetooth.guiCmd}"
      DESK_CMD="${pkgs.idasen}/bin/idasen"
      POWER_PROFILES_CMD="${pkgs.power-profiles-daemon}/bin/powerprofilesctl"
    '';
    # Write theme colours to a fixed location, to be picked up at run-time.
    home.file."${config.desktop.ignis.configDir.path}/colors.scss".text = ''
      $accent: ${config.desktop.theme.palette.${config.desktop.theme.accent}.hex};
      $base: ${config.desktop.theme.palette.base.hex};
      $crust: ${config.desktop.theme.palette.crust.hex};
      $mantle: ${config.desktop.theme.palette.mantle.hex};
      $red: ${config.desktop.theme.palette.red.hex};
      $yellow: ${config.desktop.theme.palette.yellow.hex};
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
  options.desktop.ignis = {
    bar.namespace.regex = lib.mkOption {
      default = "^(ignis-bar-.*)$";
      description = "Regex that will match the menu bar namespace.";
      readOnly = true;
      type = lib.types.str;
    };
    configDir.path = lib.mkOption {
      description = "Path relative to $HOME to the ignis config directory.";
      type = lib.types.str;
    };
    package = lib.mkOption {
      description = "Package containing ignis";
      type = lib.types.package;
    };
  };
}
