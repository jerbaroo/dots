{ ghdashboardPort, pkgs, ... }:
{
  programs.chromium = {
    enable = true;
    extensions = [
      { id = "ebboehhiijjcihmopcggopfgchnfepkn"; } # CHROLED Theme
      { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; } # Dark Reader
      { id = "blaaajhemilngeeffpbfkdjjoefldkok"; } # LeechBlock NG
      { id = "dbepggeogbaibhgnhhndojpepiihcmeb"; } # Vimium
      { id = "ddkjiahejlhfcafbddmgiahcphecmpfh"; } # uBlock Origin Lite
    ];
  };
}
