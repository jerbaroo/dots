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
      # Required for hyprglasss:
      # https://github.com/hyprnux/hyprglass/blob/main/.hyprland-version
      url = "github:hyprwm/Hyprland?ref=refs/tags/v0.55.2";
    };
    lanzaboote = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/lanzaboote/v1.0.0";
    };
    nixgl.url = "github:nix-community/nixGL";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    spicetify.url = "github:Gerg-L/spicetify-nix";
  };
  outputs =
    inputs:
    let
      hmConfigs = import ./hm-configs.nix { inherit inputs; };
      nixosConfigs = import ./nixos-configs.nix { inherit inputs; };
      pkgs = import inputs.nixpkgs {
        system = "x86_64-linux";
        overlays = [ inputs.hyprland.overlays.hyprland-packages ];
      };
      sharedArgs = {
        accent = "pink";
        catppuccin = inputs.catppuccin;
        colorSchemes = inputs.color-schemes;
        flavor = "mocha";
        hyprland = inputs.hyprland;
        ignis = inputs.ignis;
        spicetify = inputs.spicetify;
        stateVersion = "26.05";
        system = "x86_64-linux";
      };
    in
    {
      nixosConfigurations = builtins.listToAttrs (
        map (nixosConfig: {
          name = "${nixosConfig.hostname}";
          value = inputs.nixpkgs.lib.nixosSystem {
            modules = [
              ./system/nixos.nix
              inputs.catppuccin.nixosModules.catppuccin
              inputs.home-manager.nixosModules.home-manager
              inputs.lanzaboote.nixosModules.lanzaboote
            ];
            specialArgs = sharedArgs // nixosConfig;
          };
        }) nixosConfigs
      );
      homeConfigurations = builtins.listToAttrs (
        map (hmConfig: {
          name = "${hmConfig.username}@${hmConfig.hostname}";
          value = inputs.home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            extraSpecialArgs = sharedArgs;
            modules = [
              hmConfig.homeConfig
              ./user/home.nix
            ];
          };
        }) hmConfigs
      );
    };
}
