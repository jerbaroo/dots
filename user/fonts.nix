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
      name = config.desktop.font.system.name;
      package = config.desktop.font.system.package;
      size = config.desktop.font.system.size;
    };
    home.packages = [
      config.desktop.font.code.package
      config.desktop.font.shell.package
      config.desktop.font.system.package
    ]
    ++ (with pkgs; [
      nerd-fonts.symbols-only
      noto-fonts
    ]);
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
        package = lib.mkOption {
          default = pkgs.nerd-fonts.iosevka;
          description = "Package providing the coding-environment font.";
          type = lib.types.package;
        };
        size = lib.mkOption {
          default = 18;
          description = "Size of font for coding environments.";
          type = lib.types.ints.unsigned;
        };
      };
      shell = {
        name = lib.mkOption {
          default = "Cascadia Mono";
          description = "Name of (Quick)shell font.";
          type = lib.types.str;
        };
        package = lib.mkOption {
          default = pkgs.cascadia-code;
          description = "Package providing the (Quick)shell font.";
          type = lib.types.package;
        };
        size = lib.mkOption {
          default = 16;
          description = "Size of (Quick)shell font.";
          type = lib.types.ints.unsigned;
        };
      };
      system = {
        name = lib.mkOption {
          default = "Atkinson Hyperlegible";
          description = "Name of system font.";
          type = lib.types.str;
        };
        package = lib.mkOption {
          default = pkgs.atkinson-hyperlegible;
          description = "Package providing the system font.";
          type = lib.types.package;
        };
        size = lib.mkOption {
          default = 16;
          description = "Size of system font.";
          type = lib.types.ints.unsigned;
        };
      };
    };
  };
}
