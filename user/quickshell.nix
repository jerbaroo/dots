{
  config,
  lib,
  pkgs,
  ...
}:
let
  configJs = pkgs.replaceVars ./quickshell/quickshell/config.js (
    {
      accent = config.desktop.theme.palette.${config.desktop.theme.accent}.hex;
      hyprlandBorderSize = toString config.desktop.hyprland.border.size;
      hyprlandGap = toString config.desktop.hyprland.gap;
      hyprlandRounding = toString config.desktop.hyprland.rounding;
      inhibitLockPath = config.desktop.lock.inhibitPath;
      shellFontName = config.desktop.font.shell.name;
      shellFontSize = toString config.desktop.font.shell.size;
    }
    // builtins.listToAttrs paletteHexColours
  );
  paletteHexColours =
    map
      (name: {
        name = name;
        value = config.desktop.theme.palette.${name}.hex;
      })
      [
        "base"
        "crust"
        "mantle"
        "overlay0"
        "overlay1"
        "overlay2"
        "red"
        "text"
        "subtext0"
        "subtext1"
        "surface0"
        "surface1"
        "surface2"
        "yellow"
      ];
  configDir = pkgs.runCommandLocal "quickshell-config" { } ''
    mkdir $out
    cp -r ${./quickshell/quickshell}/. $out/
    chmod -R u+w $out # Needed to copy the file.
    cp ${configJs} $out/config.js
  '';
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
      After = [ "graphical-session.target" ];
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
  # Make the Cmds module and icon theme available from any config, including
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
  # Bar and notification server share one instance (see quickshell/BAR.md).
  systemd.user.services.menu-bar = makeService "Menu Bar" "bar";
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
  # Commands from the Nix config for use in QML. Launched through hyprland's
  # exec dispatcher, so rule prefixes like [float;center] apply — the same
  # mechanism the keybinds in hyprland.nix use.
  xdg.configFile."quickshell/Cmds/Cmds.qml".text =
    let
      floatCenter =
        let
          fraction = toString config.desktop.hyprland.float.size.default;
        in
        "[float;center;size (monitor_w*${fraction}) (monitor_h*${fraction})]";
    in
    ''
      pragma Singleton
      import QtQuick
      import Quickshell

      QtObject {
        readonly property string audioGui: "${floatCenter} ${config.desktop.audio.guiCmd}"
        readonly property string bluetoothGui: "${floatCenter} ${config.desktop.bluetooth.guiCmd}"
        readonly property string btop: "${floatCenter} kitty ${config.desktop.btop.attach}"
        readonly property string lockScreen: "${config.desktop.cli.ui.lockScreen.toggle}"
        readonly property string logoutMenu: "${config.desktop.cli.ui.logoutMenu.toggle}"
      }
    '';
  xdg.configFile."quickshell/Cmds/qmldir".text = ''
    module Cmds
    singleton Cmds 0.1 Cmds.qml
  '';
  # Copy our entire quickshell configuration. Use recursive so individual files
  # are linked (rather than symlinking the whole directory into the read-only
  # store), allowing the generated Cmds/ files above to live alongside them.
  xdg.configFile."quickshell" = {
    recursive = true;
    source = configDir;
  };
}
