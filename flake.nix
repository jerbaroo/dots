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
    nur.url = "github:nix-community/NUR";
    spicetify.url = "github:Gerg-L/spicetify-nix";
  };
  outputs =
    inputs:
    let
      accent = "pink";
      allowUnfreePredicate =
        let whitelist = map pkgs.lib.getName [ pkgs.spotify ];
        in  pkg: builtins.elem (pkgs.lib.getName pkg) whitelist;
      borderSize = 2;
      codeBackgroundOpacity = 0.8;
      codeFontName = "Iosevka Nerd Font Mono";
      codeFontSize = 14;
      flavor = "mocha";
      gap = 3;
      ghdashboardPort = 1234;
      hostname = "nixos";
      lockTimeout = 120;
      pkgs = import inputs.nixpkgs {
        overlays = [
          inputs.nixgl.overlay
          inputs.nur.overlays.default
        ];
        inherit system;
      };
      rounding = 8;
      stateVersion = "25.05";
      system = "x86_64-linux";
      systemFontSize = 16;
      temperature = 3000;
      username = "jeremy-barisch-rooney";
      wallpaperName = "gengar.png";
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
