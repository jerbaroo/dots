{
  ghdashboardPort,
  pkgs,
  username,
}:
let
  ghdashboard = import ./ghdashboard/default.nix { inherit pkgs; };
  ghdashboardwithtoken = pkgs.writeShellScriptBin "ghdashboardwithtoken" "${ghdashboard}/bin/ghdashboard ${toString ghdashboardPort} /home/${username}/.config/read-gh-token.sh";
in
{
  cmd = "${ghdashboardwithtoken}/bin/ghdashboardwithtoken";
  hm = {
    home.packages = [ ghdashboardwithtoken ];
  };
}
