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
  colorSchemes,
  config,
  defaultFloatSize,
  flavor,
  gap,
  ghdashboardPort,
  hdr,
  home,
  hostname,
  hyprland,
  genericLinux,
  ignis,
  layout,
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
{
  home-manager = {
    extraSpecialArgs = {
      inherit
        accent
        animationSpeed
        animations
        bitDepth
        blur
        borderSize
        catppuccin
        codeBackgroundOpacity
        codeFontName
        codeFontSize
        colorSchemes
        defaultFloatSize
        flavor
        gap
        ghdashboardPort
        hdr
        hostname
        hyprland
        ignis
        layout
        lockTimeout
        nixgl
        rounding
        spicetify
        stateVersion
        system
        systemFontSize
        temperature
        username
        wallpaperName
        ;
      allowUnfreePredicate = null;
      genericLinux = true;
      wrapGL = true;
    };
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${username} = {
      imports = [
        ../user/home.nix
        home
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
