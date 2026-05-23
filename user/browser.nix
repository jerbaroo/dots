{
  config,
  ghdashboardPort,
  lib,
  pkgs,
  ...
}:
{
  config = {
    desktop.browser.cmd = "${pkgs.chromium}/bin/chromium --disable-gpu"; # FIXME
    programs.chromium = {
      enable = true;
      extensions = [
        { id = "ebboehhiijjcihmopcggopfgchnfepkn"; } # CHROLED Theme
        { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; } # Dark Reader
        { id = "blaaajhemilngeeffpbfkdjjoefldkok"; } # LeechBlock NG
        { id = "dbepggeogbaibhgnhhndojpepiihcmeb"; } # Vimium
        { id = "ddkjiahejlhfcafbddmgiahcphecmpfh"; } # uBlock Origin Lite
      ];
      homepageLocation = "http://localhost:${ghdashboardPort}";
    };
  };
  options.desktop.browser.cmd = lib.mkOption {
    description = "Command to open a browser";
    readOnly = true;
    type = lib.types.str;
  };
}
