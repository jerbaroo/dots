{
  config,
  lib,
  pkgs,
  username,
}:
let
  ghdashboard = ./ghdashboard/default.nix;
  ghdashboardWithToken = pkgs.writeShellScriptBin "ghdashboardwithtoken" "${ghdashboard}/bin/ghdashboard ${toString config.desktop.ghdashboard.port} /home/${username}/.config/read-gh-token.sh";
in
{
  config = {
    systemd.user.services.ghdashboard = {
      Unit = {
        After = [ "graphical-session.target" ];
        Description = "GitHub Dashboard";
        BindsTo = [ "graphical-session.target" ];
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
