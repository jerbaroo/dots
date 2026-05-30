{ pkgs }:
pkgs.rustPlatform.buildRustPackage {
  pname = "shell-server";
  version = "0.1.0";
  src = ./.;
  cargoLock.lockFile = ./Cargo.lock;
}
