{
  config,
  pkgs,
  system,
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
    package = config.desktop.wrapGL pkgs.ghostty;
    settings = {
      background-opacity = config.desktop.font.code.backgroundOpacity;
      command = "${start-tmux}/bin/start-tmux";
      config-file = [
        "${config.desktop.theme.colorSchemes}/ghostty/Catppuccin ${pkgs.lib.strings.toSentenceCase config.desktop.theme.flavor}"
      ];
      confirm-close-surface = false;
      font-family = config.desktop.font.code.name;
      font-size = config.desktop.font.code.size;
      scrollback-limit = 1000000000;
    };
  };
}
