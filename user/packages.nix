{ pkgs, ... }:
{
  home.packages = with pkgs; [
    btop # Resource monitor.
    cbonsai # Screensaver.
    fastfetch # System info fetch.
    fd # 'find' alternative, required by Doom Emacs.
    feh # Image viewer.
    ffmpeg # Video converter.
    footage # Video editor.
    gcc # GNU Compiler Collection.
    jq # JSON processor.
    neo # The one screensaver.
    niv # Nix dependency manager.
    nitch # System info fetch.
    nix # Nix package manager.
    nixfmt-rfc-style # Nix formatter.
    nix-output-monitor # Pretty nix command info.
    nix-tree # Nix dependency browser.
    nh # Nix helper.
    obs-studio # Video recorder.
    pandoc # Document converter.
    python3 # For quick scripts.
    shellcheck # Shell script analyser.
    shfmt # Shell parser and formatter.
    texliveFull # LaTeX.
    unzip # Unzip zip files.
    vlc # Video player.
    wev # Wayland event viewer.
    wl-clipboard # Wayland command-line copy and paste.
  ];
}
