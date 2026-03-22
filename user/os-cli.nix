{ ignis, hostname, hyprland, pkgs, system, username, ... }:
let
  audio = (import ./audio.nix { inherit pkgs; });
  bluetooth = (import ./bluetooth.nix { inherit pkgs; });
  cli =
    let python = pkgs.python3.withPackages (ps: with ps; [ click ]);
    in pkgs.writeShellScriptBin "os" ''
      export OS_AUDIO_GUI_CMD="${audio.guiCmd}"
      export OS_BLUETOOTH_GUI_CMD="${bluetooth.guiCmd}"
      export OS_GRIM_PATH="${pkgs.grim}/bin/grim"
      export OS_NH_PATH="${pkgs.nh}/bin/nh"
      export OS_HOSTNAME="${hostname}"
      export OS_HYPRCTL_PATH="${hyprland.packages.${system}.hyprland}/bin/hyprctl"
      export OS_IGNIS_PATH="${ignis.packages.${system}.ignis}/bin/ignis"
      export OS_USERNAME="${username}"
      export OS_SLURP_PATH="${pkgs.slurp}/bin/slurp"
      export OS_SWAPPY_PATH="${pkgs.swappy}/bin/swappy"
      exec ${python}/bin/python3 ${./os_cli.py} "$@"
    '';
  mkCmd = args: "${cli}/bin/os ${args}";
in {
  inherit cli;
  # Packages to be exported to ease development of the CLI outside Nix.
  packages = with pkgs; [grim nh slurp swappy];
  # Commands available via CLI in type-safe wrappers.
  home-switch = mkCmd "home switch";
  monitor-current = mkCmd "monitor current";
  nixos-switch = mkCmd "nixos switch";
  screenshot = mkCmd "screenshot";
  ui-reload = mkCmd "ui reload";
  ui-menu-bar-toggle = mkCmd "ui menu-bar toggle";
}
