{ lib, pkgs, ... }:
let
  inherit (lib) mkOption types;
  # A curve and a duration.
  animation =
    defaults:
    types.submodule {
      options = {
        curve = mkOption {
          default = defaults.curve;
          description = "Cubic Bezier control points [x1 y1 x2 y2], without the final endpoint.";
          type = types.addCheck (types.listOf types.number) (points: builtins.length points == 4);
        };
        durationMs = mkOption {
          default = defaults.durationMs;
          description = "Animation duration in milliseconds.";
          type = types.ints.unsigned;
        };
      };
    };
  colour = types.strMatching "#[0-9a-fA-F]{6}";
  defaults = import ./defaults.nix { inherit pkgs; };

in
{
  options.programs.foyer = {
    accent = mkOption {
      default = defaults.accent;
      description = "Accent colour as #RRGGBB.";
      type = colour;
    };
    actions = {
      audioSettings = mkOption {
        description = "Command to open audio settings.";
        type = types.str;
      };
      bluetoothSettings = mkOption {
        description = "Command to open Bluetooth settings.";
        type = types.str;
      };
      lockScreen = mkOption {
        description = "Command to lock the screen.";
        type = types.str;
      };
      systemMonitor = mkOption {
        description = "Command to open the system monitor.";
        type = types.str;
      };
    };
    animation = {
      enter = mkOption {
        default = { };
        description = "Content enter animation.";
        type = animation defaults.animation.enter;
      };
      exit = mkOption {
        default = { };
        description = "Content exit animation.";
        type = animation defaults.animation.exit;
      };
      resize = mkOption {
        default = { };
        description = "Panel reveal and resize animation.";
        type = animation defaults.animation.resize;
      };
      slide = mkOption {
        default = { };
        description = "Animation between panel positions.";
        type = animation defaults.animation.slide;
      };
    };
    backgroundOpacity = mkOption {
      default = defaults.backgroundOpacity;
      description = "Background opacity for the bar and panels, from 0 (transparent) to 1 (opaque).";
      type = types.addCheck types.number (value: value >= 0 && value <= 1);
    };
    enable = lib.mkEnableOption "Foyer desktop shell";
    font = mkOption {
      apply =
        font:
        assert lib.assertMsg (font.package != null) "programs.foyer.font.package must not be null.";
        assert lib.assertMsg (font.size != null) "programs.foyer.font.size must not be null.";
        font;
      default = { };
      description = "Shell font. Size is interpreted in pixels; package and size must not be null.";
      type = types.submodule {
        imports = lib.hm.types.fontType.getSubModules;
        config = {
          name = lib.mkDefault defaults.font.name;
          package = lib.mkDefault defaults.font.package;
          size = lib.mkDefault defaults.font.size;
        };
      };
    };
    iconTheme = {
      name = mkOption {
        default = defaults.iconTheme.name;
        description = "Icon theme name.";
        type = types.str;
      };
      package = mkOption {
        default = defaults.iconTheme.package;
        description = "Package providing the icon theme.";
        type = types.package;
      };
    };
    layers = {
      bar = mkOption {
        default = defaults.layers.bar;
        description = "Layer namespace used by the bar.";
        readOnly = true;
        type = types.str;
      };
      launcher = mkOption {
        default = defaults.layers.launcher;
        description = "Layer namespace used by the launcher.";
        readOnly = true;
        type = types.str;
      };
      notifications = mkOption {
        default = defaults.layers.notifications;
        description = "Layer namespace used by the notifications.";
        readOnly = true;
        type = types.str;
      };
      osd = mkOption {
        default = defaults.layers.osd;
        description = "Layer namespace used by the osd.";
        readOnly = true;
        type = types.str;
      };
    };
    layout = {
      borderWidthPx = mkOption {
        default = defaults.layout.borderWidthPx;
        description = "Border width in pixels.";
        type = types.ints.unsigned;
      };
      cornerRadiusPx = mkOption {
        default = defaults.layout.cornerRadiusPx;
        description = "Corner radius in pixels.";
        type = types.ints.unsigned;
      };
      gapPx = mkOption {
        default = defaults.layout.gapPx;
        description = "Shell gap in pixels.";
        type = types.ints.unsigned;
      };
    };
    package = mkOption {
      default = pkgs.callPackage ./cli.nix { };
      description = "Package providing the Foyer control command.";
      readOnly = true;
      type = types.package;
    };
    palette = lib.genAttrs (builtins.attrNames defaults.palette) (
      name:
      mkOption {
        default = defaults.palette.${name};
        description = "The ${name} palette colour as #RRGGBB.";
        type = colour;
      }
    );
    search.port = mkOption {
      default = defaults.search.port;
      description = "Loopback port used by the application-search server and launcher.";
      type = types.port;
    };
  };
}
