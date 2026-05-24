{
  config,
  lib,
  pkgs,
  ...
}:
{
  config.programs.spicetify = {
    colorScheme = config.desktop.theme.flavor;
    enable = true;
    enabledExtensions = with config.desktop.spicetify.packages.extensions; [
      fullAppDisplay
      keyboardShortcut
    ];
    theme = config.desktop.spicetify.packages.themes.catppuccin;
    wayland = true;
  };
  options.desktop.spicetify.packages = lib.mkOption {
    description = "Spicetify packages";
    type = lib.types.attrs;
  };
}
