{
  config,
  lib,
  pkgs,
  ...
}:
let
  floatBetween0And1 = lib.types.addCheck lib.types.float (x: x >= 0.0 && x <= 1.0) // {
    description = "Floating point number in [0 1].";
  };
in
{
  config = {
    fonts.fontconfig.enable = true;
    gtk.font = {
      name = "Atkinson Hyperlegible";
      package = pkgs.atkinson-hyperlegible;
      size = config.desktop.font.system.size;
    };
    home.packages = with pkgs; [
      cascadia-code
      nerd-fonts.iosevka
      nerd-fonts.jetbrains-mono
      nerd-fonts.symbols-only
      noto-fonts
      symbola
    ];
  };
  options.desktop = {
    font = {
      code = {
        backgroundOpacity = lib.mkOption {
          default = 0.7;
          description = "Background opacity of coding environments.";
          type = floatBetween0And1;
        };
        name = lib.mkOption {
          default = "Iosevka Nerd Font Mono";
          description = "Name of font for coding environments.";
          type = lib.types.str;
        };
        size = lib.mkOption {
          default = 18;
          description = "Size of font for coding environments.";
          type = lib.types.ints.unsigned;
        };
      };
      system = {
        size = lib.mkOption {
          default = 16;
          description = "Size of system font.";
          type = lib.types.ints.unsigned;
        };
      };
    };
  };
}
