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
                pkgs_latest.github-copilot-app
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
            defaultColumnWidth = 0.5;
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
