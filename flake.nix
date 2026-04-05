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
    spicetify.url = "github:Gerg-L/spicetify-nix";
  };
  outputs =
    inputs:
    let
      accent = "pink";
      animationSpeed = 2;
      animations = true;
      allowUnfreePredicate =
        let whitelist = map pkgs.lib.getName [ pkgs.spotify pkgs.symbola ];
        in  pkg: builtins.elem (pkgs.lib.getName pkg) whitelist;
      blur = true;
      borderSize = 2;
      codeBackgroundOpacity = 0.7;
      codeFontName = "Iosevka Nerd Font Mono";
      codeFontSize = 12;
      flavor = "mocha";
      gap = 0;
      ghdashboardPort = 1234;
      hostname = "nixos";
      lockTimeout = 120;
      pkgs = import inputs.nixpkgs {
        overlays = [
          inputs.nixgl.overlay
        ];
        inherit system;
      };
      rounding = 1;
      stateVersion = "26.05";
      system = "x86_64-linux";
      systemFontSize = 12;
      temperature = 4000;
      username = "jeremy-barisch-rooney";
      wallpaperName = "jellyfish-purple.jpg";
    in
    {
      nixosConfigurations = {
        ${hostname} = inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./system/nixos.nix
            inputs.catppuccin.nixosModules.catppuccin
            inputs.home-manager.nixosModules.home-manager
          ];
          specialArgs = {
            inherit accent;
            inherit codeFontName;
            inherit codeFontSize;
            inherit flavor;
            inherit stateVersion;
            inherit system;
            inherit username;
            hyprland = inputs.hyprland;
          };
        };
      };
      homeConfigurations = {
        "${username}@${hostname}" = inputs.home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
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
            inherit lockTimeout;
            inherit rounding;
            inherit stateVersion;
            inherit system;
            inherit systemFontSize;
            inherit temperature;
            inherit username;
            inherit wallpaperName;
            catppuccin = inputs.catppuccin;
            color-schemes = inputs.color-schemes;
            genericLinux = true;
            hyprland = inputs.hyprland;
            ignis = inputs.ignis;
            nixgl = inputs.nixgl;
            spicetify = inputs.spicetify;
            wrapGL = true;
          };
          modules = [ ./user/home.nix ];
        };
      };
    };
}
