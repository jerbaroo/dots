{
  codeBackgroundOpacity,
  codeFontName,
  codeFontSize,
  flavor,
  palette,
  pkgs,
  ...
}:
{
  home.file.".config/doom/config.el".source = pkgs.replaceVars ./config.el {
    inherit codeFontName;
    inherit flavor;
    codeBackgroundOpacity = toString (builtins.floor (codeBackgroundOpacity * 100));
    codeFontSize = toString (codeFontSize) + ".0";
    colourComment = palette.rosewater.hex;
    colourLineNumber = palette.subtext0.hex;
    colourLineNumberCurrent = palette.peach.hex;
  };
  home.file.".config/doom/init.el".source = ./init.el;
  home.file.".config/doom/packages.el".source = ./packages.el;
  home.packages = with pkgs; [ symbola ];
  programs.emacs = {
    enable = true;
    package = pkgs.emacs-pgtk;
  };
  programs.ripgrep.enable = true;
}
