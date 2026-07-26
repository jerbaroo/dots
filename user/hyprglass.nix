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
    version = "0.7.0";
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
      hash = "sha256-x/584kY+XXlU/OWKtZAFo89VtowjLXs1DiP9PC0o0Os=";
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
          })
      end
    '';
    plugins = [ hyprglass ];
  };
}
