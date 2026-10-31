{
  config,
  hyprlandPackages,
  username,
  ...
}:
let
  accent = palette.${desktop.theme.accent}.hex;
  cursor = config.home-manager.users.${username}.home.pointerCursor;
  desktop = config.home-manager.users.${username}.desktop;
  font = desktop.font.system;
  palette = desktop.theme.palette;
  wallpaper = ../user/wallpapers + "/${desktop.wallpaperName}";
in
{
  fonts.packages = [ font.package ];
  programs.hyprland = {
    enable = true;
    package = hyprlandPackages.hyprland;
  };
  services.desktopManager.gnome.enable = true;
  # Clear old boot text before login so the compositor handoff exposes a clean VT.
  systemd.services.greetd.serviceConfig = {
    TTYPath = "/dev/tty1";
    TTYReset = true;
    TTYVTDisallocate = true;
    StandardOutput = "journal";
    StandardError = "journal";
  };
  services.displayManager.noctalia-greeter = {
    cursorTheme = {
      inherit (cursor) name package;
    };
    enable = true;
    settings = {
      appearance = {
        corner_radius_scale = desktop.hyprland.rounding / 12.0;
        font_family = font.name;
        hide_logo = true;
        palette = {
          error = palette.red.hex;
          hover = palette.surface1.hex;
          on_error = palette.base.hex;
          on_hover = palette.text.hex;
          on_primary = palette.text.hex;
          on_secondary = palette.base.hex;
          on_surface = palette.text.hex;
          on_surface_variant = palette.subtext0.hex;
          on_tertiary = palette.base.hex;
          outline = accent;
          primary = palette.crust.hex;
          secondary = accent;
          shadow = palette.crust.hex;
          surface = palette.crust.hex;
          surface_variant = palette.crust.hex;
          tertiary = palette.teal.hex;
        };
        password_style = "default";
        power_buttons_position = "top-right";
        scheme = "Synced";
        scheme_selector_position = "hidden";
        wallpaper = {
          fill_mode = "crop";
          # Interpolation copies the selected image into the store for access before login.
          path = "${wallpaper}";
        };
      };
      cursor.size = cursor.size;
      # Avoid automatic fractional scaling on the native 5120x2160 display.
      output.scales = "DP-1:1";
      session.default = "Hyprland";
      user.default = username;
    };
  };
}
