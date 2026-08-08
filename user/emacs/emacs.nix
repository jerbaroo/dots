{
  config,
  pkgs,
  lib,
  doomModule,
  ...
}:
let
  configEl = pkgs.replaceVars ./config.el {
    codeFontName = config.desktop.font.code.name;
    codeBackgroundOpacity = toString (
      builtins.floor (config.desktop.font.code.backgroundOpacity * 100)
    );
    codeFontSize = toString (config.desktop.font.code.size) + ".0";
    colourComment = config.desktop.theme.palette.rosewater.hex;
    colourLineNumber = config.desktop.theme.palette.subtext0.hex;
    colourLineNumberCurrent = config.desktop.theme.palette.peach.hex;
    flavor = config.desktop.theme.flavor;
    paletteOverrides =
      let
        changes = config.desktop.theme.paletteChanges;
      in
      if changes == { } then
        ""
      else
        lib.concatStringsSep "\n" (
          [ ''(load "catppuccin-theme" nil t)'' ]
          ++ lib.mapAttrsToList (name: colour: "(catppuccin-set-color '${name} \"${colour.to}\")") changes
          ++ [ "(catppuccin-reload)" ]
        );
  };
  doomDir = pkgs.runCommandLocal "doom-config" { } ''
    mkdir -p $out
    cp ${./init.el} $out/init.el
    cp ${./packages.el} $out/packages.el
    cp ${configEl} $out/config.el
  '';
in
{
  imports = [ doomModule ];
  home.packages = [ pkgs.fd ];
  programs.doom-emacs = {
    enable = true;
    doomDir = doomDir;
    emacs = pkgs.emacs-pgtk;
  };
  programs.ripgrep.enable = true;
}
