{
  config,
  lib,
  pkgs,
  ...
}:
let
  paletteSettings = lib.mapAttrs (_: name: config.desktop.theme.palette.${name}.hex) {
    active_border_color = config.desktop.theme.accent;
    active_tab_background = config.desktop.theme.accent;
    active_tab_foreground = "crust";
    background = "base";
    bell_border_color = "red";
    color0 = "surface1";
    color1 = "red";
    color10 = "green";
    color11 = "yellow";
    color12 = "blue";
    color13 = "pink";
    color14 = "teal";
    color15 = "subtext0";
    color2 = "green";
    color3 = "yellow";
    color4 = "blue";
    color5 = "pink";
    color6 = "teal";
    color7 = "subtext1";
    color8 = "surface2";
    color9 = "red";
    cursor = "rosewater";
    cursor_text_color = "base";
    foreground = "text";
    inactive_border_color = "surface0";
    inactive_tab_background = "mantle";
    inactive_tab_foreground = "subtext1";
    mark1_background = "lavender";
    mark1_foreground = "base";
    mark2_background = "peach";
    mark2_foreground = "base";
    mark3_background = "green";
    mark3_foreground = "base";
    selection_background = "surface2";
    selection_foreground = "base";
    tab_bar_background = "crust";
    url_color = "blue";
  };
in
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
      # Let Hyprland size new windows, avoid restoring a cached maximized state.
      remember_window_size = false;
      shell = config.desktop.tmux.start.command;
      update_check_interval = 0;
    }
    // paletteSettings;
  };
  options.desktop.kitty.package = lib.mkOption {
    default = config.lib.nixGL.wrap pkgs.kitty;
    readOnly = true;
    type = lib.types.package;
  };
}
