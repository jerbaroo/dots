{
  config,
  lib,
  pkgs,
  pkgs_latest,
  system,
  ...
}:
let
  builtinThemeIds = {
    alpenglow = "firefox-alpenglow@mozilla.org";
    dark = "firefox-compact-dark@mozilla.org";
    light = "firefox-compact-light@mozilla.org";
  };
  changeByHex = lib.mapAttrs' (
    _: colour: lib.nameValuePair colour.from colour.to
  ) config.desktop.theme.paletteChanges;
  chromiumPkg = config.lib.nixGL.wrap pkgs.chromium;
  commonExtensions = [
    {
      chromiumId = "eimadpbcbfnmbkopoojfekhnkhdbieeh";
      firefoxId = "addon@darkreader.org";
      name = "darkreader";
    }
    {
      chromiumId = "blaaajhemilngeeffpbfkdjjoefldkok";
      firefoxId = "leechblockng@proginosko.com";
      name = "leechblock-ng";
    }
    {
      chromiumId = "dbepggeogbaibhgnhhndojpepiihcmeb";
      firefoxId = "{d7742d87-e61d-4b78-b8a1-b469842139fa}";
      name = "vimium-ff";
    }
    {
      chromiumId = "ddkjiahejlhfcafbddmgiahcphecmpfh";
      firefoxId = "uBlock0@raymondhill.net";
      name = "ublock-origin";
    }
  ];
  firefoxExtension =
    { firefoxId, name, ... }:
    {
      name = firefoxId;
      value = {
        install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/${name}/latest.xpi";
        installation_mode = "normal_installed";
      };
    };
  flavourTheme =
    (lib.importJSON "${config.catppuccin.sources.firefox}/themes.json")
    .${config.desktop.theme.flavor}.${config.desktop.theme.accent};
  repalettedTheme = flavourTheme // {
    colors = lib.mapAttrs (
      _: colour:
      let
        hex = toHex colour;
      in
      if changeByHex ? ${hex} then toRgb changeByHex.${hex} else colour
    ) flavourTheme.colors;
  };
  toHex =
    colour:
    "#"
    + lib.concatMapStrings (n: lib.toLower (lib.fixedWidthString 2 "0" (lib.toHexString n))) [
      colour.r
      colour.g
      colour.b
    ];
  toRgb = hex: {
    b = lib.fromHexString (builtins.substring 5 2 hex);
    g = lib.fromHexString (builtins.substring 3 2 hex);
    r = lib.fromHexString (builtins.substring 1 2 hex);
  };
  useCatppuccin = config.desktop.browser.firefox.theme == "theme";
in
{
  config = {
    catppuccin.firefox = {
      enable = useCatppuccin;
      force = true;
    };
    # Run Firefox natively on Wayland instead of via XWayland.
    home.sessionVariables.MOZ_ENABLE_WAYLAND = "1";
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
      ]
      ++ map (
        { chromiumId, ... }:
        {
          id = chromiumId;
        }
      ) commonExtensions;
      package = chromiumPkg;
    };
    programs.firefox = {
      enable = true;
      # Avoid using 'pkgs_latest' as it can break xdg-portal.
      package = pkgs_latest.firefox;
      policies = {
        DisableFirefoxStudies = true;
        DisablePocket = true;
        DisableTelemetry = true;
        DontCheckDefaultBrowser = true;
        EncryptedMediaExtensions.Enabled = true; # Widevine (Netflix, etc.).
        ExtensionSettings = builtins.listToAttrs (map firefoxExtension commonExtensions) // {
          # Firefox Color is required by the Catppuccin Firefox module, which
          # only provides this extension's theme but does not install it.
          "FirefoxColor@mozilla.com" =
            if useCatppuccin then
              {
                install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/firefox-color/latest.xpi";
                installation_mode = "normal_installed";
              }
            else
              {
                # Keep a saved Firefox Color theme from overriding built-in themes.
                installation_mode = "blocked";
              };
        };
        FirefoxHome = {
          Pocket = false;
          Snippets = false;
          SponsoredPocket = false;
          SponsoredTopSites = false;
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
        extensions.settings."FirefoxColor@mozilla.com".settings.theme = lib.mkIf (
          config.desktop.browser.firefox.theme == "theme" && config.desktop.theme.paletteChanges != { }
        ) (lib.mkForce repalettedTheme);
        id = 0;
        isDefault = true;
        search = {
          default = "google";
          engines = {
            "hoogle" = {
              definedAliases = [ "@h" ];
              icon = "https://hoogle.haskell.org/favicon.ico";
              urls = [ { template = "https://hoogle.haskell.org/?hoogle={searchTerms}"; } ];
            };
            "nixpkgs packages" = {
              definedAliases = [ "@np" ];
              icon = "https://wiki.nixos.org/favicon.ico";
              urls = [ { template = "https://search.nixos.org/packages?query={searchTerms}"; } ];
            };
            "noogle" = {
              definedAliases = [ "@no" ];
              icon = "https://noogle.dev/favicon.ico";
              urls = [ { template = "https://noogle.dev/q?term={searchTerms}"; } ];
            };
          };
          force = true;
        };
        settings = {
          "browser.aboutConfig.showWarning" = false;
          "browser.compactmode.show" = true;
          "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
          "browser.newtabpage.activity-stream.showSponsored" = false;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "browser.newtabpage.activity-stream.showWeather" = false;
          # Firefox's profile group backend (SelectableProfileService) rewrites
          # `profiles.ini` to add `StoreID`/`ShowSelector`, but Home Manager
          # owns that file as a read-only /nix/store symlink. The failed write
          # makes Firefox fork onto an unmanaged profile that has none of the
          # config below, including the Catppuccin theme. Disabling the feature
          # short-circuits its init (`SelectableProfileService.sys.mjs`, see `if
          # (!this.isEnabled) return;`) before it touches `profiles.ini`.
          "browser.profiles.enabled" = false;
          "browser.tabs.warnOnClose" = false;
          "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
          "browser.urlbar.suggest.quicksuggest.sponsored" = false;
          "dom.security.https_only_mode" = true;
          "extensions.activeThemeID" = lib.mkIf (
            !useCatppuccin
          ) builtinThemeIds.${config.desktop.browser.firefox.theme};
          "extensions.autoDisableScopes" = 0;
          "extensions.pocket.enabled" = false;
          "gfx.webrender.all" = true;
          # Keep content, including the new-tab page, dark independently of the toolbar theme.
          "layout.css.prefers-color-scheme.content-override" = 0;
          "media.ffmpeg.vaapi.enabled" = true;
          "services.sync.prefs.sync.extensions.activeThemeID" = lib.mkIf (!useCatppuccin) false;
          "toolkit.legacyUserProfileCustomizations.stylesheets" = lib.mkIf config.desktop.theme.oled true;
          "widget.use-xdg-desktop-portal.mime-handler" = 1;
          "widget.use-xdg-desktop-portal.open-uri" = 1;
        };
        userChrome = lib.optionalString config.desktop.theme.oled ''
          :root {
            --tabpanel-background-color: #000000 !important;
          }

          #appMenu-popup,
          panel:has(#allTabsMenu-allTabsView),
          panel:has(#PanelUI-fxa),
          panel:has(#PanelUI-profiles) {
            --panel-background-color: #000000 !important;
            --panel-text-color: #fbfbfe !important;
          }
        '';
        userContent = lib.optionalString config.desktop.theme.oled ''
          @-moz-document url("about:newtab"), url("about:home") {
            :root {
              color-scheme: dark !important;
              --newtab-background-color: #000000 !important;
              --newtab-text-primary-color: #fbfbfe !important;
            }

            html, body {
              background-color: #000000 !important;
              background-image: none !important;
              color: #fbfbfe !important;
            }
          }
        '';
      };
    };
    xdg.mimeApps = {
      defaultApplications = {
        "application/xhtml+xml" = [ "firefox.desktop" ];
        "text/html" = [ "firefox.desktop" ];
        "x-scheme-handler/http" = [ "firefox.desktop" ];
        "x-scheme-handler/https" = [ "firefox.desktop" ];
      };
      enable = true;
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
    firefox.theme = lib.mkOption {
      default = "theme";
      description = ''
        Firefox UI theme. "theme" follows desktop.theme.flavor and accent,
        applying desktop.theme.paletteChanges (including OLED backgrounds).
        "dark", "light", and "alpenglow" use Firefox's built-in themes.
        Existing profiles may need the built-in theme enabled once in Firefox's
        Themes page; setting the preference alone does not always activate it.
      '';
      type = lib.types.enum [
        "alpenglow"
        "dark"
        "light"
        "theme"
      ];
    };
    homepage = lib.mkOption {
      default = "https://google.com";
      description = "Homepage";
      type = lib.types.str;
    };
  };
}
