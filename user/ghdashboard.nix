{
  config,
  lib,
  pkgs,
  ...
}:
let
  ghdashboard = pkgs.callPackage ./ghdashboard/default.nix { };
  ghdashboardWithParams = pkgs.writeShellScriptBin "ghdashboardwithparams" "${ghdashboard}/bin/ghdashboard ${toString config.desktop.ghdashboard.port} ${config.desktop.ghdashboard.readToken} $@";
in
{
  config = lib.mkIf config.desktop.ghdashboard.enable {
    home.packages = [ ghdashboardWithParams ];
    systemd.user.services.ghdashboard = lib.mkIf (config.desktop.ghdashboard.port != null) {
      Unit = {
        After = [ "graphical-session.target" ];
        BindsTo = [ "graphical-session.target" ];
        Description = "GitHub Dashboard";
      };
      Service = {
        ExecStart = "${ghdashboardWithParams}/bin/ghdashboardwithparams";
        Restart = "on-failure";
      };
      # Ready to run on graphical session start, but still needs to wait on
      # targets in "After".
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
  options.desktop.ghdashboard = {
    enable = lib.mkOption {
      default = true;
      description = "Port to serve the GitHub Dashboard on.";
      type = lib.types.bool;
    };
    port = lib.mkOption {
      default = 1234;
      description = "Port to serve the GitHub Dashboard on.";
      type = lib.types.port;
    };
    readToken = lib.mkOption {
      default = "/home/${config.desktop.username}/.config/read-ghdashboard-token.sh";
      description = "Path to script that returns a GitHub token.";
      type = lib.types.str;
    };
  };
}
