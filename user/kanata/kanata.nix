{ lib, pkgs, ... }:
let
  config = builtins.readFile ./config.kbd;
  extraDefCfg = ''
    concurrent-tap-hold yes
    process-unmapped-keys yes
  '';
  pathInHome = ".config/kanata/config.kbd";
in
{
  config.home.file.${pathInHome}.text = ''
    (defcfg
      ${extraDefCfg}
    )

    ${config}
  '';
  options.desktop.kanata.command = lib.mkOption {
    default = "${pkgs.kanata}/bin/kanata -c ~/${pathInHome}";
    description = "Command to run kanata";
    readOnly = true;
    type = lib.types.str;
  };
}
