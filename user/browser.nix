{
  config,
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
        # Ensures that Chromium-internal pages like "This site can't be reached"
        # are also in dark mode. In fact it applies dark mode to ALL Pages, so
        # we have two layers of dark mode (also DarkReader).
        "--enable-features=WebContentsForceDark"
        "http://localhost:${toString config.desktop.ghdashboard.port}"
      ];
    };
  };
  options.desktop.browser.cmd = lib.mkOption {
    description = "Command to open a browser";
    readOnly = true;
    type = lib.types.str;
  };
}
