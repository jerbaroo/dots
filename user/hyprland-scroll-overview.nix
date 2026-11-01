{
  config,
  lib,
  pkgs,
  ...
}:
let
  scrolloverview = pkgs.hyprlandPlugins.mkHyprlandPlugin (finalAttrs: {
    buildInputs = [ pkgs.lua5_4 ];
    dontUseCmakeConfigure = true;
    env.SCROLLOVERVIEW_BUILD_VERSION = finalAttrs.version;
    hyprland = config.desktop.hyprland.packages.hyprland;
    installPhase = ''
      runHook preInstall
      mkdir -p "$out/lib"
      cp scrolloverview.so "$out/lib/libscrolloverview.so"
      runHook postInstall
    '';
    meta = {
      description = "Scrollable workspace overview for Hyprland";
      homepage = "https://github.com/yayuuu/hyprland-scroll-overview";
      license = lib.licenses.bsd3;
      platforms = lib.platforms.linux;
    };
    patches = [ ./patches/scrolloverview-hyprglass.patch ];
    pluginName = "scrolloverview";
    src = pkgs.fetchFromGitHub {
      hash = "sha256-684XIZXg/MPkFClgTJGUAVB/bEc4C2aTdD/nfQEt81o=";
      owner = "yayuuu";
      repo = "hyprland-scroll-overview";
      rev = "a8dcca6fe3ddc2164774cb6925bc67c0b974a78f";
    };
    version = "0-unstable-a8dcca6";
  });
in
{
  wayland.windowManager.hyprland = {
    extraConfig = ''
      hl.define_submap("scrolloverview", function()
        for key, direction in pairs({
          ["H"] = "left",
          ["J"] = "down",
          ["K"] = "up",
          ["L"] = "right",
        }) do
          hl.bind(key, function() hl.plugin.scrolloverview.navigate(direction) end)
        end
        hl.bind("RETURN", function() hl.plugin.scrolloverview.overview("off") end)
        hl.bind("ESCAPE", function() hl.plugin.scrolloverview.overview("off") end)
        hl.bind("mouse:272", function()
          hl.plugin.scrolloverview.overview("select")
          hl.plugin.scrolloverview.window("select")
          hl.plugin.scrolloverview.overview("off")
        end, { mouse = true })
      end)
    '';
    plugins = [ scrolloverview ];
  };
}
