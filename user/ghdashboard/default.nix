{
  pkgs,
  palette ? { },
  ...
}:
let
  name = "ghdashboard";
  # Colour name -> hex. Anything not given falls back to Catppuccin Mocha, so
  # the package still builds standalone (see README).
  mocha = {
    base = "#1e1e2e";
    mantle = "#181825";
    crust = "#11111b";
    text = "#cdd6f4";
    subtext0 = "#a6adc8";
    subtext1 = "#bac2de";
    surface0 = "#313244";
    surface1 = "#45475a";
    overlay0 = "#6c7086";
    rosewater = "#f5e0dc";
    flamingo = "#f2cdcd";
    pink = "#f5c2e7";
    mauve = "#cba6f7";
    red = "#f38ba8";
    maroon = "#eba0ac";
    peach = "#fab387";
    yellow = "#f9e2af";
    green = "#a6e3a1";
    teal = "#94e2d5";
    sky = "#89dceb";
    sapphire = "#74c7ec";
    blue = "#89b4fa";
    lavender = "#b4befe";
  };
  # intersectAttrs drops palette colours the page has no placeholder for;
  # replaceVars treats an unused one as an error.
  indexHtml = pkgs.replaceVars ./index.html (mocha // builtins.intersectAttrs mocha palette);
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
    cp server.py query.graphql $out/share/app/
    cp ${indexHtml} $out/share/app/index.html

    # --add-flags: tell Python to execute the server.py script.
    # --prefix PYTHONPATH: ensure Python path includes the py libraries.
    # --run: change to data dir, so it finds index.html etc..
    makeWrapper ${pkgs.python3}/bin/python $out/bin/${name} \
      --add-flags "$out/share/app/server.py" \
      --prefix PYTHONPATH : "$PYTHONPATH" \
      --run "cd $out/share/app"
  '';
}
