{
  config,
  foyer,
  lib,
  pkgs,
  ...
}:
let
  animation = name: {
    curve = map builtins.fromJSON desktop.animation.curves.${desktop.animation.${name}.curve}.points;
    durationMs = desktop.animation.${name}.durationMs;
  };
  desktop = config.desktop;
  floatCenter = "[float;center;size (monitor_w*${fraction}) (monitor_h*${fraction})]";
  fraction = toString desktop.hyprland.float.size.default;
in
{
  imports = [ foyer.homeManagerModules.default ];

  programs.foyer = {
    accent = desktop.theme.palette.${desktop.theme.accent}.hex;
    actions = {
      audioSettings = "${floatCenter} ${desktop.audio.guiCmd}";
      bluetoothSettings = "${floatCenter} ${desktop.bluetooth.guiCmd}";
      lockScreen = desktop.lock.cmd;
      systemMonitor = "${floatCenter} ${lib.getExe pkgs.kitty} ${desktop.btop.attach}";
    };
    animation = {
      enter = animation "fadeIn";
      exit = (animation "fadeIn") // {
        durationMs = desktop.animation.fadeOut.durationMs;
      };
      resize = animation "growY";
      slide = animation "transitionX";
    };
    enable = true;
    font = {
      name = desktop.font.shell.name;
      package = desktop.font.shell.package;
      size = desktop.font.shell.size;
    };
    iconTheme = {
      name = config.gtk.iconTheme.name;
      package = config.gtk.iconTheme.package;
    };
    layout = {
      borderWidthPx = desktop.hyprland.border.size;
      cornerRadiusPx = desktop.hyprland.rounding;
      gapPx = 2 * desktop.hyprland.gap;
    };
    palette = {
      background = desktop.theme.palette.crust.hex;
      controlActive = desktop.theme.palette.surface0.hex;
      controlBorder = desktop.theme.palette.overlay0.hex;
      controlHover = desktop.theme.palette.surface1.hex;
      danger = desktop.theme.palette.red.hex;
      fieldBackground = desktop.theme.palette.base.hex;
      notificationBody = desktop.theme.palette.yellow.hex;
      panelBackground = desktop.theme.palette.mantle.hex;
      text = desktop.theme.palette.text.hex;
      textMuted = desktop.theme.palette.subtext0.hex;
    };
  };
}
