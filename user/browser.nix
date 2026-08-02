{
  config,
  lib,
  pkgs,
  system,
  ...
}:
let
  chromiumPkg = config.lib.nixGL.wrap pkgs.chromium;
  commonExtensions = [
    {
      name = "darkreader";
      firefoxId = "addon@darkreader.org";
      chromiumId = "eimadpbcbfnmbkopoojfekhnkhdbieeh";
    }
    {
      name = "leechblock-ng";
      firefoxId = "leechblockng@proginosko.com";
      chromiumId = "blaaajhemilngeeffpbfkdjjoefldkok";
    }
    {
      name = "vimium-ff";
      firefoxId = "{d7742d87-e61d-4b78-b8a1-b469842139fa}";
      chromiumId = "dbepggeogbaibhgnhhndojpepiihcmeb";
    }
    {
      name = "ublock-origin";
      firefoxId = "uBlock0@raymondhill.net";
      chromiumId = "ddkjiahejlhfcafbddmgiahcphecmpfh";
    }
  ];
  firefoxExtension = { name, firefoxId, ... }: {
    name = firefoxId;
    value = {
      install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/${name}/latest.xpi";
      installation_mode = "normal_installed";
    };
  };
in
{
  config = {
    catppuccin.firefox.force = true;
    # Run Firefox natively on Wayland instead of via XWayland.
    home.sessionVariables.MOZ_ENABLE_WAYLAND = "1";
    programs.firefox = {
      enable = true;
      policies = {
        DisableTelemetry = true;
        DisableFirefoxStudies = true;
        DisablePocket = true;
        DontCheckDefaultBrowser = true;
        EncryptedMediaExtensions.Enabled = true; # Widevine (Netflix, etc.).
        ExtensionSettings = builtins.listToAttrs (map firefoxExtension commonExtensions) // {
          # Firefox Color is required by the Catppuccin Firefox module, which
          # only provides this extension's theme but does not install it.
          "FirefoxColor@mozilla.com" = {
            install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/firefox-color/latest.xpi";
            installation_mode = "normal_installed";
          };
        };
        FirefoxHome = {
          Pocket = false;
          SponsoredPocket = false;
          SponsoredTopSites = false;
          Snippets = false;
        };
        Homepage = {
          StartPage = "homepage";
          URL = config.desktop.browser.homepage;
        };
        NoDefaultBookmarks = true;
        OverrideFirstRunPage = "";
        OverridePostUpdatePage = "";
        UserMessaging = {
          ExtensionRecommendations = false;
          SkipOnboarding = true;
          WhatsNew = false;
        };
      };
      profiles.default = {
        id = 0;
        isDefault = true;
        search = {
          default = "google";
          force = true;
          engines = {
            "hoogle" = {
              urls = [ { template = "https://hoogle.haskell.org/?hoogle={searchTerms}"; } ];
              icon = "https://hoogle.haskell.org/favicon.ico";
              definedAliases = [ "@h" ];
            };
            "nixpkgs packages" = {
              urls = [ { template = "https://search.nixos.org/packages?query={searchTerms}"; } ];
              icon = "https://wiki.nixos.org/favicon.ico";
              definedAliases = [ "@np" ];
            };
            "noogle" = {
              urls = [ { template = "https://noogle.dev/q?term={searchTerms}"; } ];
              icon = "https://noogle.dev/favicon.ico";
              definedAliases = [ "@no" ];
            };
          };
        };
        settings = {
          "browser.aboutConfig.showWarning" = false;
          "browser.compactmode.show" = true;
          "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
          "browser.newtabpage.activity-stream.showSponsored" = false;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "browser.newtabpage.activity-stream.showWeather" = false;
          "browser.tabs.warnOnClose" = false;
          "browser.urlbar.suggest.quicksuggest.sponsored" = false;
          "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
          "dom.security.https_only_mode" = true;
          "extensions.autoDisableScopes" = 0;
          "extensions.pocket.enabled" = false;
          "gfx.webrender.all" = true;
          "media.ffmpeg.vaapi.enabled" = true;
        };
      };
    };
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
        { id = "ebboehhiijjcihmopcggopfgchnfepkn"; }
      ] # CHROLED Theme
      ++ map ({ chromiumId, ... }: { id = chromiumId; }) commonExtensions;
      package = chromiumPkg;
    };
  };
  options.desktop.browser = {
    cmd = lib.mkOption {
      default = "${config.programs.firefox.finalPackage}/bin/firefox";
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
