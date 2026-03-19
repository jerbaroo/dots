{
  accent,
  borderSize,
  config,
  flavor,
  ghdashboardPort,
  gap,
  hyprland,
  ignisPath,
  palette,
  pkgs,
  system,
  temperature,
  username,
  wallpaperName,
  wrapGL,
  ...
}:
let
  defaultFloatSize = 0.8;
  floatSize = fraction: "size (monitor_w*${toString(fraction)}) (monitor_h*${toString(fraction)})";
  ghdashboard = import ./ghdashboard/default.nix { inherit pkgs; };
  ghdashboardwithargs = pkgs.writeShellScriptBin "ghdashboardwithargs" "${ghdashboard}/bin/ghdashboard ${toString(ghdashboardPort)} /home/${username}/.config/read-gh-token.sh";
  lockAfterNotify = n: "notify_countdown -s -t ${toString(n)} -m 'Locking in {} seconds'";
  lockAfterSeconds = 60;
  locks = import ./lock.nix { inherit ignisPath; inherit palette; inherit pkgs; };
  os-current-monitor = pkgs.writeShellScriptBin "os-current-monitor" "hyprctl monitors | awk -F '[ ()]+' '/Monitor/ {id=$4} /focused: yes/ {print id; exit}'";
  os-screenshot = pkgs.writeShellScriptBin "os-screenshot" "${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp)\" - | ${pkgs.swappy}/bin/swappy -f -";
  os-toggle-menu-bar = pkgs.writeShellScriptBin "os-toggle-menu-bar" "ignis toggle-window ignis-bar-$(${os-current-monitor}/bin/os-current-monitor)";
  wallpaperPath = (import ./wallpaper.nix { inherit pkgs; inherit wallpaperName; }).wallpaperPath;
  zoomFactor = 0.2;
in
{
  home.packages = [ ghdashboardwithargs locks.os-lock locks.swaylock os-current-monitor os-toggle-menu-bar ];
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        after_sleep_cmd = "hyprctl dispatch dpms on";
        before_sleep_cmd = "loginctl lock-session";
        lock_cmd = "pidof os-lock || os-lock ";
      };
      listener = [
        {
          on-timeout = lockAfterNotify(5);
          timeout = lockAfterSeconds - 5;
        }
        {
          on-timeout = "loginctl lock-session";
          timeout = lockAfterSeconds;
        }
        {
          on-resume = "hyprctl dispatch dpms on";
          on-timeout = "hyprctl dispatch dpms off";
          timeout = lockAfterSeconds + 60;
        }
        {
          on-timeout = "systemctl suspend";
          timeout = lockAfterSeconds + 120;
        }
      ];
    };
  };
  services.hyprsunset = {
    enable = true;
    extraArgs = ["-t" "${toString(temperature)}"];
  };
  wayland.windowManager.hyprland = {
    enable = true;
    extraConfig = ''
      submap = locked
      bind = , code:255, exec, true
      submap = reset
    '';
    package = ((if wrapGL then config.lib.nixGL.wrap else (x: x)) hyprland.packages.${system}.hyprland);
    settings = {
      # "env" = "GTK_THEME, catppuccin-${flavor}-${accent}-standard";
      env = "GDK_BACKEND, wayland";
      "$mod" = "SUPER";
      # https://github.com/end-4/dots-hyprland/blob/main/dots/.config/hypr/hyprland/general.conf
      animations = {
        animation = [
          "windowsIn, 1, 3, emphasizedDecel, popin 80%"
          "fadeIn, 1, 3, emphasizedDecel"
          "windowsOut, 1, 2, emphasizedDecel, popin 90%"
          "fadeOut, 1, 2, emphasizedDecel"
          "windowsMove, 1, 3, emphasizedDecel, slide"
          "border, 1, 10, emphasizedDecel"
          "layersIn, 1, 2.7, emphasizedDecel, popin 93%"
          "layersOut, 1, 2.4, menu_accel, popin 94%"
          "fadeLayersIn, 1, 0.5, menu_decel"
          "fadeLayersOut, 1, 2.7, stall"
          "workspaces, 1, 7, menu_decel, slide"
          "specialWorkspaceIn, 1, 2.8, emphasizedDecel, slidevert"
          "specialWorkspaceOut, 1, 1.2, emphasizedAccel, slidevert"
        ];
        bezier = [
          "expressiveFastSpatial, 0.42, 1.67, 0.21, 0.90"
          "expressiveSlowSpatial, 0.39, 1.29, 0.35, 0.98"
          "expressiveDefaultSpatial, 0.38, 1.21, 0.22, 1.00"
          "emphasizedDecel, 0.05, 0.7, 0.1, 1"
          "emphasizedAccel, 0.3, 0, 0.8, 0.15"
          "standardDecel, 0, 0, 0, 1"
          "menu_decel, 0.1, 1, 0, 1"
          "menu_accel, 0.52, 0.03, 0.72, 0.08"
          "stall, 1, -0.1, 0.7, 0.85"
        ];
        enabled = true;
      };
      bind = [
        ",Delete, exec, os-lock & disown && sleep 1 && systemctl suspend"
        # Function keys.
        ",XF86MonBrightnessDown, exec, ${pkgs.brightnessctl}/bin/brightnessctl s 10%-"
        ",XF86MonBrightnessUp  , exec, ${pkgs.brightnessctl}/bin/brightnessctl s +10%"
        ",XF86AudioMute        , exec, ${pkgs.wireplumber}/bin/wpctl set-mute   @DEFAULT_SINK@ toggle"
        ",XF86AudioLowerVolume , exec, ${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_SINK@ 5%-"
        ",XF86AudioRaiseVolume , exec, ${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_SINK@ 5%+"
        # Move focus in direction.
        "$mod, H, movefocus, l"
        "$mod, J, movefocus, d"
        "$mod, K, movefocus, u"
        "$mod, L, movefocus, r"
        # Swap windows in direction.
        "$mod SHIFT, H, movewindow, l"
        "$mod SHIFT, J, movewindow, d"
        "$mod SHIFT, K, movewindow, u"
        "$mod SHIFT, L, movewindow, r"
        # Move focus to workspace by ID.
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 0"
        # Move window to workspace by ID.
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
        "$mod SHIFT, 0, movetoworkspace, 0"
        # Primary keys.
        "$mod      , RETURN, exec, ghostty"
        "$mod      , SLASH, exec, ignis open-window ignis-app-launcher"
        "$mod      , SPACE, togglesplit, # dwindle"
        "$mod SHIFT, SPACE, togglefloating"
        "$mod      , TAB, workspace, m+1"
        "$mod      , B, exec, ${pkgs.blueman}/bin/blueman-manager"
        "$mod SHIFT, B, exec, ${os-toggle-menu-bar}/bin/os-toggle-menu-bar"
        "$mod      , C, exec, ${pkgs.cliphist}/bin/cliphist list | ${pkgs.rofi}/bin/rofi -dmenu | ${pkgs.cliphist}/bin/cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy"
        "$mod      , D, exec, ${pkgs.wdisplays}/bin/wdisplays"
        "$mod      , E, exec, ${pkgs.emacs-pgtk}/bin/emacs"
        "$mod      , F, fullscreenstate, 1"
        "$mod SHIFT, F, fullscreen"
        "$mod      , M, exec, spotify"
        "$mod      , N, exec, ${pkgs.swaynotificationcenter}/bin/swaync-client -t"
        "$mod      , O, exec, ${pkgs.ghostty}/bin/ghostty --command=${pkgs.yazi}/bin/yazi"
        "$mod      , R, exec, ${pkgs.hyprpicker}/bin/hyprpicker --autocopy"
        "$mod SHIFT, R, exec, ${pkgs.hyprpicker}/bin/hyprpicker --autocopy --render-inactive"
        "$mod      , P, workspace, previous"
        "$mod      , Q, killactive"
        "$mod SHIFT, Q, exec, os-logout-menu"
        "$mod      , S, exec, ${os-screenshot}/bin/os-screenshot"
        "$mod      , T, exec, [float;center;${floatSize(defaultFloatSize)}] ghostty -e ${pkgs.btop}/bin/btop"
        "$mod      , U, exec, [float;center;${floatSize(0.5)}] ghostty -e os-switch-home"
        "$mod      , V, exec, ${pkgs.pavucontrol}/bin/pavucontrol"
        "$mod      , W, exec, firefox"
        "$mod SHIFT, W, exec, ${pkgs.librewolf}/bin/librewolf"
        # Zoom.
        "$mod CTRL, J, exec, hyprctl keyword cursor:zoom_factor $(hyprctl -j getoption cursor:zoom_factor |  ${pkgs.jq}/bin/jq '[.float - ${toString zoomFactor}, 1.0] | max')"
        "$mod CTRL, K, exec, hyprctl keyword cursor:zoom_factor $(hyprctl -j getoption cursor:zoom_factor | ${pkgs.jq}/bin/jq '.float + ${toString zoomFactor}')"
        "$mod CTRL, H, exec, hyprctl keyword cursor:zoom_factor 1"
      ];
      bindl = [ ", switch:on:Lid Switch, exec, ${locks.swaylock}/bin/swaylock_ & disown && systemctl suspend" ];
      debug.disable_logs = false;
      decoration = {
        active_opacity = 1;
        blur = {
          enabled = true;
          noise = 0.02;
          passes = 4;
          size = 5;
        };
        inactive_opacity = 1;
        rounding = 8;
      };
      dwindle.preserve_split = true;
      exec-once = [
        # "openrgb -m static -c ff1e00"
        "1password --silent"
        "swww img ${wallpaperPath}"
        "${ghdashboardwithargs}/bin/ghdashboardwithargs"
        "${pkgs.blueman}/bin/blueman-applet"
        "nm-applet"
        "ignis init"
      ];
      general = {
        border_size = borderSize;
        "col.active_border" = "rgb(${pkgs.lib.strings.removePrefix "#" palette.${accent}.hex})";
        "col.inactive_border" = "rgb(${pkgs.lib.strings.removePrefix "#" palette.base.hex})";
        gaps_in = gap;
        gaps_out = gap * 2;
        resize_on_border = true;
      };
      input.kb_options = "caps:swapescape";
      layerrule = [
        # Blur the menu bar.
        "blur on, match:namespace ^(ignis-bar-.*)$"
        # Ignore the transparent gaps.
        # "ignore_alpha 0.1, match:namespace ^(ignis-bar-.*)$"
      ];
      monitor = [ ", preferred, auto-up, 1.5" ];
      misc.disable_hyprland_logo = true;
      windowrule = [
        "float true, match:class ^(org.pulseaudio.pavucontrol)$"
        "center true, match:class ^(org.pulseaudio.pavucontrol)$"
        "${floatSize(defaultFloatSize)}, match:class ^(org.pulseaudio.pavucontrol)$"
        "float true, match:class ^(.blueman-manager-wrapped)$"
        "center true, match:class ^(.blueman-manager-wrapped)$"
        "${floatSize(defaultFloatSize)}, match:class ^(.blueman-manager-wrapped)$"
        "float true, match:class ^(wdisplays)$"
        "center true, match:class ^(wdisplays)$"
        "${floatSize(defaultFloatSize)}, match:class ^(wdisplays)$"
      ];
      xwayland = {
        force_zero_scaling = true;
      };
    };
    systemd = {
      enable = true;
      enableXdgAutostart = false;
    };
    xwayland = {
      enable = true;
    };
  };
  xdg.portal.enable = true;
}
