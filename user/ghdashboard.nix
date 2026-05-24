{
  config,
  lib,
  pkgs,
  ...
}:
let
  ghdashboard = pkgs.callPackage ./ghdashboard/default.nix { };
  ghdashboardWithToken = pkgs.writeShellScriptBin "ghdashboardwithtoken" "${ghdashboard}/bin/ghdashboard ${toString config.desktop.ghdashboard.port} /home/${config.desktop.username}/.config/read-gh-token.sh";
in
{
  config = {
    home.packages = [ ghdashboardWithToken ];
    systemd.user.services.ghdashboard = {
      Unit = {
        After = [ "graphical-session.target" ];
        BindsTo = [ "graphical-session.target" ];
        Description = "GitHub Dashboard";
      };
      Service = {
        ExecStart = "${ghdashboardWithToken}/bin/ghdashboardwithtoken";
        Restart = "on-failure";
      };
      # Ready to run on graphical session start, but still needs to wait on
      # targets in "After".
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
  options = {
    desktop.ghdashboard.port = lib.mkOption {
      description = "Port to serve the GitHub Dashboard on.";
      type = lib.types.port;
    };
  };
}
