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
      hash = "sha256-cQmVmmdaITss2hO6aidKOtq6GtEe85fmgrPcrn1eIUg=";
      owner = "hyprnux";
      repo = "hyprglass";
      rev = "v${finalAttrs.version}";
    };
    # Recheck Hyprland compatibility and refresh the local patch when bumping.
    # https://github.com/hyprnux/hyprglass/blob/main/.hyprland-version
    version = "1.1.1";
  });
in
{
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
}
