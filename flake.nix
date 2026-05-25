{
  description = "NixOS";
  inputs = {
    catppuccin.url = "github:catppuccin/nix";
    color-schemes = {
      flake = false;
      url = "github:mbadolato/iTerm2-Color-Schemes";
    };
    home-manager = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/home-manager/master";
    };
    ignis = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:linkfrg/ignis";
    };
    hyprland = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:hyprwm/Hyprland";
    };
    nixgl.url = "github:nix-community/nixGL";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      # Prevents Nix from downloading and compiling a second, slightly different
      # version of Qt6 and other heavy dependencies.
      inputs.nixpkgs.follows = "nixpkgs";
    };
    spicetify.url = "github:Gerg-L/spicetify-nix";
  };
  outputs =
    inputs:
    let
      hostnameNixOS = "nixos";
      hmConfigs = import ./hm-configs.nix;
      usernameNixOS = "jer";
      pkgs = import inputs.nixpkgs {
        overlays = [
          inputs.nixgl.overlay
        ];
        inherit system;
      };
      system = "x86_64-linux";

      sharedArgs = {
        inherit system;
        accent = "pink";
        animationSpeed = 1.0;
        bitDepth = 10;
        blur = true;
        borderSize = 2;
        catppuccin = inputs.catppuccin;
        codeBackgroundOpacity = 0.7;
        codeFontName = "Iosevka Nerd Font Mono";
        codeFontSize = 12;
        colorSchemes = inputs.color-schemes;
        defaultFloatSize = 0.8;
        flavor = "mocha";
        gap = 0;
        ghdashboardPort = 1234;
        hdr = true;
        hyprland = inputs.hyprland;
        ignis = inputs.ignis;
        layout = "scrolling";
        lockTimeout = 120;
        nixgl = inputs.nixgl;
        quickshell = inputs.quickshell;
        rounding = 1;
        spicetify = inputs.spicetify;
        stateVersion = "26.05";
        systemFontSize = 12;
        temperature = 5500;
        wallpaperName = "jellyfish-purple.jpg";
      };
    in
    {
      nixosConfigurations = {
        ${hostnameNixOS} = inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./system/nixos.nix
            inputs.catppuccin.nixosModules.catppuccin
            inputs.home-manager.nixosModules.home-manager
          ];
          specialArgs = sharedArgs // {
            allowUnfreePredicate = _: true;
            genericLinux = false;
            hostname = hostnameNixOS;
            startupExtraCommands = [
              {
                cmd = config: config.desktop.openrgb.command;
                name = "openrgb";
              }
            ];
            username = usernameNixOS;
            wrapGL = false;
          };
        };
      };
      homeConfigurations = builtins.listToAttrs (
        map (hmConfig: {
          name = "${hmConfig.username}@${hmConfig.hostname}";
          value = inputs.home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            extraSpecialArgs =
              let
                hmArgs = {
                  allowUnfreePredicate =
                    let
                      whitelist = map pkgs.lib.getName [
                        pkgs.google-chrome
                        pkgs.spotify
                        pkgs.steam
                        pkgs.steam-unwrapped
                        pkgs.symbola
                      ];
                    in
                    pkg: builtins.elem (pkgs.lib.getName pkg) whitelist;
                  genericLinux = true;
                  wrapGL = true;
                };
              in
              sharedArgs // hmArgs // hmConfig;
            modules = [ ./user/home.nix ];
          };
        }) hmConfigs
      );
    };
}
