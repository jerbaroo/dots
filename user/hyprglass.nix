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
    version = "0.6.2";
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
      hash = "sha256-6qa0PoeKfGSpXpILgp2yuYfRmrQKjDSQWpy8q27u1uE=";
    };
    installPhase = ''
      mkdir -p $out/lib
      cp hyprglass.so $out/lib/libhyprglass.so
    '';
  });
in
{
  wayland.windowManager.hyprland = {
    extraConfig = ''
      if hl.plugin.hyprglass then
        local hg = hl.plugin.hyprglass
        hg.config({
          default_preset = "glass",
          default_theme = "dark",
          layers = { enabled = 0 },
        })
      end
    '';
    plugins = [ hyprglass ];
  };
}
