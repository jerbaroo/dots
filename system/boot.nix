{ pkgs, ... }:
{
  boot = {
    # Keep boot diagnostics in the journal rather than on the splash/console.
    consoleLogLevel = 0;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "udev.log_level=3"
      "rd.udev.log_level=3"
      "systemd.show_status=false"
      "rd.systemd.show_status=false"
      "vt.global_cursor_default=0"
    ];
    kernelPackages = pkgs.linuxPackages;
    loader = {
      efi.canTouchEfiVariables = true;
      grub.configurationLimit = 10;
      systemd-boot.configurationLimit = 10;
      systemd-boot.enable = true;
    };
    plymouth.enable = true;
    supportedFilesystems = [ "ntfs" ];
  };
}
