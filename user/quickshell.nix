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
  makeService = humanName: fileName: {
    Install.WantedBy = [ "graphical-session.target" ];
    Service = {
      Environment = [
        "QML_IMPORT_PATH=${config.xdg.configHome}/quickshell"
        "QS_ICON_THEME=${config.gtk.iconTheme.name}"
      ];
      ExecStart = "${quickshellPkg}/bin/quickshell -p /home/${config.desktop.username}/.config/quickshell/${fileName}.qml";
      Restart = "on-failure";
    };
    Unit = {
      After = [
        "graphical-session.target"
        "ignis.target"
      ];
      Description = humanName;
      BindsTo = [ "graphical-session.target" ];
    };
  };
  shellServer = pkgs.callPackage ./quickshell/shell-server/shell-server.nix { };
in
{
  home.packages = [
    (lib.hiPrio qmllsWrapper) # Prioritize qmlls with library paths.
    qtPkg # For qmlformat and other tools.
    shellServer
  ];
  # Make the Theme module and icon theme available from any config, including
  # when launching a single file with `quickshell -p <file>` (whose config root
  # is the file's own directory rather than ~/.config/quickshell).
  home.sessionVariables.QML_IMPORT_PATH = "${config.xdg.configHome}/quickshell";
  home.sessionVariables.QS_ICON_THEME = config.gtk.iconTheme.name;
  qt.enable = true;
  programs.quickshell = {
    enable = true;
    package = quickshellPkg;
  };
  systemd.user.services.app-launcher = makeService "App Launcher" "app_launcher";
  systemd.user.services.notification-center = makeService "Notification Center" "notifications";
  systemd.user.services.shell-server = {
    Install.WantedBy = [ "graphical-session.target" ];
    Service = {
      ExecStart = "${shellServer}/bin/shell-server";
      Restart = "on-failure";
    };
    Unit = {
      After = [ "graphical-session.target" ];
      Description = "Shell server";
      BindsTo = [ "graphical-session.target" ];
    };
  };
  # Global theme module. Exposed as `import Theme 1.0`, which requires a
  # proper module directory (Theme/qmldir declaring `module Theme`) rather
  # than a singleton entry in the config-root qmldir.
  xdg.configFile."quickshell/Theme/Theme.qml".text = ''
    pragma Singleton
    import QtQuick
    import Quickshell

    QtObject {
      readonly property string accent: "${
        config.desktop.theme.palette.${config.desktop.theme.accent}.hex
      }"
      readonly property string base: "${config.desktop.theme.palette.base.hex}"
      readonly property string crust: "${config.desktop.theme.palette.crust.hex}"
      readonly property string mantle: "${config.desktop.theme.palette.mantle.hex}"
      readonly property string overlay0: "${config.desktop.theme.palette.overlay0.hex}"
      readonly property string overlay1: "${config.desktop.theme.palette.overlay1.hex}"
      readonly property string overlay2: "${config.desktop.theme.palette.overlay2.hex}"
      readonly property string red: "${config.desktop.theme.palette.red.hex}"
      readonly property string text: "${config.desktop.theme.palette.text.hex}"
      readonly property string subtext0: "${config.desktop.theme.palette.subtext0.hex}"
      readonly property string subtext1: "${config.desktop.theme.palette.subtext1.hex}"
      readonly property string surface0: "${config.desktop.theme.palette.surface0.hex}"
      readonly property string surface1: "${config.desktop.theme.palette.surface1.hex}"
      readonly property string surface2: "${config.desktop.theme.palette.surface2.hex}"
      readonly property string yellow: "${config.desktop.theme.palette.yellow.hex}"
    }
  '';
  # Tell quickshell/Qt about our global theme module.
  xdg.configFile."quickshell/Theme/qmldir".text = ''
    module Theme
    singleton Theme 0.1 Theme.qml
  '';
  # Copy our entire quickshell configuration. Use recursive so individual files
  # are linked (rather than symlinking the whole directory into the read-only
  # store), allowing the generated Theme/ files above to live alongside them.
  xdg.configFile."quickshell" = {
    recursive = true;
    source = ./quickshell/quickshell;
  };
}
