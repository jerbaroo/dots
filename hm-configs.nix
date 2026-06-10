{ inputs, pkgs }:
[
  {
    allowUnfreePredicate =
      let
        whitelist = map pkgs.lib.getName [
          pkgs.github-copilot-cli
          pkgs.spotify
          pkgs.symbola
        ];
      in
      pkg: builtins.elem (pkgs.lib.getName pkg) whitelist;
    homeConfig =
      { config, pkgs, ... }:
      {
        desktop = {
          browser = {
            cmd = "firefox";
            homepage = "http://localhost:${toString config.desktop.ghdashboard.port}";
          };
          genericLinux = {
            enable = true;
            nixGL.packages = inputs.nixgl.packages;
          };
        };
        desktop.hyprland.gap = 0;
      };
    hostname = "ubuntu";
    username = "jeremy-barisch-rooney";
  }
]
