{
  accent,
  allowUnfreePredicate,
  animations,
  bitDepth,
  catppuccin,
  config,
  flavor,
  homeBase,
  homeConfig,
  hostname,
  hyprland,
  genericLinux,
  ignis,
  layout,
  lib,
  nixgl,
  pkgs,
  spicetify,
  stateVersion,
  system,
  username,
  ...
}:
{
  home-manager = {
    extraSpecialArgs = {
      inherit
        accent
        animations
        bitDepth
        catppuccin
        flavor
        hostname
        hyprland
        ignis
        layout
        nixgl
        spicetify
        stateVersion
        system
        username
        ;
      allowUnfreePredicate = null;
      genericLinux = true;
    };
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${username} = {
      imports = [
        ../user/home.nix
        homeBase
        homeConfig
      ];
    };
  };
  imports = [
    (import ./boot.nix { inherit pkgs; })
    (import ./bluetooth.nix { inherit lib; })
    ./desktop.nix
    ./docker.nix
    ./firmware.nix
    (import ./graphics.nix {
      inherit hyprland;
      inherit pkgs;
      inherit system;
    })
    ./hardware-configuration.nix
    ./kanata.nix
    ./keyboard.nix
    ./lanzaboote.nix
    ./locale.nix
    (import ./network.nix { inherit hostname; })
    ./openrgb.nix
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
