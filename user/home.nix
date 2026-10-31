{
  accent,
  catppuccin,
  colorSchemes,
  config,
  flavor,
  hyprlandPackages,
  lib,
  pkgs,
  spicetify,
  stateVersion,
  system,
  ...
}:
{
  # Set Home Manager options using module parameters.
  desktop = {
    inherit
      system
      ;
    hyprland.packages = hyprlandPackages;
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
    spicetify.homeManagerModules.default

    # Define common Home Manager options.
    ./options.nix

    # Personal Home Manager modules.
    ./agents.nix
    ./animation.nix
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
    ./kanata/kanata.nix
    ./kitty.nix
    ./lock.nix
    ./monitor.nix
    ./openrgb.nix
    ./os-cli.nix
    ./neovim.nix
    ./packages.nix
    ./qt.nix
    ./foyer.nix
    ./spicetify.nix
    ./starship.nix
    ./startup.nix
    ./swaync.nix
    ./terminal.nix
    ./portal.nix
    ./theme.nix
    ./tmux.nix
    ./wallpaper.nix
    ./wallpaper-service.nix
    ./wlogout.nix
  ];
  # We use "mkIf" because setting this is not permitted on NixOS (instead this
  # should be set in NixOS' configuration directly).
  nixpkgs.config = lib.mkIf (config.desktop.allowUnfreePredicate != null) {
    allowUnfreePredicate = config.desktop.allowUnfreePredicate;
  };
  programs.home-manager.enable = true;
  xdg.configFile."mpv/mpv.conf".text = ''
    panscan=0
    script-opts-append=dynamic_crop-mode=4
    target-colorspace-hint=auto
    # Let Hyprland's auto HDR detect HDR content with mpv 0.41 and later.
    target-colorspace-hint-mode=source
    vo=gpu-next
  '';
  xdg.configFile."mpv/scripts/dynamic-crop.lua".source = pkgs.fetchurl {
    hash = "sha256-My8xSzJGF9cDjADDraCNJXFg4QdmyAGADb3qMl/hECI=";
    url = "https://raw.githubusercontent.com/Ashyni/mpv-scripts/d3f5685f5209ae548f8398b21d4dcbbea766d076/dynamic-crop.lua";
  };
  xdg.configFile."yazi/yazi.toml".text = ''
    [mgr]
    sort_by = "alphabetical"
    sort_dir_first = false
    sort_sensitive = false
  '';
  xdg.mimeApps.defaultApplications = {
    "video/matroska" = [ "mpv.desktop" ];
    "video/mp4" = [ "mpv.desktop" ];
    "video/webm" = [ "mpv.desktop" ];
    "video/x-matroska" = [ "mpv.desktop" ];
  };
}
