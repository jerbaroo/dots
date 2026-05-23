{
  accent,
  allowUnfreePredicate,
  animationSpeed,
  animations,
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
  # Custom Home Manager options.
  desktop.hyprland.layout = layout;

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
    (import ./bluetooth.nix { inherit pkgs; }).hm
    (import ./browser.nix {
      inherit config;
      inherit ghdashboardPort;
      inherit pkgs;
      inherit wrapGL;
    }).hm
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
      inherit ghdashboardPort;
      inherit pkgs;
      inherit username;
    }).hm
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
      inherit animationSpeed;
      inherit animations;
      inherit bitDepth;
      inherit blur;
      inherit borderSize;
      inherit config;
      inherit defaultFloatSize;
      inherit flavor;
      inherit gap;
      inherit ghdashboardPort;
      inherit hdr;
      inherit hostname;
      inherit hyprland;
      inherit ignis;
      inherit ignisPath;
      inherit lib;
      inherit lockTimeout;
      inherit palette;
      inherit pkgs;
      inherit rounding;
      inherit system;
      inherit temperature;
      inherit username;
      inherit wallpaperName;
      inherit wrapGL;
    })
    (import ./hyprsunset.nix { inherit temperature; })
    (import ./ignis.nix {
      inherit accent;
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
    ./sound.nix
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
    (import ./wallpaper-service.nix {
      inherit pkgs;
      inherit wallpaperName;
    })
    (import ./wlogout.nix {
      inherit pkgs;
      inherit wallpaperName;
    })
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
