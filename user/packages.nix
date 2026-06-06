{ pkgs, ... }:
{
  home.packages = with pkgs; [
    fd # 'find' alternative, required by Doom Emacs.
    gcc # GNU Compiler Collection.
    github-copilot-cli # AI Sparkles.
    idasen # Desk control.
    jq # JSON processor.
    niv # Nix dependency manager.
    nix # Nix package manager.
    nixfmt # Nix formatter.
    nix-output-monitor # Pretty nix command info.
    nix-tree # Nix dependency browser.
    nh # Nix helper.
    pandoc # Document converter.
    pre-commit # House cleaning.
    pulseaudio # pactl.
    python3 # For quick scripts.
    python3Packages.black # Python formatter.
    shellcheck # Shell script analyser.
    shfmt # Shell parser and formatter.
    unzip # Unzip zip files.
    wev # Wayland event viewer.
    wl-clipboard # Wayland command-line copy and paste.
  ];
}
