{ pkgs, settings }:
let
  animCurve = name: builtins.concatStringsSep ", " (map toString settings.animation.${name}.curve);
  animMs = name: toString settings.animation.${name}.durationMs;
  # Generate the runtime settings singleton.
  configQml = pkgs.replaceVars ./templates/Config.qml.in (
    {
      accent = settings.accent;
      borderSize = toString settings.layout.borderWidthPx;
      inhibitCommand = builtins.toJSON "${pkgs.systemd}/bin/systemd-inhibit";
      sleepCommand = builtins.toJSON "${pkgs.coreutils}/bin/sleep";
      gap = toString settings.layout.gapPx;
      backgroundOpacity = toString settings.backgroundOpacity;
      layers = builtins.toJSON settings.layers;
      rounding = toString settings.layout.cornerRadiusPx;
      searchUrl = builtins.toJSON "http://127.0.0.1:${toString settings.search.port}";
      shellFontName = builtins.toJSON settings.font.name;
      shellFontSize = toString settings.font.size;
      # Animations.
      enterCurve = animCurve "enter";
      enterMs = animMs "enter";
      exitCurve = animCurve "exit";
      exitMs = animMs "exit";
      resizeCurve = animCurve "resize";
      resizeMs = animMs "resize";
      slideCurve = animCurve "slide";
      slideMs = animMs "slide";
    }
    // settings.palette
  );
  cmds = pkgs.writeText "foyer-commands.qml" ''
    pragma Singleton
    import QtQuick
    import Quickshell

    QtObject {
      readonly property string audioGui: ${builtins.toJSON settings.actions.audioSettings}
      readonly property string bluetoothGui: ${builtins.toJSON settings.actions.bluetoothSettings}
      readonly property string btop: ${builtins.toJSON settings.actions.systemMonitor}
      readonly property string lockScreen: ${builtins.toJSON settings.actions.lockScreen}
    }
  '';
  qmldir = pkgs.writeText "foyer-commands-qmldir" ''
    module Cmds
    singleton Cmds 0.1 Cmds.qml
  '';
in
pkgs.runCommandLocal "foyer-settings" { } ''
  mkdir -p $out/FoyerConfig $out/Cmds
  cp ${configQml} $out/FoyerConfig/Config.qml
  cat > $out/FoyerConfig/qmldir <<'QMLDIR'
  module FoyerConfig
  singleton Config 1.0 Config.qml
  QMLDIR
  cp ${cmds} $out/Cmds/Cmds.qml
  cp ${qmldir} $out/Cmds/qmldir
''
