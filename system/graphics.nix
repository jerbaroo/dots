{
  hyprland,
  system,
  ...
}:
{
  programs.hyprland = {
    enable = true;
    package = hyprland.packages.${system}.hyprland;
  };
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;
}
