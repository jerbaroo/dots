{
  accent,
  allowUnfreePredicate,
  animationSpeed,
  animations,
  blur,
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
{
  home-manager = {
    extraSpecialArgs = {
      inherit accent;
      inherit allowUnfreePredicate;
      inherit animationSpeed;
      inherit animations;
      inherit blur;
      inherit borderSize;
      inherit codeBackgroundOpacity;
      inherit codeFontName;
      inherit codeFontSize;
      inherit flavor;
      inherit gap;
      inherit ghdashboardPort;
      inherit hostname;
      inherit hyprland;
      inherit ignis;
      inherit lockTimeout;
      inherit nixgl;
      inherit quickshell;
      inherit rounding;
      inherit spicetify;
      inherit stateVersion;
      inherit system;
      inherit systemFontSize;
      inherit temperature;
      inherit username;
      inherit wallpaperName;
      inherit catppuccin;
      inherit color-schemes;
      genericLinux = true;
      wrapGL = true;
    };
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${username} = import ../user/home.nix;
  };
  imports = [
    ./boot.nix
    ./docker.nix
    (import ./graphics.nix {
      inherit hyprland;
      inherit pkgs;
      inherit system;
    })
    ./hardware-configuration.nix
    ./keyboard.nix
    ./locale.nix
    (import ./network.nix { inherit hostname; })
    ./openrgb.nix
    ./printing.nix
    ./sound.nix
    ./steam.nix
    ./store.nix
    (import ./theme.nix {
      inherit accent;
      inherit flavor;
    })
    ./transmission.nix
  ];
  nix.settings = {
    experimental-features = [
      "flakes"
      "nix-command"
    ];
    substituters = [ ];
    trusted-public-keys = [ ];
  };
  nixpkgs.config.allowUnfreePredicate = allowUnfreePredicate;
  system.stateVersion = stateVersion;
  users.users.${username} = {
    extraGroups = [
      "docker"
      "networkmanager"
      "wheel"
    ];
    isNormalUser = true;
  };
}
