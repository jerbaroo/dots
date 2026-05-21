{
  config,
  ghdashboardPort,
  pkgs,
  wrapGL,
  ...
}:
{
  programs.chromium = {
    # commandLineArgs = ["--enable-features=VaapiVideoDecodeLinuxGL,VaapiVideoEncoder,Vulkan,VulkanFromANGLE,DefaultANGLEVulkan,VaapiIgnoreDriverChecks,VaapiVideoDecoder,PlatformHEVCDecoderSupport,UseMultiPlaneFormatForHardwareVideo"];
    enable = true;
    # package = (if wrapGL then config.lib.nixGL.wrap else (x: x)) pkgs.chromium;
    extensions = [
      { id = "ebboehhiijjcihmopcggopfgchnfepkn"; } # CHROLED Theme
      { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; } # Dark Reader
      { id = "blaaajhemilngeeffpbfkdjjoefldkok"; } # LeechBlock NG
      { id = "dbepggeogbaibhgnhhndojpepiihcmeb"; } # Vimium
      { id = "ddkjiahejlhfcafbddmgiahcphecmpfh"; } # uBlock Origin Lite
    ];
  };
}
