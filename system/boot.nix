{pkgs}: {
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelPatches = [
      {
        name = "mediatek-bluetooth-handshake-fix";
        patch = pkgs.fetchurl {
          hash = "sha256-ij0hQmC0U++AdXWQy6nycnDe6z4yaMoQIrSiLal5DHc=";
          url = "https://git.kernel.org/pub/scm/linux/kernel/git/bluetooth/bluetooth-next.git/patch/?id=162b1adeb057d28ad84fd8a03f3c50cf08db5c62";
        };
      }
    ];
    loader = {
      efi.canTouchEfiVariables = true;
      grub.configurationLimit = 10;
      systemd-boot.enable = true;
    };
    plymouth.enable = true;
  };
}
