{
  accent,
  allowUnfreePredicate,
  catppuccin,
  colorSchemes,
  config,
  flavor,
  hostname,
  hyprland,
  ignis,
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
  # Set Home Manager options using module parameters.
  desktop = {
    inherit
      hostname
      system
      username
      ;
    hyprland.packages = hyprland.packages.${system};
    ignis = {
      configDir.path = ".config/ignis";
      package = ignis.packages.${system}.ignis;
    };
    spicetify.packages = spicetify.legacyPackages.${system};
    # Theme options taken as parameters because, either they are shared with
    # NixOS, or they come from "inputs".
    theme = { inherit accent colorSchemes flavor; };
  };
  home = {
    homeDirectory = "/home/${config.desktop.username}";
    stateVersion = stateVersion;
    username = "${config.desktop.username}";
  };
  imports = [
    # 3rd-party Home Manager modules.
    catppuccin.homeModules.catppuccin
    ignis.homeManagerModules.default
    spicetify.homeManagerModules.default

    # Define common Home Manager options.
    ./options.nix

    # Personal Home Manager modules.
    ./audio.nix
    ./btop.nix
    ./bluetooth.nix
    ./browser.nix
    ./direnv.nix
    ./emacs/emacs.nix
    ./eza.nix
    ./fish.nix
    ./fonts.nix
    ./genericLinux.nix
    ./ghostty.nix
    ./ghdashboard.nix
    ./git.nix
    ./hypridle.nix
    ./hyprland.nix
    ./hyprglass.nix
    ./hyprsunset.nix
    ./ignis.nix
    ./kanata/kanata.nix
    ./kitty.nix
    ./lock.nix
    ./monitor.nix
    ./openrgb.nix
    ./os-cli.nix
    ./neovim.nix
    ./notifications.nix
    ./packages.nix
    ./qt.nix
    ./quickshell.nix
    ./spicetify.nix
    ./starship.nix
    ./startup.nix
    ./terminal.nix
    ./theme.nix
    ./tmux.nix
    ./wallpaper.nix
    ./wallpaper-service.nix
    ./wlogout.nix
  ];
  # We use "mkIf" because setting this is not permitted on NixOS (instead this
  # should be set in NixOS' configuration directly).
  nixpkgs.config = lib.mkIf (allowUnfreePredicate != null) {
    inherit allowUnfreePredicate;
  };
  programs.home-manager.enable = true;
}
