{
  accent,
  allowUnfreePredicate,
  animationSpeed,
  bitDepth,
  blur,
  borderSize,
  catppuccin,
  codeBackgroundOpacity,
  codeFontName,
  codeFontSize,
  color-schemes,
  config,
  defaultFloatSize,
  flavor,
  gap,
  ghdashboardPort,
  hdr,
  hostname,
  hyprland,
  genericLinux,
  ignis,
  layout,
  lib,
  lockTimeout,
  nixgl,
  pkgs,
  quickshell,
  rounding,
  spicetify,
  stateVersion,
  system,
  systemFontSize,
  temperature,
  username,
  wallpaperName,
  wrapGL,
  ...
}:
let
  # Where we install ignis configuration. Relative to home directory.
  ignisPath = ".config/ignis/";
  palette =
    (pkgs.lib.importJSON (config.catppuccin.sources.palette + "/palette.json")).${flavor}.colors;
in
{
  # Set custom Home Manager options.
  desktop = {
    inherit username wallpaperName;
    ghdashboard.port = ghdashboardPort;
    hyprland = {
      inherit
        animationSpeed
        blur
        gap
        layout
        rounding
        ;
    };
    hyprsunset.temperature = temperature;
  };
  home = {
    homeDirectory = "/home/${username}";
    stateVersion = stateVersion;
    username = "${username}";
  };
  imports = [
    # 3rd-party Home Manager modules.
    catppuccin.homeModules.catppuccin
    ignis.homeManagerModules.default
    spicetify.homeManagerModules.default

    # Personal Home Manager modules.
    ./audio.nix
    ./bluetooth.nix
    (import ./browser.nix {
      inherit config;
      inherit ghdashboardPort;
      inherit lib;
      inherit pkgs;
    })
    # ./os-cli.nix
    ./direnv.nix
    (import ./emacs/emacs.nix {
      inherit codeFontName;
      inherit codeFontSize;
      inherit codeBackgroundOpacity;
      inherit flavor;
      inherit palette;
      inherit pkgs;
    })
    ./eza.nix
    (import ./fish.nix {
      inherit accent;
      inherit lib;
      inherit palette;
      inherit pkgs;
      inherit username;
    })
    (import ./fonts.nix {
      inherit pkgs;
      inherit systemFontSize;
    })
    (import ./ghostty.nix {
      inherit accent;
      inherit codeFontName;
      inherit codeFontSize;
      inherit codeBackgroundOpacity;
      inherit color-schemes;
      inherit config;
      inherit flavor;
      inherit pkgs;
      inherit system;
      inherit wrapGL;
    })
    (import ./ghdashboard.nix {
      inherit
        config
        lib
        pkgs
        username
        ;
    })
    ./git.nix
    (import ./helix.nix {
      inherit accent;
      inherit flavor;
      inherit lib;
      inherit pkgs;
    })
    (import ./hypridle.nix {
      inherit lockTimeout;
      inherit pkgs;
    })
    (import ./hyprland.nix {
      inherit accent;
      inherit bitDepth;
      inherit borderSize;
      inherit config;
      inherit defaultFloatSize;
      inherit flavor;
      inherit hdr;
      inherit hostname;
      inherit hyprland;
      inherit ignis;
      inherit ignisPath;
      inherit lib;
      inherit lockTimeout;
      inherit palette;
      inherit pkgs;
      inherit system;
      inherit username;
      inherit wrapGL;
    })
    ./hyprsunset.nix
    (import ./ignis.nix {
      inherit accent;
      inherit config;
      inherit ignis;
      inherit ignisPath;
      inherit palette;
      inherit pkgs;
    }).hm
    (import ./kanata/kanata.nix { inherit pkgs; }).hm
    (import ./kitty.nix {
      inherit codeBackgroundOpacity;
      inherit codeFontName;
      inherit codeFontSize;
      inherit config;
      inherit pkgs;
      inherit wrapGL;
    })
    (import ./openrgb.nix { inherit pkgs; }).hm
    ./neovim.nix
    ./notifications.nix
    ./packages.nix
    ./qt.nix
    (import ./quickshell.nix {
      inherit lib;
      inherit pkgs;
      inherit quickshell;
      inherit system;
    })
    (import ./spicetify.nix {
      inherit accent;
      inherit flavor;
      inherit palette;
      inherit pkgs;
      inherit spicetify;
    })
    ./starship.nix
    (import ./theme.nix {
      inherit accent;
      inherit flavor;
      inherit pkgs;
    })
    (import ./tmux.nix {
      inherit accent;
      inherit palette;
      inherit pkgs;
    })
    ./wallpaper.nix
    ./wallpaper-service.nix
    ./wlogout.nix
  ];
  nixpkgs.config = {
    inherit allowUnfreePredicate;
  };
  programs.home-manager.enable = true;
  targets.genericLinux = {
    enable = genericLinux;
    nixGL = {
      defaultWrapper = "mesa";
      packages = nixgl.packages;
    };
  };
  xdg.configFile."environment.d/envvars.conf".text = ''
    PATH="$HOME/.config/emacs/bin:$HOME/.nix-profile/bin:$HOME/.cargo/bin:$HOME/${username}/.ghcup/bin:$HOME/.cabal/bin:$PATH"
  '';
}
