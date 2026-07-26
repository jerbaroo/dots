{
  config,
  lib,
  pkgs,
  ...
}:
let
  c = colour: pkgs.lib.strings.removePrefix "#" config.desktop.theme.palette.${colour}.hex;
  # We wrap the distro-packaged swaylock package with a custom theme.
  # We don't use the swaylock from Nix packages due to PAM issues.
  swaylock_ = pkgs.writeShellScriptBin "swaylock_" ''
    swaylock \
      --font 'Atkinson Hyperlegible' \
      --font-size 196 \
      --indicator-caps-lock \
      --indicator-radius 256 \
      --indicator-thickness 64 \
      \
        --color 000000 \
        --inside-color 000000 \
        --line-color 000000 \
        --ring-color ${c "blue"} \
        --separator-color 000000 \
        --text-color ${c "text"} \
      \
        --key-hl-color ${c "pink"} \
        --bs-hl-color ${c "peach"} \
      \
        --inside-wrong-color ${c "red"} \
        --line-wrong-color ${c "red"} \
        --ring-wrong-color ${c "red"} \
        --text-wrong-color ${c "base"} \
      \
        --inside-ver-color ${c "green"} \
        --line-ver-color ${c "green"} \
        --ring-ver-color ${c "green"} \
        --text-ver-color ${c "base"} \
      \
        --inside-clear-color ${c "mauve"} \
        --line-clear-color ${c "mauve"} \
        --ring-clear-color ${c "mauve"} \
        --text-clear-color ${c "base"} \
      \
        --caps-lock-bs-hl-color ${c "yellow"} \
        --caps-lock-key-hl-color ${c "yellow"} \
        --inside-caps-lock-color ${c "base"} \
        --line-caps-lock-color ${c "yellow"} \
        --ring-caps-lock-color ${c "yellow"} \
        --text-caps-lock-color ${c "base"} \
      \
        --layout-bg-color ${c "base"} \
        --layout-border-color ${c "surface0"} \
        --layout-text-color ${c "text"}
  '';
in
{
  options.desktop.lock = {
    cmd = lib.mkOption {
      default = "${swaylock_}/bin/swaylock_";
      type = lib.types.str;
    };
    inhibitPath = lib.mkOption {
      default = "/tmp/inhibit_lock";
      description = "Flag file to tell idling programs (e.g. hypridle) to skip locking.";
      type = lib.types.str;
    };
    unlessNoLock = lib.mkOption {
      default = cmd: "[ -e ${config.desktop.lock.inhibitPath} ] || { ${cmd}; }";
      description = ''
        Wraps a shell command (run via `sh -c`) so it is skipped while
        `inhibitPath` exists.
      '';
      internal = true;
      readOnly = true;
      type = lib.types.functionTo lib.types.str;
    };
    timeout = lib.mkOption {
      default = 180;
      description = "Time until system locks.";
      type = lib.types.ints.unsigned;
    };
  };
  config = {
    home.packages = [
      # We make sure that, regardless of the locking program, it can be found
      # at the same command. TODO use CLI for this.
      (pkgs.writeShellScriptBin "os-lock" "${config.desktop.lock.cmd}")
      swaylock_
    ];
  };
}
