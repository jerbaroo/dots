{ pkgs }:
{
  accent = "#b4befe";
  animation = {
    enter = {
      curve = [
        0.215
        0.61
        0.355
        1
      ];
      durationMs = 150;
    };
    exit = {
      curve = [
        0.215
        0.61
        0.355
        1
      ];
      durationMs = 100;
    };
    resize = {
      curve = [
        0.34
        1.08
        0.22
        1
      ];
      durationMs = 280;
    };
    slide = {
      curve = [
        0.215
        0.61
        0.355
        1
      ];
      durationMs = 160;
    };
  };
  backgroundOpacity = 0.35;
  font = {
    name = "Cascadia Mono";
    package = pkgs.cascadia-code;
    size = 18;
  };
  iconTheme = {
    name = "Papirus-Dark";
    package = pkgs.papirus-icon-theme;
  };
  layers = {
    bar = "foyer-bar";
    launcher = "foyer-launcher";
    notifications = "foyer-notifications";
    osd = "foyer-osd";
  };
  layout = {
    borderWidthPx = 2;
    cornerRadiusPx = 8;
    gapPx = 16;
  };
  palette = {
    background = "#11111b";
    controlActive = "#313244";
    controlBorder = "#6c7086";
    controlHover = "#45475a";
    danger = "#f38ba8";
    fieldBackground = "#1e1e2e";
    notificationBody = "#f9e2af";
    panelBackground = "#181825";
    text = "#cdd6f4";
    textMuted = "#a6adc8";
  };
  search.port = 1235;
}
