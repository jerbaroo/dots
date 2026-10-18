{ pkgs }:
pkgs.rustPlatform.buildRustPackage {
  pname = "foyer-server";
  version = "0.1.0";
  src = ./.;
  cargoLock.lockFile = ./Cargo.lock;
}
