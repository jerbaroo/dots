{
  description = "Dev shell for development of quickshell (and supporting) components.";

  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

  outputs =
    { self, nixpkgs }:

    let
      pkgs = nixpkgs.legacyPackages.${system};
      system = "x86_64-linux";
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          cargo
          clippy
          rust-analyzer
          rustc
          rustfmt
          rustlings
        ];
        env.RUST_SRC_PATH = pkgs.rust.packages.stable.rustPlatform.rustLibSrc;
      };
    };
}
