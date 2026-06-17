{ inputs }:
[
  rec {
    allowUnfreePredicate = _: true;
    hostname = "nixos";
    homeConfig =
      { config, pkgs, ... }:
      {
        desktop = {
          inherit hostname username;
          genericLinux = {
            enable = false;
            nixGL.packages = inputs.nixgl.packages;
          };
          startup.extraCommands = [
            {
              cmd = config.desktop.openrgb.command;
              name = "openrgb";
            }
          ];
        };
        home.packages = with pkgs; [
          cbonsai # Screensaver.
          fastfetch # System info fetch.
          feh # Image viewer.
          ffmpeg # Video converter.
          footage # Video editor.
          google-chrome # Well-supported browser.
          mpv # Better HDR support.
          neo # The one screensaver.
          obs-studio # Video recorder.
          texliveFull # LaTeX.
          vlc # Video player.
        ];
      };
    username = "jer";
  }
]
