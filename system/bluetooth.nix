{ lib, ... }:
{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
}
