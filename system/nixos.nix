{
  accent,
  allowUnfreePredicate,
  catppuccin,
  colorSchemes,
  config,
  flavor,
  homeConfig,
  hostname,
  hyprland,
  ignis,
  lib,
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
        catppuccin
        colorSchemes
        flavor
        hostname
        hyprland
        ignis
        spicetify
        stateVersion
        system
        username
        ;
      allowUnfreePredicate = null;
    };
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${username} = {
      imports = [
        ../user/home.nix
        homeConfig
      ];
    };
  };
  imports = [
    ./boot.nix
    ./bluetooth.nix
    ./desktop.nix
    ./docker.nix
    ./firmware.nix
    ./graphics.nix
    ./hardware-configuration.nix
    ./kanata.nix
    ./keyboard.nix
    ./lanzaboote.nix
    ./locale.nix
    ./network.nix
    ./openrgb.nix
    ./printing.nix
    ./sound.nix
    ./steam.nix
    ./store.nix
    ./theme.nix
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
