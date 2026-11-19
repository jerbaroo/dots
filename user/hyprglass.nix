{
  config,
  lib,
  pkgs,
  ...
}:
let
  hyprglass = pkgs.hyprlandPlugins.mkHyprlandPlugin (finalAttrs: {
    hyprland = config.desktop.hyprland.packages.hyprland;
    installPhase = ''
      mkdir -p $out/lib
      cp hyprglass.so $out/lib/libhyprglass.so
    '';
    meta = {
      description = "Liquid Glass for Hyprland";
      homepage = "https://github.com/hyprnux/hyprglass";
      license = lib.licenses.bsd3;
      platforms = lib.platforms.linux;
    };
    patches = [ ./patches/hyprglass-overview.patch ];
    pluginName = "hyprglass";
    src = pkgs.fetchFromGitHub {
      hash = "sha256-yWfeuLNVhoLYDmrFrZ8YDoHSFObwvKoplwHvTulPWTs=";
      owner = "hyprnux";
      repo = "hyprglass";
      rev = "v${finalAttrs.version}";
    };
    # Recheck Hyprland compatibility and refresh the local patch when bumping.
    # https://github.com/hyprnux/hyprglass/blob/main/.hyprland-version
    version = "1.2.0";
  });
in
{
  config = {
    wayland.windowManager.hyprland = lib.mkIf config.desktop.hyprland.blur.liquidGlass.enabled {
      extraConfig = ''
        if hl.plugin.hyprglass then
          local hg = hl.plugin.hyprglass
          hg.config({
            default_preset = "glass",
            default_theme = "dark",
            -- Disable hyprglass for layers (e.g. Quickshell components).
            -- layers = { enabled = 0 },
          })
          hg.preset("glass",
            { blur_iterations = ${toString config.desktop.hyprland.blur.liquidGlass.iterations}
            , blur_strength = ${toString config.desktop.hyprland.blur.liquidGlass.size}
            , noise_strength = ${toString config.desktop.hyprland.blur.liquidGlass.grain}
            , xray = true
            })
        end
      '';
      plugins = [ hyprglass ];
    };
  };

  options.desktop.hyprland.blur.liquidGlass = {
    enabled = lib.mkOption {
      default = true;
      description = "Apply liquid glass effect for blurred windows.";
      type = lib.types.bool;
    };
    grain = lib.mkOption {
      default = 0.3;
      description = "Amount of frosted grain.";
      type = lib.types.addCheck lib.types.float (x: x >= 0 && x <= 1);
    };
    iterations = lib.mkOption {
      default = 3;
      description = "Amount of liquid glass blurring iterations.";
      type = lib.types.ints.unsigned;
    };
    size = lib.mkOption {
      default = 3.0;
      description = "Liquid glass blur size.";
      type = lib.types.float;
    };
  };
}
