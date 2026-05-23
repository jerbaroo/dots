{ pkgs, ... }:

let
  config = builtins.readFile ./config.kbd;
  cmd = "${pkgs.kanata}/bin/kanata -c ~/${pathInHome}";
  extraDefCfg = ''
    concurrent-tap-hold yes
    process-unmapped-keys yes
  '';
  pathInHome = ".config/kanata/config.kbd";
in
{
  inherit cmd;
  hm = {
    home.file.${pathInHome}.text = ''
      (defcfg
        ${extraDefCfg}
      )

      ${config}
    '';
  };
  nixos = {
    hardware.uinput.enable = true;
    services.udev.extraRules = ''
      KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
    '';
    services.kanata = {
      enable = true;
      keyboards.default = {
        config = builtins.readFile ./config.kbd;
        extraDefCfg = ''
          process-unmapped-keys yes
          concurrent-tap-hold yes
        '';
      };
    };
  };
}
