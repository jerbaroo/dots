{
  config,
  doomModule,
  lib,
  pkgs,
  pkgs_latest,
  ...
}:
let
  configEl = pkgs.replaceVars ./config.el {
    codeBackgroundOpacity = toString (
      builtins.floor (config.desktop.font.code.backgroundOpacity * 100)
    );
    codeFontName = config.desktop.font.code.name;
    codeFontSize = toString (config.desktop.font.code.size) + ".0";
    colourLineNumber = config.desktop.theme.palette.subtext0.hex;
    colourLineNumberCurrent = config.desktop.theme.palette.peach.hex;
  };
  desktopTheme = pkgs.replaceVars ./desktop-theme.el {
    backgroundMode = if config.desktop.theme.flavor == "latte" then "light" else "dark";
    errorColor = config.desktop.theme.palette.red.hex;
    noteColor = config.desktop.theme.palette.blue.hex;
    palette = lib.concatStringsSep "\n    " (
      lib.mapAttrsToList (
        name: colour: "(${name} . ${builtins.toJSON colour.hex})"
      ) config.desktop.theme.palette
    );
    warningColor = config.desktop.theme.palette.yellow.hex;
  };
  doomDir = pkgs.runCommandLocal "doom-config" { } ''
    mkdir -p $out
    cp ${./init.el} $out/init.el
    cp ${./packages.el} $out/packages.el
    cp ${configEl} $out/config.el
    cp ${desktopTheme} $out/desktop-theme.el
  '';
in
{
  imports = [ doomModule ];
  home.packages = [ pkgs.fd ];
  programs.doom-emacs = {
    enable = true;
    doomDir = doomDir;
    emacs = pkgs_latest.emacs-pgtk;
  };
  programs.ripgrep.enable = true;
}
