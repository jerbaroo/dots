{
  config,
  ghdashboardPort,
  lib,
  pkgs,
  ...
}:
{
  config = {
    desktop.browser.cmd = "chromium";
    programs.chromium = {
      enable = true;
      extensions = [
        { id = "ebboehhiijjcihmopcggopfgchnfepkn"; } # CHROLED Theme
        { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; } # Dark Reader
        { id = "blaaajhemilngeeffpbfkdjjoefldkok"; } # LeechBlock NG
        { id = "dbepggeogbaibhgnhhndojpepiihcmeb"; } # Vimium
        { id = "ddkjiahejlhfcafbddmgiahcphecmpfh"; } # uBlock Origin Lite
      ];
      commandLineArgs = [
        "--disable-gpu" # FIXME
        "http://localhost:${toString ghdashboardPort}"
      ];
    };
  };
  options.desktop.browser.cmd = lib.mkOption {
    description = "Command to open a browser";
    readOnly = true;
    type = lib.types.str;
  };
}
