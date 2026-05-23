{
  config,
  ghdashboardPort,
  pkgs,
  wrapGL,
  ...
}:
let
  pkg = pkgs.chromium;
  # pkg = (if wrapGL then config.lib.nixGL.wrap else (x: x)) pkgs.chromium;
in
{
  cmd = "${pkg}/bin/chromium --disable-gpu"; # FIXME
  hm = {
    programs.chromium = {
      # commandLineArgs = ["--enable-features=VaapiVideoDecodeLinuxGL,VaapiVideoEncoder,Vulkan,VulkanFromANGLE,DefaultANGLEVulkan,VaapiIgnoreDriverChecks,VaapiVideoDecoder,PlatformHEVCDecoderSupport,UseMultiPlaneFormatForHardwareVideo"];
      enable = true;
      extensions = [
        { id = "ebboehhiijjcihmopcggopfgchnfepkn"; } # CHROLED Theme
        { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; } # Dark Reader
        { id = "blaaajhemilngeeffpbfkdjjoefldkok"; } # LeechBlock NG
        { id = "dbepggeogbaibhgnhhndojpepiihcmeb"; } # Vimium
        { id = "ddkjiahejlhfcafbddmgiahcphecmpfh"; } # uBlock Origin Lite
      ];
    };
  };
}
