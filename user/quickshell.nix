{
  lib,
  pkgs,
  quickshell,
  system,
  ...
}:
let
  # Packages and paths of dependencies.
  qt-base-pkg = pkgs.kdePackages.qtdeclarative;
  qt-base-path = "${qt-base-pkg}/lib/qt-6/qml";
  quickshell-pkg = quickshell.packages.${system}.default;
  quickshell-path = "${quickshell-pkg}/lib/qt-6/qml";
  # Provide dependency paths to qmlls.
  qmlls-wrapper = pkgs.writeShellScriptBin "qmlls" ''
    exec ${qt-base-pkg}/bin/qmlls -I "${quickshell-path}" -I "${qt-base-path}" "$@"
  '';
in
{
  home.packages = [
    (lib.hiPrio qmlls-wrapper) # Prioritize qmlls with library paths.
    qt-base-pkg # For qmlformat and other tools.
  ];
  programs.quickshell = {
    enable = true;
    package = quickshell-pkg;
  };
}
