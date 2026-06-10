{ pkgs, ... }:
{
  boot = {
    kernelPackages = pkgs.linuxPackages;
    loader = {
      efi.canTouchEfiVariables = true;
      grub.configurationLimit = 10;
      systemd-boot.enable = true;
    };
    plymouth.enable = true;
    supportedFilesystems = [ "ntfs" ];
  };
}
