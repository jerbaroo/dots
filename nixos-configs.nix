[
  {
    allowUnfreePredicate = _: true;
    hostname = "nixos";
    home =
      { pkgs, ... }:
      {
        desktop.startup.extraCommands = [
          {
            cmd = config: config.desktop.openrgb.command;
            name = "openrgb";
          }
        ];
        home.packages = [ ];
      };
    username = "jer";
  }
]
