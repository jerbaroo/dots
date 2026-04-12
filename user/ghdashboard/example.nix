let
  pkgs = import <nixpkgs> { };
  port = 6767;
  ghdashboard = import "${
    builtins.fetchTarball {
      sha256 = "sha256:1xfab6mf63lvb64rgvpvknmnn7j0c19bc0f5xsdmhq9093x11f0f";
      url = "https://github.com/jerbaroo/nixos-config/archive/main.tar.gz";
    }
  }/user/ghdashboard/default.nix" { inherit pkgs; };
  read-gh-token = pkgs.writeShellScriptBin "read-gh-token" "echo fetch-pwd-from-pwd-manager";
in
# Or put this somewhere to execute at startup via Home Manager.
pkgs.writeShellScriptBin "run-the-dashboard"
  "${ghdashboard}/bin/ghdashboard ${toString port} '${read-gh-token}/bin/read-gh-token'"
