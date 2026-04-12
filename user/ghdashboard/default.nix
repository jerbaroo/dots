{ pkgs, ... }:
let
  name = "ghdashboard";
in
pkgs.python3Packages.buildPythonApplication {
  pname = name;
  version = "1.0.0";
  src = ./.;
  # Build-time deps.
  nativeBuildInputs = [ pkgs.makeWrapper ];
  # Run-time deps.
  propagatedBuildInputs = with pkgs.python3Packages; [
    flask
    requests
  ];
  # Tells Nix NOT to look for setup.py or pyproject.toml.
  format = "other";
  installPhase = ''
    # Create binary and data dirs.
    mkdir -p $out/bin $out/share/app
    # Copy source files over to data dir.
    cp server.py index.html query.graphql $out/share/app/

    # --add-flags: tell Python to execute the server.py script.
    # --prefix PYTHONPATH: ensure Python path includes the py libraries.
    # --run: change to data dir, so it finds index.html etc..
    makeWrapper ${pkgs.python3}/bin/python $out/bin/${name} \
      --add-flags "$out/share/app/server.py" \
      --prefix PYTHONPATH : "$PYTHONPATH" \
      --run "cd $out/share/app"
  '';
}
