{
  config,
  lib,
  pkgs,
  system,
  ...
}:
let
  cli =
    let
      python = pkgs.python3.withPackages (ps: with ps; [ click ]);
    in
    pkgs.writeShellScriptBin "os" ''
      export OS_AUDIO_GUI_CMD="${config.desktop.audio.guiCmd}"
      export OS_BLUETOOTH_GUI_CMD="${config.desktop.bluetooth.guiCmd}"
      export OS_GRIM_PATH="${pkgs.grim}/bin/grim"
      export OS_NH_PATH="${pkgs.nh}/bin/nh"
      export OS_HOSTNAME="${config.desktop.hostname}"
      export OS_HYPRCTL_PATH="${config.desktop.hyprland.package}/bin/hyprctl"
      export OS_IGNIS_PATH="${config.desktop.ignis.package}/bin/ignis"
      export OS_KANATA_CMD="${config.desktop.kanata.command}"
      export OS_USERNAME="${config.desktop.username}"
      export OS_SLURP_PATH="${pkgs.slurp}/bin/slurp"
      export OS_SWAPPY_PATH="${pkgs.swappy}/bin/swappy"
      exec ${python}/bin/python3 ${./os_cli.py} "$@"
    '';
  mkCmd = args: "${cli}/bin/os ${args}";
in
{
  # Packages to be exported to ease development of the CLI outside Nix.
  config.home.packages = with pkgs; [
    cli
    grim
    nh
    slurp
    swappy
  ];
  # Commands available via CLI in type-safe wrappers.
  # TODO avoid going through Python.
  options.desktop.cli = lib.mkOption {
    description = "Nix interface to the CLI.";
    type = lib.types.submodule {
      options = {
        home.switch = lib.mkOption {
          default = mkCmd "home switch";
          description = "Switch home-manager configuration.";
          readOnly = true;
          type = lib.types.str;
        };
        monitor.current = lib.mkOption {
          default = mkCmd "monitor current";
          description = "Inspect current monitor.";
          readOnly = true;
          type = lib.types.str;
        };
        nixos.switch = lib.mkOption {
          default = mkCmd "nixos switch";
          description = "Switch the NixOS configuration.";
          readOnly = true;
          type = lib.types.str;
        };
        screenshot = lib.mkOption {
          default = mkCmd "screenshot";
          description = "Take a screenshot.";
          readOnly = true;
          type = lib.types.str;
        };
        ui = lib.mkOption {
          description = "GUI commands.";
          type = lib.types.submodule {
            options = {
              reload = lib.mkOption {
                default = mkCmd "ui reload";
                description = "Reload the desktop UI.";
                readOnly = true;
                type = lib.types.str;
              };
              appLauncher.toggle = lib.mkOption {
                default = mkCmd "ui app-launcher toggle";
                description = "Toggle the app launcher.";
                readOnly = true;
                type = lib.types.str;
              };
              lockScreen.toggle = lib.mkOption {
                default = mkCmd "ui lock-screen toggle";
                description = "Toggle the lock screen.";
                readOnly = true;
                type = lib.types.str;
              };
              logoutMenu.toggle = lib.mkOption {
                default = mkCmd "ui logout-menu toggle";
                description = "Toggle the power/logout menu.";
                readOnly = true;
                type = lib.types.str;
              };
              menuBar.toggle = lib.mkOption {
                default = mkCmd "ui menu-bar toggle";
                description = "Toggle the menu bar.";
                readOnly = true;
                type = lib.types.str;
              };
            };
          };
        };
      };
    };
  };
}
