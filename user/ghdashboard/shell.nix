{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  buildInputs = with pkgs; [
    (python3.withPackages (
      python-pkgs: with python-pkgs; [
        flask
        requests
      ]
    ))
  ];
}
