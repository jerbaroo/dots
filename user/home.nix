{
  accent,
  allowUnfreePredicate,
  animationSpeed,
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
  startupExtraCommands,
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
  # Set custom Home Manager options.
  desktop = {
    inherit
      hostname
      system
      username
      wallpaperName
      ;
    font = {
      code = {
        name = codeFontName;
        size = codeFontSize;
        backgroundOpacity = codeBackgroundOpacity;
      };
      system = {
        size = systemFontSize;
      };
    };
    genericLinux = {
      enable = genericLinux;
      nixGL.packages = nixgl.packages;
    };
    ghdashboard.port = ghdashboardPort;
    hyprland = {
      inherit
        animationSpeed
        blur
        gap
        layout
        rounding
        ;
      border.size = borderSize;
      float.size.default = defaultFloatSize;
      package = hyprland.packages.${system}.hyprland;
    };
    hyprsunset.temperature = temperature;
    ignis = {
      configDir.path = ".config/ignis";
      package = ignis.packages.${system}.ignis;
    };
    lock.timeout = lockTimeout;
    spicetify.packages = spicetify.legacyPackages.${system};
    startup.extraCommands = startupExtraCommands;
    theme = {
      inherit accent colorSchemes flavor;
      palette =
        (pkgs.lib.importJSON (config.catppuccin.sources.palette + "/palette.json")).${flavor}.colors;
    };
    wrapGL = if wrapGL then config.lib.nixGL.wrap else (x: x);
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
