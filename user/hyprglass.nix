{
  config,
  lib,
  pkgs,
  ...
}:
let
  hyprglass = pkgs.hyprlandPlugins.mkHyprlandPlugin (finalAttrs: {
    hyprland = config.desktop.hyprland.packages.hyprland;
    pluginName = "hyprglass";
    # Bumping this requires bumping the hyprland version in flake.nix:
    # https://github.com/hyprnux/hyprglass/blob/main/.hyprland-version
    # Also bump the hash and possibly the revision below.
    version = "0.10.0";
    meta = {
      description = "Liquid Glass for Hyprland";
      homepage = "https://github.com/hyprnux/hyprglass";
      license = lib.licenses.bsd3;
      platforms = lib.platforms.linux;
    };
    src = pkgs.fetchFromGitHub {
      owner = "hyprnux";
      repo = "hyprglass";
      rev = "v${finalAttrs.version}";
      hash = "sha256-60nDpYUgPXue7iSWHb05goz95j0cNmBYAyhlpviu7K4=";
    };
    installPhase = ''
      mkdir -p $out/lib
      cp hyprglass.so $out/lib/libhyprglass.so
    '';
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
          -- We only use hyprglass for windows, not layers (e.g. Quickshell components).
          layers = { enabled = 0 },
        })
        hg.preset("glass",
          { blur_strength = ${toString config.desktop.hyprland.blur.liquidGlass.size}
          , blur_iterations = ${toString config.desktop.hyprland.blur.liquidGlass.iterations}
          , noise_strength = ${toString config.desktop.hyprland.blur.liquidGlass.grain}
          , xray = true
          })
      end
    '';
    plugins = [ hyprglass ];
  };
}
