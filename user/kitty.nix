{
  config,
  lib,
  pkgs,
  ...
}:
let
  # catppuccin-nix themes kitty by including a prebuilt conf from nixpkgs'
  # kitty-themes, so kitty does not follow desktop.theme.palette. Home Manager
  # emits `settings` after that include and kitty takes the last definition of a
  # key, so restating the affected ones is enough -- nothing to rewrite.
  #
  # These are the keys the Catppuccin theme sets to base, mantle or crust. The
  # foreground ones are text drawn on top of an accent; they follow their colour
  # too, so they cannot end up a not-quite-black sitting next to a true black.
  paletteSettings = lib.mapAttrs (_: name: config.desktop.theme.palette.${name}.hex) {
    active_tab_foreground = "crust";
    background = "base";
    cursor_text_color = "base";
    inactive_tab_background = "mantle";
    mark1_foreground = "base";
    mark2_foreground = "base";
    mark3_foreground = "base";
    selection_foreground = "base";
    tab_bar_background = "crust";
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
