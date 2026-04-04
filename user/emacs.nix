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
  imports = [
    (import ./emacs-config.nix {
      inherit codeBackgroundOpacity;
      inherit codeFontName;
      inherit codeFontSize;
      inherit flavor;
      inherit palette;
      inherit pkgs;
    })
    ./emacs-init.nix
    ./emacs-package.nix
  ];
  programs.emacs = {
    enable = true;
    package = pkgs.emacs-pgtk;
  };
  programs.ripgrep.enable = true;
}
