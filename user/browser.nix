{
  config,
  lib,
  pkgs,
  ...
}:
let
  pkg = config.desktop.wrapGL pkgs.chromium;
in
{
  config = {
    desktop.browser.cmd = "chromium";
    programs.chromium = {
      commandLineArgs = [
        "--disable-gpu" # FIXME
        # Disable the horizontal notification banners that drop downl.
        "--disable-infobars"
        # Disable the "Chrome didn't shut down correctly" popup.
        "--disable-session-crashed-bubble"
        # Ensures that Chromium-internal pages like "This site can't be reached"
        # are also in dark mode. In fact it applies dark mode to ALL Pages, so
        # we have two layers of dark mode (also DarkReader).
        "--enable-features=WebContentsForceDark"
        "http://localhost:${toString config.desktop.ghdashboard.port}"
      ];
      enable = true;
      extensions = [
        { id = "ebboehhiijjcihmopcggopfgchnfepkn"; } # CHROLED Theme
        { id = "pflnpcinjbcfefgbejjfanemlgcfjbna"; } # Show Tab Numbers
        { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; } # Dark Reader
        { id = "blaaajhemilngeeffpbfkdjjoefldkok"; } # LeechBlock NG
        { id = "dbepggeogbaibhgnhhndojpepiihcmeb"; } # Vimium
        { id = "ddkjiahejlhfcafbddmgiahcphecmpfh"; } # uBlock Origin Lite
      ];
      package = pkg;
    };
  };
  options.desktop.browser.cmd = lib.mkOption {
    description = "Command to open a browser";
    readOnly = true;
    type = lib.types.str;
  };
}
