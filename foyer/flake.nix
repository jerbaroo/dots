{
  description = "Foyer desktop shell";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      settings = import ./dev-settings.nix { inherit pkgs; };
      generatedSettings = import ./generate-settings.nix {
        inherit pkgs settings;
      };
      configureDev = import ./configure-dev.nix {
        inherit pkgs generatedSettings;
      };
      cli = import ./cli.nix { inherit pkgs; };
      qt = pkgs.kdePackages.qtdeclarative;
      qmlImports = "${pkgs.quickshell}/lib/qt-6/qml:${qt}/lib/qt-6/qml";
      qmlls = pkgs.writeShellScriptBin "qmlls" ''
        exec ${qt}/bin/qmlls -I "${pkgs.quickshell}/lib/qt-6/qml" -I "${qt}/lib/qt-6/qml" "$@"
      '';
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = [
          cli
          settings.font.package
          settings.iconTheme.package
          pkgs.cargo
          pkgs.clippy
          pkgs.nixfmt
          pkgs.quickshell
          (pkgs.python3.withPackages (ps: [ ps.click ]))
          pkgs.rust-analyzer
          pkgs.rustc
          pkgs.rustfmt
          qmlls
          qt
        ];
        QML_IMPORT_PATH = qmlImports;
        shellHook = ''
          ${configureDev}/bin/configure-dev > /dev/null
          export FOYER_CONFIG_DIR="$PWD/quickshell"
          export QML_IMPORT_PATH="$PWD/quickshell/dev-generated:$QML_IMPORT_PATH"
        '';
        QS_ICON_THEME = settings.iconTheme.name;
        RUST_SRC_PATH = pkgs.rust.packages.stable.rustPlatform.rustLibSrc;
      };
      homeManagerModules.default = import ./home-manager.nix;
      # Generate Foyer dev config once on entering dev shell, can be
      # re-generated without rebuilding the entire dev shell.
      packages.${system} = {
        configure-dev = configureDev;
        default = cli;
      };
    };
}
