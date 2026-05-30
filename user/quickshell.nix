{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Packages and paths of dependencies.
  qtPkg = pkgs.kdePackages.qtdeclarative;
  qtPath = "${qtPkg}/lib/qt-6/qml";
  quickshellPkg = pkgs.quickshell;
  quickshellPath = "${quickshellPkg}/lib/qt-6/qml";
  # Provide dependency paths to qmlls.
  qmllsWrapper = pkgs.writeShellScriptBin "qmlls" ''
    exec ${qtPkg}/bin/qmlls -I "${quickshellPath}" -I "${qtPath}" "$@"
  '';
  shellServer = pkgs.callPackage ./quickshell/shell-server/shell-server.nix { };
in
{
  home.packages = [
    (lib.hiPrio qmllsWrapper) # Prioritize qmlls with library paths.
    qtPkg # For qmlformat and other tools.
    shellServer
  ];
  programs.quickshell = {
    enable = true;
    package = quickshellPkg;
  };
  # Global theme file.
  xdg.configFile."quickshell/Theme.sql".text = ''
    pragma Singleton
    import QtQuick

    QtObject {
      readonly property string accent: "${
        config.desktop.theme.palette.${config.desktop.theme.accent}.hex
      }"
      readonly property string base: "${config.desktop.theme.palette.base.hex}"
      readonly property string crust: "${config.desktop.theme.palette.crust.hex}"
      readonly property string mantle: "${config.desktop.theme.palette.mantle.hex}"
      readonly property string red: "${config.desktop.theme.palette.red.hex}"
      readonly property string yellow: "${config.desktop.theme.palette.yellow.hex}"
    }
  '';
  # Tell quickshell about our global theme file.
  xdg.configFile."quickshell/qmldir".text = "singleton Theme 1.0 Theme.qml";
}
