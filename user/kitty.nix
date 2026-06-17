{
  config,
  lib,
  pkgs,
  ...
}:
{
  config.programs.kitty = {
    enable = true;
    font = {
      name = config.desktop.font.code.name;
      size = config.desktop.font.code.size;
    };
    package = config.desktop.kitty.package;
    settings = {
      auto_reload_config = -1; # https://github.com/kovidgoyal/kitty/issues/10102
      background_opacity = config.desktop.font.code.backgroundOpacity;
      clipboard_control = "clipboard_control write-clipboard write-primary read-clipboard-ask read-primary-ask no_append";
      confirm_os_window_close = 0;
      enable_audio_bell = false;
      hide_window_decorations = false;
      shell = config.desktop.tmux.start.command;
      update_check_interval = 0;
    };
  };
  options.desktop.kitty.package = lib.mkOption {
    default = config.lib.nixGL.wrap pkgs.kitty;
    readOnly = true;
    type = lib.types.package;
  };
}
