{ pkgs, ... }:
let
  ghcidPoll = pkgs.writeShellScriptBin "ghcid" ''
    ${pkgs.ghcid}/bin/ghcid --poll "$@"
  '';
in
{
  home.packages = with pkgs; [
    bacon # mmmmm
    brightnessctl # 🔆🔆🔆
    chatgpt
    codex # skynet
    ddcutil # Monitor brightness over DDC (menu bar).
    gh # Slob Hub.
    ghc # Glorious Haskell Compiler.
    ghciwatch # Mercury's ghcid.
    ghcidPoll # Ol' reliable.
    gcc # GNU Compiler Collection.
    jq # JSON processor.
    niv # Nix dependency manager.
    nixfmt # Nix formatter.
    nix-output-monitor # Pretty nix command info.
    nix-tree # Nix dependency browser.
    nh # Nix helper.
    pandoc # Document converter.
    pgcli # PG CLI.
    pre-commit # House cleaning.
    proton-pass # Say friend and enter.
    python3 # For quick scripts.
    python3Packages.black # Python formatter.
    shellcheck # Shell script analyser.
    shfmt # Shell parser and formatter.
    unzip # Unzip zip files.
    watchexec # exec on file-change.
    wev # Wayland event viewer.
    wl-clipboard # Wayland command-line copy and paste.
  ];
}
