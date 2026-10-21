{
  hyprlandPackages,
  ...
}:
{
  programs.hyprland = {
    enable = true;
    package = hyprlandPackages.hyprland;
  };
  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;
}
