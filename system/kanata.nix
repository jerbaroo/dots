{
  hardware.uinput.enable = true;
  services.udev.extraRules = ''
    KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
  '';
  services.kanata = {
    enable = true;
    keyboards.default = {
      config = builtins.readFile ../user/kanata/config.kbd;
      extraDefCfg = ''
        process-unmapped-keys yes
        concurrent-tap-hold yes
      '';
    };
  };
}
