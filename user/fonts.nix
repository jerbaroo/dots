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
  iosevka-custom = pkgs.iosevka.override {
    # https://github.com/be5invis/Iosevka/blob/main/doc/custom-build.md
    privateBuildPlan = {
      family = "Iosevka Custom";
      ligations = {
        enables = [ "llggeq" ];
        inherits = "haskell";
      };
      serifs = "sans";
      slopes = {
        Italic = {
          angle = 9.4;
          css = "italic";
          menu = "italic";
          shape = "italic";
        };
        Upright = {
          angle = 0;
          css = "normal";
          menu = "upright";
          shape = "upright";
        };
      };
      spacing = "term";
      weights = {
        Bold = {
          css = 700;
          menu = 700;
          shape = 700;
        };
        Regular = {
          css = 400;
          menu = 400;
          shape = 400;
        };
      };
      widths.Normal = {
        css = "normal";
        menu = 5;
        shape = 500;
      };
    };
    set = "custom";
  };
in
{
  config = {
    # Required so fontconfig discovers fonts in ~/.nix-profile/share/fonts
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
      pkgs.nerd-fonts.symbols-only
      pkgs.noto-fonts
    ];
  };
  options.desktop = {
    font = {
      code = {
        backgroundOpacity = lib.mkOption {
          default = 0.6;
          description = "Background opacity of coding environments.";
          type = floatBetween0And1;
        };
        name = lib.mkOption {
          default = "Iosevka Custom";
          description = "Name of font for coding environments.";
          type = lib.types.str;
        };
        package = lib.mkOption {
          default = iosevka-custom;
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
          default = 18;
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
          default = 18;
          description = "Size of system font.";
          type = lib.types.ints.unsigned;
        };
      };
    };
  };
}
