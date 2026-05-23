{ lib, ... }:
{
  hardware.bluetooth = {
    enable = true;
    # settings = {
    #   General = {
    #     Experimental = true;
    #   };
    # };
  };
  hardware.bluetooth.powerOnBoot = true;
  # hardware.enableAllFirmware = true;
  # services.blueman.enable = true;
}
