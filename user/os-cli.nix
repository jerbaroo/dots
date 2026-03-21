{ ignis, hyprland, pkgs, system, ... }:
let
  cli =
    let python = pkgs.python3.withPackages (ps: with ps; [ click ]);
    in pkgs.writeShellScriptBin "os" ''
      export HYPRCTL_PATH="${hyprland.packages.${system}.hyprland}/bin/hyprctl"
      export IGNIS_PATH="${ignis.packages.${system}.ignis}/bin/ignis"
      exec ${python}/bin/python3 ${./os_cli.py} "$@"
    '';
  mkCmd = args: "${cli}/bin/os ${args}";
in {
  inherit cli;
  monitor-current = mkCmd "monitor current";
  ui-reload = mkCmd "ui reload";
}
