{ pkgs }:
let
  python = pkgs.python3.withPackages (ps: [ ps.click ]);
in
pkgs.writeShellScriptBin "foyer" ''
  export PATH="${pkgs.quickshell}/bin:$PATH"
  exec ${python}/bin/python3 ${./cli.py} "$@"
''
