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
    # Pin jakeleveroni's hyprland-0.57-port branch.
    src = pkgs.fetchFromGitHub {
      hash = "sha256-6IQ57nXyFfNanl6RJRTnIn8P2W1yHo4E82SsgErE2Eo=";
      owner = "jakeleveroni";
      repo = "hyprland-scroll-overview";
      rev = "82f03826ed2b424c4cfdac06a88241dd18679d8b";
    };
    version = "0-unstable-82f0382";
  });
in
{
  wayland.windowManager.hyprland = {
    extraConfig = ''
      hl.define_submap("scrolloverview", function()
        for key, direction in pairs({
          ["SUPER + J"] = "down",
          ["SUPER + K"] = "up",
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
