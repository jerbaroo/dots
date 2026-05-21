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
  bitDepth = 10;
  bitDepthStr = ", bitdepth, ${toString (bitDepth)}";
  bluetooth = (import ./bluetooth.nix { inherit pkgs; });
  defaultFloatSize = 0.8;
  floatCenter = "[float;center;${floatSize (defaultFloatSize)}]";
  floatSize = fraction: "size (monitor_w*${toString (fraction)}) (monitor_h*${toString (fraction)})";
  ghdashboard = import ./ghdashboard/default.nix { inherit pkgs; };
  ghdashboardwithargs = pkgs.writeShellScriptBin "ghdashboardwithargs" "${ghdashboard}/bin/ghdashboard ${toString (ghdashboardPort)} /home/${username}/.config/read-gh-token.sh";
  hdr = true;
  # hdrStr = if hdr then ", cm, hdr" else "";
  hdrStr = if hdr then "" else "";
  kanataRun = (import ./kanata/kanata.nix { inherit pkgs; }).run;
  layout = "scrolling";
  layouts = [
    "dwindle"
    "scrolling"
  ];
  lockAfterNotify =
    n: "fish -c 'notify_countdown -f ${lockingPath} -t ${toString (n)} -m \'Locking in {} seconds\''";
  lockingPath = "/tmp/hypr_locking";
  locks = import ./lock.nix {
    inherit ignisPath;
    inherit palette;
    inherit pkgs;
  };
  os-cli = import ./os-cli.nix {
    inherit ignis;
    inherit hostname;
    inherit hyprland;
    inherit pkgs;
    inherit system;
    inherit username;
  };
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
  setWallpaperCmd = "awww img ${wallpaperPath}"; # TODO factor out
  wallpaperPath =
    (import ./wallpaper.nix {
      inherit pkgs;
      inherit wallpaperName;
    }).wallpaperPath;
  zoomFactor = 0.2;
in
# TODO enum.
assert lib.assertMsg (lib.elem layout layouts)
  "Invalid layout '${layout}'. Must be one of: ${lib.concatStringsSep ", " layouts}";
{
  catppuccin.hyprland.enable = false; # TODO
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
        # TODO ${pkgs.playerctl}/bin/playerctl pause
        lock_cmd = "pidof os-lock || os-lock "; # TODO
      };
      listener = [
        # Locking notification.
        {
          on-resume = "rm ${lockingPath}";
          on-timeout = "touch ${lockingPath}; " + lockAfterNotify (10);
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
          timeout = lockTimeout + (60 * 5);
        }
      ];
    };
  };
  services.hyprsunset = {
    enable = false;
    extraArgs = [ "-t" "${toString (temperature)}" ];
  };
  wayland.windowManager.hyprland = {
    configType = "lua";
    enable = true;
    # TODO locked submap.
    # extraConfig = ''
    #   submap = locked
    #   bind = , code:255, exec, true
    #   submap = reset
    # '';
    package = ((if wrapGL then config.lib.nixGL.wrap else (x: x)) hyprland.packages.${system}.hyprland);
    settings =
      let
        # Parameters to Lua function "hl.bind".
        bind = keys: action:
          { _args = [ keys (lib.generators.mkLuaInline action) ]; };
        execCmd = cmd: "hl.dsp.exec_cmd(\"${cmd}\")";
        hyprctlDispatch = disp: arg: execCmd("HI");
      in
      {
        config = {
          animations = {
            enabled = animations;
            # TODO lua.
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
            # TODO lua.
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
          };
          decoration = {
            active_opacity = 1;
            inactive_opacity = 1;
            rounding = rounding;
            blur = {
              enabled = blur;
              noise = 0.02;
              passes = 4;
              size = 5;
            };
          };
          dwindle.preserve_split = true;
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
          misc = {
            disable_hyprland_logo = true;
            vrr = 1;
          };
          render.cm_auto_hdr = 1;
          scrolling = {
            column_width = 0.333333;
            direction = "right";
            focus_fit_method = 1;
            fullscreen_on_one_column = false;
          };
          xwayland.force_zero_scaling = true;
          debug.disable_logs = false;
        };
        # Environment variables
        # env = [
        #   "GDK_BACKEND, wayland"
        #   "XDG_CURRENT_DESKTOP, hyprland"
        # ];
        # Standard monitors array
        # monitor = [
        #   "HDMI-A-1, 5120x2160@30, auto-up, 1.6${bitDepthStr}${hdrStr}"
        #   ", preferred, auto-up, 1.6"
        # ];
        # Hyprland hooks.
        on =
          let execOnStart = cmd:
                { _args = [ "hyprland.start" (lib.generators.mkLuaInline ("function()" + execCmd cmd + "end")) ]; };
          in map execOnStart
            [
              kanataRun
              setWallpaperCmd
              "ignis init >> /tmp/ignis.log 2>&1"
              "${monitorListener}"
              "${ghdashboardwithargs}/bin/ghdashboardwithargs"
              "1password --silent"
            ];
        bind =
          let hl = action: arg: "hl.${action}(${arg})";
              dispatch = action: arg: hl "dsp.${action}" arg;
              dispatchFocusMoveInDirection = direction: dispatch "focus" "{ direction = \"${direction}\" }";
              dispatchFocusMoveToWorkspace = workspace: "hl.dsp.focus({ workspace = \"${workspace}\" })";
              dispatchLayoutSwapCol = direction : "hl.dsp.layout(\"swapcol ${direction}\")";
              dispatchWindowMoveInDirection = direction: "hl.dsp.window.move({ direction = \"${direction}\" })";
              dispatchWindowMoveToWorkspace = workspace: "hl.dsp.window.move({ workspace = \"${workspace}\" })";
              dispatchWorkspaceMoveInDirection = direction: "hl.dsp.workspace.move({ monitor = \"${direction}\" })";
              mod = "SUPER";
          in [
          # Function keys
          (bind "XF86MonBrightnessDown" (execCmd "${pkgs.brightnessctl}/bin/brightnessctl s 10%-"))
          (bind "XF86MonBrightnessUp"   (execCmd "${pkgs.brightnessctl}/bin/brightnessctl s +10%"))
          (bind "XF86AudioMute"         (execCmd "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_SINK@ toggle"))
          (bind "XF86AudioLowerVolume"  (execCmd "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_SINK@ 5%-"))
          (bind "XF86AudioRaiseVolume"  (execCmd "${pkgs.wireplumber}/bin/wpctl set-volume -l 1.0 @DEFAULT_SINK@ 5%+"))

          # Alphabet keys.
          (bind "${mod} + B" (execCmd "${floatCenter} ${bluetooth.guiCmd}"))
          (bind "${mod} + SHIFT + B" (execCmd os-cli.ui-menu-bar-toggle))
          (bind "${mod} + D" (execCmd "${pkgs.ghostty}/bin/ghostty --command=${pkgs.yazi}/bin/yazi"))
          (bind "${mod} + SHIFT + D" (execCmd "${pkgs.wdisplays}/bin/wdisplays"))
          (bind "${mod} + E" (execCmd "${pkgs.emacs-pgtk}/bin/emacs"))
          (bind "${mod} + F" (dispatch "window.fullscreen" "{ mode = \"fullscreen\" }"))
          # https://wiki.hypr.land/Configuring/Basics/Dispatchers/#fullscreenstate
          (bind "${mod} + SHIFT + F" (dispatch "window.fullscreen_state" "{ client = 2, internal = 0 }"))
          (bind "${mod} + M" (execCmd "spotify"))
          (bind "${mod} + N" (execCmd "${pkgs.swaynotificationcenter}/bin/swaync-client -t"))
          (bind "${mod} + R" (execCmd "${pkgs.hyprpicker}/bin/hyprpicker --autocopy"))
          (bind "${mod} + SHIFT + R" (execCmd "${pkgs.hyprpicker}/bin/hyprpicker --autocopy --render-inactive"))
          (bind "${mod} + P" (dispatch "layout" "promote"))
          (bind "${mod} + Q" (dispatch "window.kill" ""))
          (bind "${mod} + S" (execCmd os-cli.screenshot))
          (bind "${mod} + SHIFT + S" (execCmd "ghostty -e ${os-cli.home-switch}"))
          (bind "${mod} + T" (execCmd "${floatCenter} ghostty -e ${pkgs.btop}/bin/btop"))
          (bind "${mod} + V" (execCmd "${floatCenter} ${audio.guiCmd}"))
          (bind "${mod} + W" (execCmd "chromium")) # TODO pass this in.
          (bind "${mod} + SHIFT + W" (execCmd "${pkgs.librewolf}/bin/librewolf"))

          # Other keys
          (bind "${mod} + BACKSPACE" (execCmd os-cli.ui-logout-menu-toggle))
          (bind "${mod} + DELETE" (execCmd "systemctl suspend"))
          (bind "${mod} + RETURN" (execCmd "ghostty"))
          (bind "${mod} + SHIFT + RETURN" (execCmd "konsole")) # Backup terminal.
          (bind "${mod} + SLASH" (execCmd os-cli.ui-app-launcher-toggle))
          (bind "${mod} + SPACE"
            ( execCmd
              ( if layout == "dwindle" then
                  "hyprctl dispatch togglesplit"
                else if layout == "scrolling" then
                  "hyprctl dispatch layoutmsg fit visible"
                else throw "Unsupported layout: ${layout}" # TODO Enum.
              )
            )
          )
          (bind "${mod} + SHIFT + SPACE" (dispatch "window.float" ""))
          (bind "${mod} + TAB" (dispatch "window.cycle_next" ""))
          (bind "${mod} + SHIFT + TAB" (dispatch "group.prev" ""))

          ##### Focus #####

          # Move focus in direction.
          (bind "${mod} + H" (dispatchFocusMoveInDirection "l"))
          (bind "${mod} + J" (dispatchFocusMoveInDirection "d"))
          (bind "${mod} + K" (dispatchFocusMoveInDirection "u"))
          (bind "${mod} + L" (dispatchFocusMoveInDirection "r"))

          # Move focus to workspace.
          (bind "${mod} + 0" (dispatchFocusMoveToWorkspace "0"))
          (bind "${mod} + 1" (dispatchFocusMoveToWorkspace "1"))
          (bind "${mod} + 2" (dispatchFocusMoveToWorkspace "2"))
          (bind "${mod} + 3" (dispatchFocusMoveToWorkspace "3"))
          (bind "${mod} + 4" (dispatchFocusMoveToWorkspace "4"))
          (bind "${mod} + 5" (dispatchFocusMoveToWorkspace "5"))
          (bind "${mod} + 6" (dispatchFocusMoveToWorkspace "6"))
          (bind "${mod} + 7" (dispatchFocusMoveToWorkspace "7"))
          (bind "${mod} + 8" (dispatchFocusMoveToWorkspace "8"))
          (bind "${mod} + 9" (dispatchFocusMoveToWorkspace "9"))

          ##### Windows #####

          # Move window in direction.
          (bind "${mod} + SHIFT + H" (dispatchWindowMoveInDirection "l"))
          (bind "${mod} + SHIFT + J" (dispatchWindowMoveInDirection "d"))
          (bind "${mod} + SHIFT + K" (dispatchWindowMoveInDirection "u"))
          (bind "${mod} + SHIFT + L" (dispatchWindowMoveInDirection "r"))

          # Move window to workspace.
          (bind "${mod} + SHIFT + 0" (dispatchWindowMoveToWorkspace "0"))
          (bind "${mod} + SHIFT + 1" (dispatchWindowMoveToWorkspace "1"))
          (bind "${mod} + SHIFT + 2" (dispatchWindowMoveToWorkspace "2"))
          (bind "${mod} + SHIFT + 3" (dispatchWindowMoveToWorkspace "3"))
          (bind "${mod} + SHIFT + 4" (dispatchWindowMoveToWorkspace "4"))
          (bind "${mod} + SHIFT + 5" (dispatchWindowMoveToWorkspace "5"))
          (bind "${mod} + SHIFT + 6" (dispatchWindowMoveToWorkspace "6"))
          (bind "${mod} + SHIFT + 7" (dispatchWindowMoveToWorkspace "7"))
          (bind "${mod} + SHIFT + 8" (dispatchWindowMoveToWorkspace "8"))
          (bind "${mod} + SHIFT + 9" (dispatchWindowMoveToWorkspace "9"))

          # Move column horizontally in scrolling mode.
          (bind "${mod} + COMMA"  (dispatchLayoutSwapCol "l"))
          (bind "${mod} + PERIOD" (dispatchLayoutSwapCol "r"))

          ##### Workspaces #####

          # Move workspace in direction.
          (bind "${mod} + CTRL + H" (dispatchWorkspaceMoveInDirection "l"))
          (bind "${mod} + CTRL + J" (dispatchWorkspaceMoveInDirection "d"))
          (bind "${mod} + CTRL + K" (dispatchWorkspaceMoveInDirection "u"))
          (bind "${mod} + CTRL + L" (dispatchWorkspaceMoveInDirection "r"))

          ##### Resizing and zooming #####

          # Resize splits.
          # (bind "${mod} + ALT + L" (dispatch "window.resize" "40 0"))
          # (bind "${mod} + ALT + H" (dispatch "window.resize" "-40 0"))
          # (bind "${mod} + ALT + K" (dispatch "window.resize" "0 -40"))
          # (bind "${mod} + ALT + J" (dispatch "window.resize" "0 40"))

          # Resize column width
          (bind "${mod} + ALT + 1" (hyprctlDispatch "layoutmsg" "colresize 1"))
          (bind "${mod} + ALT + 2" (hyprctlDispatch "layoutmsg" "colresize 0.5"))
          (bind "${mod} + ALT + 3" (hyprctlDispatch "layoutmsg" "colresize 0.333333"))
          (bind "${mod} + ALT + 4" (hyprctlDispatch "layoutmsg" "colresize 0.25"))
          (bind "${mod} + ALT + 5" (hyprctlDispatch "layoutmsg" "colresize 0.2"))
          (bind "${mod} + ALT + 6" (hyprctlDispatch "layoutmsg" "colresize 0.666666"))
          (bind "${mod} + ALT + 9" (hyprctlDispatch "layoutmsg" "colresize -conf"))
          (bind "${mod} + ALT + 0" (hyprctlDispatch "layoutmsg" "colresize +conf"))

          # Zoom
          (bind "${mod} + SHIFT + U" (execCmd "hyprctl keyword cursor:zoom_factor $(hyprctl -j getoption cursor:zoom_factor | ${pkgs.jq}/bin/jq '[.float - ${toString zoomFactor}, 1.0] | max')"))
          (bind "${mod} + SHIFT + I" (execCmd "hyprctl keyword cursor:zoom_factor $(hyprctl -j getoption cursor:zoom_factor | ${pkgs.jq}/bin/jq '.float + ${toString zoomFactor}')"))
          (bind "${mod} + SHIFT + O" (execCmd "hyprctl keyword cursor:zoom_factor 1"))

          # Suspend system on laptop-lid close
          {
            _args = [
              "switch:on:Lid Switch"
              (lib.generators.mkLuaInline (execCmd "systemctl suspend"))
              { locked = true; } # Suspend system even if locked.
            ];
          }
        ];
        # Blur the menu bar.
        layer_rule = [
          {
            match.namespace = "^(ignis-bar-.*)$"; # TODO factor out name.
            blur = true;
          }
        ];
        # Workspace rule maps
        # workspace_rule = [
        #   { match.workspace = "1"; monitor = "HDMI-A-1"; default = true; }
        # ];
        window_rule =
          let
            floatRule = title:
                {
                  center = true;
                  float = true;
                  match.title = "^(${title})$";
                  size = "(monitor_w*${toString defaultFloatSize}) (monitor_h*${toString defaultFloatSize})";
                };
            noBorderIfSoleTile = {
                match = {
                  float = false;
                  workspace = "f[1]";
                };
                border_size = 0;
              };
          in
            map floatRule [audio.guiTitle bluetooth.guiTitle "wdisplays"]
            ++ [ noBorderIfSoleTile ];
      };
    systemd = {
      enable = true;
      enableXdgAutostart = false;
    };
    xwayland.enable = true;
  };
  xdg.portal.enable = true;
}
