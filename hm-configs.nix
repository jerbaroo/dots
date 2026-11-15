{ inputs }:
[
  rec {
    allowUnfreePredicate =
      pkg:
      builtins.elem (inputs.nixpkgs.lib.getName pkg) [
        "github-copilot-app"
        "github-copilot-cli"
        "spotify"
      ];
    hostname = "ubuntu";
    username = "jeremy-barisch-rooney";

    homeConfig =
      {
        config,
        pkgs_latest,
        ...
      }:
      {
        desktop = {
          inherit allowUnfreePredicate hostname username;
          browser.homepage = "http://localhost:${toString config.desktop.ghdashboard.port}";
          font.code.size = 12;
          genericLinux = {
            enable = true;
            nixGL.packages = inputs.nixgl.packages;
          };
          hyprland = {
            defaultColumnWidth = 0.333333;
            gap = 8;
          };
          lock.cmd = "swaylock";
          neo.colour = "gold";
        };
        home.packages = [
          (pkgs_latest.github-copilot-app.overrideAttrs (old: {
            # Foundry loads OpenSSL dynamically, so autoPatchelf cannot infer it.
            runtimeDependencies = (old.runtimeDependencies or [ ]) ++ [
              pkgs_latest.openssl_3_5
            ];
          }))
          pkgs_latest.github-copilot-cli
        ];
      };
  }
]
