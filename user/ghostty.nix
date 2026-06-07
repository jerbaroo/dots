{
  config,
  lib,
  pkgs,
  system,
  ...
}:
{
  config.programs.ghostty = {
    enable = true;
    package = config.desktop.ghostty.package;
    settings = {
      background-opacity = config.desktop.font.code.backgroundOpacity;
      command = config.desktop.tmux.start.command;
      config-file = [
        "${config.desktop.theme.colorSchemes}/ghostty/Catppuccin ${pkgs.lib.strings.toSentenceCase config.desktop.theme.flavor}"
      ];
      confirm-close-surface = false;
      font-family = config.desktop.font.code.name;
      font-size = config.desktop.font.code.size;
      scrollback-limit = 1000000000;
    };
  };
  options.desktop.ghostty.package = lib.mkOption {
    default = config.lib.nixGL.wrap pkgs.ghostty;
    readOnly = true;
    type = lib.types.package;
  };
}
