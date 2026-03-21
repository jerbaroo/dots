{
  accent,
  ignis,
  ignisPath,
  palette,
  pkgs,
  ...
}:
{
  home.file.${ignisPath} = {
    source = ./ignis;
    recursive = true;
  };
  # Write theme colours to a fixed location, to be picked up at run-time.
  home.file.".config/ignis/colors.scss".text = ''
    $accent: ${palette.${accent}.hex};
    $base: ${palette.base.hex};
    $crust: ${palette.crust.hex};
    $mantle: ${palette.mantle.hex};
    $red: ${palette.red.hex};
    $yellow: ${palette.yellow.hex};
  '';
  programs.ignis = {
    enable = true;
    sass = {
      enable = true;
      useDartSass = true;
    };
    services = {
      audio.enable = true;
      # bluetooth.enable = true;
      # recorder.enable = true;
      # network.enable = true;
    };
    extraPackages = with pkgs; [
      libnotify
    ];
  };
}
