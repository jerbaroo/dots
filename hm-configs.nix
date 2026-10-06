{ inputs }:
[
  rec {
    hostname = "ubuntu";
    username = "jeremy-barisch-rooney";

    homeConfig =
      {
        config,
        pkgs,
        pkgs_latest,
        ...
      }:
      {
        desktop = {
          inherit hostname username;
          allowUnfreePredicate =
            let
              whitelist = map pkgs.lib.getName [
                pkgs_latest.github-copilot-cli # FIXME
                pkgs.spotify
              ];
            in
            pkg: builtins.elem (pkgs.lib.getName pkg) whitelist;
          browser.homepage = "http://localhost:${toString config.desktop.ghdashboard.port}";
          font.code.size = 14;
          genericLinux = {
            enable = true;
            nixGL.packages = inputs.nixgl.packages;
          };
          hyprland = {
            blur.liquidGlass = {
              # iterations = 1;
              # size = 1.5;
            };
            defaultColumnWidth = 0.333333;
            gap = 8;
          };
        };
        home.packages = [
          pkgs_latest.github-copilot-cli
        ];
      };
  }
]
