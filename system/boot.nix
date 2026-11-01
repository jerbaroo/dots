{ pkgs, ... }:
{
  boot = {
    # Keep boot diagnostics in the journal rather than on the splash/console.
    consoleLogLevel = 0;
    kernelParams = [
      "quiet"
      "udev.log_level=3"
      "rd.udev.log_level=3"
      "systemd.show_status=false"
      "rd.systemd.show_status=false"
      "vt.global_cursor_default=0"
    ];
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      efi.canTouchEfiVariables = true;
      grub.configurationLimit = 5;
      systemd-boot.configurationLimit = 5;
      systemd-boot.enable = true;
    };
    plymouth = {
      enable = true;
      theme = "circle";
      themePackages = [
        (pkgs.adi1090x-plymouth-themes.override {
          selected_themes = [ "circle" ];
        })
      ];
    };
    supportedFilesystems = [ "ntfs" ];
  };
  catppuccin.plymouth.enable = false;
}
