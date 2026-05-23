{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  buildInputs = [
    pkgs.black
    pkgs.nixfmt
    pkgs.pre-commit
  ];
}
