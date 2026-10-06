{
  accent,
  flavor,
  ...
}:
{
  catppuccin = {
    accent = accent;
    autoEnable = true;
    enable = true;
    flavor = flavor;
  };
  programs.dconf.enable = true;
  programs.hyprland.enable = true;
}
