{
  accent,
  allowUnfreePredicate,
  borderSize,
  catppuccin,
  codeBackgroundOpacity,
  codeFontName,
  codeFontSize,
  color-schemes,
  config,
  flavor,
  gap,
  ghdashboardPort,
  hostname,
  hyprland,
  genericLinux,
  ignis,
  lib,
  lockTimeout,
  nixgl,
  pkgs,
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
  imports = [
    catppuccin.homeModules.catppuccin
    ignis.homeManagerModules.default
    spicetify.homeManagerModules.default

    (import ./bluetooth.nix { inherit pkgs; }).hm
    (import ./browser.nix { inherit ghdashboardPort; inherit pkgs; })
    ./direnv.nix
    (import ./emacs.nix {
      inherit codeFontName;
      inherit codeFontSize;
      inherit codeBackgroundOpacity;
      inherit flavor;
      inherit pkgs;
    })
    ./eza.nix
    (import ./fish.nix {
      inherit accent;
      inherit lib;
      inherit pkgs;
      inherit username;
    })
    (import ./fonts.nix { inherit pkgs; inherit systemFontSize; })
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
    ./git.nix
    (import ./helix.nix {
      inherit accent;
      inherit flavor;
      inherit lib;
      inherit pkgs;
    })
    (import ./hyprland.nix {
      inherit accent;
      inherit borderSize;
      inherit config;
      inherit flavor;
      inherit gap;
      inherit ghdashboardPort;
      inherit hostname;
      inherit hyprland;
      inherit ignis;
      inherit ignisPath;
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
    (import ./ignis.nix {
      inherit accent;
      inherit ignis;
      inherit ignisPath;
      inherit palette;
      inherit pkgs;
    }).hm
    (import ./kitty.nix {
      inherit codeBackgroundOpacity;
      inherit codeFontName;
      inherit codeFontSize;
      inherit config;
      inherit pkgs;
      inherit wrapGL;
    })
    (import ./neovim.nix {
      inherit pkgs;
    })
    ./notifications.nix
    ./packages.nix
    ./quickshell.nix
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
  home = {
    homeDirectory = "/home/${username}";
    stateVersion = stateVersion;
    username = "${username}";
  };
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
