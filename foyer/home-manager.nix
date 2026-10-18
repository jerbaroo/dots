{
  config,
  lib,
  pkgs,
  ...
}:
let
  foyer = config.programs.foyer;
  generatedSettings = import ./generate-settings.nix {
    inherit pkgs;
    settings = foyer;
  };
  qmlSource = "${pkgs.nix-gitignore.gitignoreSource [ ] ./.}/quickshell";
  configDir = pkgs.runCommandLocal "foyer-config" { } ''
    mkdir $out
    cp -r ${qmlSource}/. $out/
    chmod -R u+w $out
    cp -r ${generatedSettings}/. $out/
  '';
  quickshellPkg = pkgs.quickshell;
  makeService = humanName: fileName: {
    Install.WantedBy = [ "graphical-session.target" ];
    Service = {
      Environment = [
        "QML_IMPORT_PATH=${config.xdg.configHome}/foyer"
        "QS_ICON_THEME=${foyer.iconTheme.name}"
      ];
      ExecStart = "${quickshellPkg}/bin/quickshell -p ${config.xdg.configHome}/foyer/${fileName}.qml";
      Restart = "on-failure";
    };
    Unit = {
      After = [ "graphical-session.target" ];
      Description = humanName;
      BindsTo = [ "graphical-session.target" ];
      # Restart when the QML or generated FoyerConfig changes.
      X-Restart-Triggers = [ configDir ];
    };
  };
  foyerServer = pkgs.callPackage ./foyer-server/foyer-server.nix { };
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf foyer.enable {
    fonts.fontconfig.enable = true;
    home.packages = [
      foyer.font.package
      foyer.iconTheme.package
      foyer.package
      foyerServer
    ];
    home.sessionVariables.QML_IMPORT_PATH = "${config.xdg.configHome}/foyer";
    home.sessionVariables.QS_ICON_THEME = foyer.iconTheme.name;
    programs.quickshell = {
      enable = true;
      package = quickshellPkg;
    };
    qt.enable = true;
    systemd.user.services.foyer-bar = makeService "Foyer Bar" "bar";
    systemd.user.services.foyer-launcher = makeService "Foyer Launcher" "app_launcher";
    systemd.user.services.foyer-server = {
      Install.WantedBy = [ "graphical-session.target" ];
      Service = {
        ExecStart = "${foyerServer}/bin/foyer-server --port ${toString foyer.search.port}";
        Restart = "on-failure";
      };
      Unit = {
        After = [ "graphical-session.target" ];
        Description = "Foyer server";
        BindsTo = [ "graphical-session.target" ];
      };
    };
    xdg.configFile."foyer" = {
      recursive = true;
      source = configDir;
    };
  };
}
