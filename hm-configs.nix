{ inputs }:
[
  rec {
    hostname = "ubuntu";
    username = "jeremy-barisch-rooney";

    homeConfig =
      { config, pkgs, ... }:
      {
        desktop = {
          inherit hostname username;
          allowUnfreePredicate =
            let
              whitelist = map pkgs.lib.getName [
                pkgs.github-copilot-cli
                pkgs.spotify
              ];
            in
            pkg: builtins.elem (pkgs.lib.getName pkg) whitelist;
          browser = {
            cmd = "firefox";
            homepage = "http://localhost:${toString config.desktop.ghdashboard.port}";
          };
          font.code.size = 14;
          genericLinux = {
            enable = true;
            nixGL.packages = inputs.nixgl.packages;
          };
          hyprland = {
            defaultColumnWidth = 0.333333;
            gap = 4;
          };
        };
      };
  }
]
