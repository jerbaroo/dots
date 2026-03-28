{
  accent,
  animationSpeed,
  animations,
  blur,
  borderSize,
  config,
  flavor,
  ghdashboardPort,
  gap,
  hostname,
  hyprland,
  ignis,
  ignisPath,
  lib,
  palette,
  pkgs,
  rounding,
  system,
  lockTimeout,
  temperature,
  username,
  wallpaperName,
  wrapGL,
  ...
}:
let
  audio = (import ./audio.nix { inherit pkgs; });
  bluetooth = (import ./bluetooth.nix { inherit pkgs; });
  defaultFloatSize = 0.8;
  floatCenter = "[float;center;${floatSize(defaultFloatSize)}]";
  floatSize = fraction: "size (monitor_w*${toString(fraction)}) (monitor_h*${toString(fraction)})";
  ghdashboard = import ./ghdashboard/default.nix { inherit pkgs; };
  ghdashboardwithargs = pkgs.writeShellScriptBin "ghdashboardwithargs" "${ghdashboard}/bin/ghdashboard ${toString(ghdashboardPort)} /home/${username}/.config/read-gh-token.sh";
  layout = "scrolling";
  layouts = [ "dwindle" "scrolling" ];
  lockAfterNotify = n: "fish -c 'notify_countdown -f ${lockingPath} -t ${toString(n)} -m \'Locking in {} seconds\''";
  lockingPath = "/tmp/hypr_locking";
  locks = import ./lock.nix { inherit ignisPath; inherit palette; inherit pkgs; };
  os-cli = import ./os-cli.nix { inherit ignis; inherit hostname; inherit hyprland; inherit pkgs; inherit system; inherit username; };
  monitorListener = pkgs.writeShellScript "hyprland-monitor-listener" ''
    ${pkgs.socat}/bin/socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do
      case "$line" in
        "monitoradded>>"*|"monitorremoved>>"*)
          echo "$line" >> /tmp/monitor-change
          ${setWallpaperCmd}
          ${os-cli.ui-reload}
          ;;
      esac
    done
  '';
  setWallpaperCmd = "swww img ${wallpaperPath}";
  wallpaperPath = (import ./wallpaper.nix { inherit pkgs; inherit wallpaperName; }).wallpaperPath;
  zoomFactor = 0.2;
in
assert lib.assertMsg (lib.elem layout layouts)
  "Invalid layout '${layout}'. Must be one of: ${lib.concatStringsSep ", " layouts}";
{
  home.packages = [
    ghdashboardwithargs
    locks.os-lock
    locks.swaylock
    os-cli.cli
  ];
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        # Screen off after sleeping.
        after_sleep_cmd = "hyprctl dispatch dpms on";
        # Lock before sleeping.
        before_sleep_cmd = "loginctl lock-session";
        # Lock if not already locked.
        lock_cmd = "pidof os-lock || os-lock ";
      };
      listener = [
        # Locking notification.
        {
          on-resume = "rm ${lockingPath}";
          on-timeout = "touch ${lockingPath}; " + lockAfterNotify(10);
          timeout = lockTimeout - 10;
        }
        # Lock.
        {
          on-timeout = "loginctl lock-session";
          timeout = lockTimeout;
        }
        # Screen off.
        {
          on-resume = "hyprctl dispatch dpms on";
          on-timeout = "hyprctl dispatch dpms off";
          timeout = lockTimeout + 60;
        }
        # Sleep.
        {
          on-timeout = "systemctl suspend";
          timeout = lockTimeout + 120;
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
        animation =
          let f = speed: toString (speed / animationSpeed);
          in [
             "windowsIn, 1, ${f 3.0}, emphasizedDecel, popin 80%"
             "fadeIn, 1, ${f 3.0}, emphasizedDecel"
             "windowsOut, 1, ${f 2.0}, emphasizedDecel, popin 90%"
             "fadeOut, 1, ${f 2.0}, emphasizedDecel"
             "windowsMove, 1, ${f 3.0}, emphasizedDecel, slide"
             "border, 1, ${f 10.0}, emphasizedDecel"
             "layersIn, 1, ${f 2.7}, emphasizedDecel, popin 93%"
             "layersOut, 1, ${f 2.4}, menu_accel, popin 94%"
             "fadeLayersIn, 1, ${f 0.5}, menu_decel"
             "fadeLayersOut, 1, ${f 2.7}, stall"
             "workspaces, 1, ${f 7.0}, menu_decel, slide"
             "specialWorkspaceIn, 1, ${f 2.8}, emphasizedDecel, slidevert"
             "specialWorkspaceOut, 1, ${f 1.2}, emphasizedAccel, slidevert"
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
        enabled = animations;
      };
      bind = [
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
        "$mod, COMMA, layoutmsg, swapcol l"
        "$mod, PERIOD, layoutmsg, swapcol r"
        "$mod SHIFT, H, movewindow, l"
        "$mod SHIFT, J, movewindow, d"
        "$mod SHIFT, K, movewindow, u"
        "$mod SHIFT, L, movewindow, r"
        # Move workspace in direction.
        "$mod CTRL, H, movecurrentworkspacetomonitor, l"
        "$mod CTRL, J, movecurrentworkspacetomonitor, d"
        "$mod CTRL, K, movecurrentworkspacetomonitor, u"
        "$mod CTRL, L, movecurrentworkspacetomonitor, r"
        # Resize splits.
        "$mod ALT, l, resizeactive, 40 0"
        "$mod ALT, h, resizeactive, -40 0"
        "$mod ALT, k, resizeactive, 0 -40"
        "$mod ALT, j, resizeactive, 0 40"
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
        "$mod      , BACKSPACE, exec, ${os-cli.ui-logout-menu-toggle}"
        "$mod      , DELETE, exec, systemctl suspend"
        "$mod      , RETURN, exec, ghostty"
        "$mod      , SLASH, exec, ${os-cli.ui-app-launcher-toggle}"
        "$mod      , SPACE, ${
          { dwindle = "togglesplit";
            scrolling = "layoutmsg, fit visible";
          }.${layout} or (throw "Unsupported layout: ${layout}")
        }"
        "$mod SHIFT, SPACE, togglefloating"
        "$mod      , TAB, cyclenext"
        "$mod SHIFT, TAB, workspace, previous"
        "$mod      , B, exec, ${floatCenter} ${bluetooth.guiCmd}"
        "$mod SHIFT, B, exec, ${os-cli.ui-menu-bar-toggle}"
        "$mod      , D, exec, ${pkgs.ghostty}/bin/ghostty --command=${pkgs.yazi}/bin/yazi"
        "$mod SHIFT, D, exec, ${pkgs.wdisplays}/bin/wdisplays"
        "$mod      , E, exec, ${pkgs.emacs-pgtk}/bin/emacs"
        "$mod      , F, fullscreen"
        "$mod SHIFT, F, fullscreenstate, 1"
        "$mod      , M, exec, spotify"
        "$mod      , N, exec, ${pkgs.swaynotificationcenter}/bin/swaync-client -t"
        "$mod      , R, exec, ${pkgs.hyprpicker}/bin/hyprpicker --autocopy"
        "$mod SHIFT, R, exec, ${pkgs.hyprpicker}/bin/hyprpicker --autocopy --render-inactive"
        "$mod      , P, focuscurrentorlast"
        "$mod SHIFT, P, layoutmsg, promote"
        "$mod      , Q, killactive"
        "$mod      , S, exec, ${os-cli.screenshot}"
        "$mod SHIFT, S, exec, ghostty -e ${os-cli.home-switch}"
        "$mod      , T, exec, ${floatCenter} ghostty -e ${pkgs.btop}/bin/btop"
        "$mod      , V, exec, ${floatCenter} ${audio.guiCmd}"
        "$mod      , W, exec, chromium"
        "$mod SHIFT, W, exec, ${pkgs.librewolf}/bin/librewolf"
        # Zoom.
        "$mod ALT, U, exec, hyprctl keyword cursor:zoom_factor $(hyprctl -j getoption cursor:zoom_factor |  ${pkgs.jq}/bin/jq '[.float - ${toString zoomFactor}, 1.0] | max')"
        "$mod ALT, I, exec, hyprctl keyword cursor:zoom_factor $(hyprctl -j getoption cursor:zoom_factor | ${pkgs.jq}/bin/jq '.float + ${toString zoomFactor}')"
        "$mod ALT, O, exec, hyprctl keyword cursor:zoom_factor 1"
      ];
      bindl = [ ", switch:on:Lid Switch, exec, systemctl suspend" ];
      debug.disable_logs = false;
      decoration = {
        active_opacity = 1;
        blur = {
          enabled = blur;
          noise = 0.02;
          passes = 4;
          size = 5;
        };
        inactive_opacity = 1;
        rounding = rounding;
      };
      dwindle.preserve_split = true;
      exec-once = [
        # "openrgb -m static -c ff1e00"
        setWallpaperCmd
        "ignis init >> /tmp/ignis.log 2>&1"
        "${monitorListener}"
        "${ghdashboardwithargs}/bin/ghdashboardwithargs"
        "1password --silent"
      ];
      general = {
        border_size = borderSize;
        "col.active_border" = "rgb(${pkgs.lib.strings.removePrefix "#" palette.${accent}.hex})";
        "col.inactive_border" = "rgb(${pkgs.lib.strings.removePrefix "#" palette.base.hex})";
        gaps_in = gap;
        gaps_out = gap * 2;
        layout = layout;
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
      scrolling = {
        column_width = 0.3333;
        fullscreen_on_one_column = true;
        direction = "right";
        focus_fit_method = 1; # Center active column.
      };
      windowrule =
        let floatCenterRule = title: [
            "float true, match:title ^(${title})$"
            "center true, match:title ^(${title})$"
            "${floatSize(defaultFloatSize)}, match:title ^(${title})$"
          ];
        in
          floatCenterRule audio.guiTitle
          ++ floatCenterRule bluetooth.guiTitle
          ++ floatCenterRule "wdisplays";
      workspace = ["1, monitor:DP-1, default:true" ];
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
