{
  accent,
  codeBackgroundOpacity,
  codeFontName,
  codeFontSize,
  color-schemes,
  config,
  flavor,
  pkgs,
  system,
  wrapGL,
  ...
}:
let
  start-tmux = pkgs.writeScriptBin "start-tmux" ''
    #!/usr/bin/env fish
    ${pkgs.tmux}/bin/tmux new-session -A -s main
  '';
in
{
  programs.ghostty = {
    enable = true;
    package = (if wrapGL then config.lib.nixGL.wrap else (x: x)) pkgs.ghostty;
    settings = {
      background-opacity = codeBackgroundOpacity;
      command = "${start-tmux}/bin/start-tmux";
      config-file = [
        "${color-schemes}/ghostty/Catppuccin ${pkgs.lib.strings.toSentenceCase flavor}"
      ];
      confirm-close-surface = false;
      font-family = codeFontName;
      font-size = codeFontSize;
      scrollback-limit = 1000000000;
    };
  };
}
