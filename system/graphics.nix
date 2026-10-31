{
  # Enable native-resolution graphics during boot.
  hardware.amdgpu.initrd.enable = true;
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  # Monitor brightness control over DDC (ddcutil, used by the menu bar).
  hardware.i2c.enable = true;
}
