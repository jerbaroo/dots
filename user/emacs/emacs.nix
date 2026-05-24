{ config, pkgs, ... }:
{
  home.file.".config/doom/config.el".source = pkgs.replaceVars ./config.el {
    codeFontName = config.desktop.font.code.name;
    codeBackgroundOpacity = toString (
      builtins.floor (config.desktop.font.code.backgroundOpacity * 100)
    );
    codeFontSize = toString (config.desktop.font.code.size) + ".0";
    colourComment = config.desktop.theme.palette.rosewater.hex;
    colourLineNumber = config.desktop.theme.palette.subtext0.hex;
    colourLineNumberCurrent = config.desktop.theme.palette.peach.hex;
    flavor = config.desktop.theme.flavor;
  };
  home.file.".config/doom/init.el".source = ./init.el;
  home.file.".config/doom/packages.el".source = ./packages.el;
  programs.emacs = {
    enable = true;
    package = pkgs.emacs-pgtk;
  };
  programs.ripgrep.enable = true;
}
