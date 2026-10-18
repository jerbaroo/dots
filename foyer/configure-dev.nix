{ pkgs, generatedSettings }:
pkgs.writeShellApplication {
  name = "configure-dev";
  runtimeInputs = [ pkgs.coreutils ];
  text = ''
    # Keep generated settings in the checkout's ignored development directory.
    output="quickshell/dev-generated"

    # Copy generated modules from the Nix store with writable file permissions.
    mkdir -p "$output"
    cp -R --no-preserve=mode ${generatedSettings}/. "$output/"
    printf 'Generated settings in %s\n' "$output"
  '';
}
