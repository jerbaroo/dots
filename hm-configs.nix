{ inputs }:
[
  {
    hostname = "ubuntu";
    username = "jeremy-barisch-rooney";

    homeConfig =
      { config, pkgs, ... }:
      {
        desktop = {
          allowUnfreePredicate =
            let
              whitelist = map pkgs.lib.getName [
                pkgs.github-copilot-cli
                pkgs.spotify
                pkgs.symbola
              ];
            in
            pkg: builtins.elem (pkgs.lib.getName pkg) whitelist;
          browser = {
            cmd = "firefox";
            homepage = "http://localhost:${toString config.desktop.ghdashboard.port}";
          };
          genericLinux = {
            enable = true;
            nixGL.packages = inputs.nixgl.packages;
          };
          hyprland.gap = 0;
        };
      };
  }
]
