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
{
  home-manager = {
    extraSpecialArgs = {
      inherit accent;
      inherit allowUnfreePredicate;
      inherit animationSpeed;
      inherit animations;
      inherit bitDepth;
      inherit blur;
      inherit borderSize;
      inherit codeBackgroundOpacity;
      inherit codeFontName;
      inherit codeFontSize;
      inherit defaultFloatSize;
      inherit flavor;
      inherit gap;
      inherit ghdashboardPort;
      inherit hdr;
      inherit hostname;
      inherit hyprland;
      inherit ignis;
      inherit layout;
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
    (import ./boot.nix { inherit pkgs; })
    (import ./bluetooth.nix { inherit lib; })
    ./docker.nix
    ./firmware.nix
    (import ./graphics.nix {
      inherit hyprland;
      inherit pkgs;
      inherit system;
    })
    ./hardware-configuration.nix
    (import ../user/kanata/kanata.nix { inherit pkgs; }).nixos
    ./keyboard.nix
    ./locale.nix
    (import ./network.nix { inherit hostname; })
    (import ../user/openrgb.nix { inherit pkgs; }).nixos
    ./printing.nix
    (import ./sound.nix { inherit pkgs; })
    ./steam.nix
    ./store.nix
    (import ./theme.nix { inherit accent flavor pkgs; })
    ./transmission.nix
  ];
  nixpkgs.config.allowUnfreePredicate = allowUnfreePredicate;
  nix.settings = {
    experimental-features = [
      "flakes"
      "nix-command"
    ];
    substituters = [ ];
    trusted-public-keys = [ ];
  };
  system.stateVersion = stateVersion;
  users.users.${username} = {
    extraGroups = [
      "audio"
      "bluetooth"
      "docker"
      "networkmanager"
      "wheel"
    ];
    isNormalUser = true;
  };
}
