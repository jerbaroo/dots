{
  accent,
  allowUnfree,
  codeFontName,
  config,
  flavor,
  hostname,
  hyprland,
  pkgs,
  stateVersion,
  system,
  username,
  ...
}:
{
  home-manager = {
    extraSpecialArgs = {
      inherit accent;
      inherit codeFontName;
      inherit flavor;
      inherit stateVersion;
      inherit system;
      inherit username;
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
      "nix-command"
      "flakes"
    ];
    substituters = [
      "https://cosmic.cachix.org/"
      "https://nixcache.reflex-frp.org"
    ];
    trusted-public-keys = [
      "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
      "ryantrinkle.com-1:JJiAKaRv9mWgpVAz8dwewnZe0AzzEAzPkagE9SP5NWI="
    ];
  };
  nixpkgs.config.allowUnfree = allowUnfree;
  programs.adb.enable = true; # TODO
  system.stateVersion = stateVersion;
  users.users.${username} = {
    extraGroups = [
      "adbusers"
      "docker"
      "kvm"
      "networkmanager"
      "wheel"
    ];
    isNormalUser = true;
  };
}
