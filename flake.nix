{
  description = "NixOS";
  inputs = {
    catppuccin.url = "github:catppuccin/nix";
    color-schemes = {
      flake = false;
      url = "github:mbadolato/iTerm2-Color-Schemes";
    };
    nix-doom-emacs-unstraightened = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "git+https://github.com/marienz/nix-doom-emacs-unstraightened";
    };
    foyer = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:jerbaroo/foyer";
    };
    home-manager = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/home-manager/master";
    };
    hyprland = {
      # Important to follow nixpkgs to ensure graphics match.
      inputs.nixpkgs.follows = "nixpkgs";
      # Required for hyprglasss (bumping this requires a bump in hyprglass.nix):
      # https://github.com/hyprnux/hyprglass/blob/main/.hyprland-version
      url = "github:hyprwm/Hyprland?ref=refs/tags/v0.56.2";
    };
    nixgl.url = "github:nix-community/nixGL";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs_stable.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs_latest.url = "github:NixOS/nixpkgs/nixos-unstable";
    spicetify.url = "github:Gerg-L/spicetify-nix";
  };
  outputs =
    inputs:
    let
      hmConfigs = import ./hm-configs.nix { inherit inputs; };
      nixosConfigs = import ./nixos-configs.nix { inherit inputs; };
      pkgs = import inputs.nixpkgs {
        system = "x86_64-linux";
        #  overlays = [ inputs.hyprland.overlays.hyprland-packages ];
      };
      pkgs_latest = import inputs.nixpkgs_latest { system = "x86_64-linux"; };
      pkgs_stable = import inputs.nixpkgs_stable { system = "x86_64-linux"; };
      hyprlandPkgs = import inputs.nixpkgs {
        system = "x86_64-linux";
        overlays = [
          inputs.hyprland.overlays.hyprland-packages
          # The pinned Hyprland overlay omits its locked toolkit. The newer
          # nixpkgs toolkit requires a newer hyprutils than this Hyprland uses.
          inputs.hyprland.inputs.hyprland-guiutils.inputs.hyprtoolkit.overlays.default
          inputs.hyprland.overlays.hyprland-extras
          (final: prev: {
            # Hyprland 0.56 requires Glaze 7; unstable now provides Glaze 8.
            glaze-hyprland = pkgs_stable.glaze.override {
              enableSSL = false;
              enableInterop = false;
            };
            # NixOS requires an ELF executable for its capability wrapper.
            hyprland = prev.hyprland.override { makeWrapper = final.makeBinaryWrapper; };
          })
        ];
      };
      sharedArgs = {
        accent = "lavender";
        catppuccin = inputs.catppuccin;
        colorSchemes = inputs.color-schemes;
        doomModule = inputs.nix-doom-emacs-unstraightened.homeModule;
        flavor = "mocha";
        foyer = inputs.foyer;
        hyprlandPackages = {
          inherit (hyprlandPkgs) hyprland xdg-desktop-portal-hyprland;
        };
        inherit pkgs_latest;
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
