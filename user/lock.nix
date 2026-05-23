{
  ignisPath,
  palette,
  pkgs,
  ...
}:
let
  c = colour: pkgs.lib.strings.removePrefix "#" palette.${colour}.hex;
  # The lock screen program we currently use.
  os-lock = pkgs.writeShellScriptBin "os-lock" "${swaylock_}/bin/swaylock_";
  # We wrap the distro-specific swaylock package.
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
  hm = {
    home.packages = [
      os-lock
      swaylock_
    ];
  };
  inherit os-lock swaylock_;
}
