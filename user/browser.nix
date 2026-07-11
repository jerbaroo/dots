{
  config,
  lib,
  pkgs,
  zen,
  ...
}:
let
  chromiumPkg = config.lib.nixGL.wrap pkgs.chromium;
  firefoxExtension = shortId: guid: {
    name = guid;
    value = {
      install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/${shortId}/latest.xpi";
      installation_mode = "normal_installed";
    };
  };
  zenPkg = config.lib.nixGL.wrap (
    pkgs.wrapFirefox zen.packages.${pkgs.stdenv.hostPlatform.system}.zen-browser-unwrapped {
      extraPolicies = {
        DisableTelemetry = true;
        ExtensionSettings = builtins.listToAttrs [
          (firefoxExtension "darkreader" "addon@darkreader.org")
          (firefoxExtension "leechblock-ng" "leechblockng@proginosko.com")
          (firefoxExtension "vimium-ff" "{d7742d87-e61d-4b78-b8a1-b469842139fa}")
          (firefoxExtension "ublock-origin" "uBlock0@raymondhill.net")
        ];
        SearchEngines = {
          Default = "google";
          Add = [
            {
              Alias = "@np";
              IconURL = "https://wiki.nixos.org/favicon.ico";
              Name = "nixpkgs packages";
              URLTemplate = "https://search.nixos.org/packages?query={searchTerms}";
            }
            {
              Alias = "@no";
              IconURL = "https://noogle.dev/favicon.ico";
              Name = "noogle";
              URLTemplate = "https://noogle.dev/q?term={searchTerms}";
            }
          ];
        };
      };
      extraPrefs = lib.concatLines (
        lib.mapAttrsToList
          (name: value: "lockPref(${lib.strings.toJSON name}, ${lib.strings.toJSON value});")
          {
            # See about:config
            "extensions.autoDisableScopes" = 0;
            "extensions.pocket.enabled" = false;
          }
      );
    }
  );
in
{
  config = {
    home.packages = [ zenPkg ];
    programs.chromium = {
      commandLineArgs = [
        "--disable-gpu" # FIXME
        # Disable the horizontal notification banners that drop down.
        "--disable-infobars"
        # Disable the "Chrome didn't shut down correctly" popup.
        "--disable-session-crashed-bubble"
        # Ensures that Chromium-internal pages like "This site can't be reached"
        # are also in dark mode. In fact it applies dark mode to ALL Pages, so
        # we have two layers of dark mode (also DarkReader).
        "--enable-features=WebContentsForceDark"
        "--new-window"
        config.desktop.browser.homepage
      ];
      enable = true;
      extensions = [
        { id = "ebboehhiijjcihmopcggopfgchnfepkn"; } # CHROLED Theme
        { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; } # Dark Reader
        { id = "blaaajhemilngeeffpbfkdjjoefldkok"; } # LeechBlock NG
        { id = "dbepggeogbaibhgnhhndojpepiihcmeb"; } # Vimium
        { id = "ddkjiahejlhfcafbddmgiahcphecmpfh"; } # uBlock Origin Lite
      ];
      package = chromiumPkg;
    };
  };
  options.desktop.browser = {
    cmd = lib.mkOption {
      default = "${zenPkg}/bin/zen";
      description = "Command to open a browser";
      type = lib.types.str;
    };
    cmd2 = lib.mkOption {
      default = "chromium";
      description = "Command to open another browser";
      type = lib.types.str;
    };
    homepage = lib.mkOption {
      default = "https://google.com";
      description = "Homepage";
      type = lib.types.str;
    };
  };
}
