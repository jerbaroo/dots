{
  config,
  pkgs,
  ...
}:
{
  programs.kitty = {
    enable = true;
    font.name = config.desktop.font.code.name;
    font.size = config.desktop.font.code.size;
    package = config.desktop.wrapGL pkgs.kitty;
    settings = {
      background_opacity = config.desktop.font.code.backgroundOpacity;
      clipboard_control = "clipboard_control write-clipboard write-primary read-clipboard-ask read-primary-ask no_append";
      confirm_os_window_close = 0;
      enable_audio_bell = false;
      hide_window_decorations = false;
      shell = "${pkgs.fish}/bin/fish";
      update_check_interval = 0;
    };
  };
}
