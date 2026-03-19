{ ghdashboardPort, pkgs, ... }:
{
  programs.chromium = {
    enable = true;
    extensions = [
      { id = "blaaajhemilngeeffpbfkdjjoefldkok"; } # LeechBlock NG
      { id = "dbepggeogbaibhgnhhndojpepiihcmeb"; } # Vimium
      { id = "ddkjiahejlhfcafbddmgiahcphecmpfh"; } # uBlock Origin Lite
    ];
  };
}
