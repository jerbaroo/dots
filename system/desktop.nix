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
  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;
}
