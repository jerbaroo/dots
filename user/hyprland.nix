{
  config,
  lib,
  pkgs,
  system,
  ...
}:
let
  bitDepthStr = ", bitdepth, ${toString config.desktop.graphics.bitDepth}";
  floatCenter = _: "[float;center;${floatSize config.desktop.hyprland.float.size.default}]";
  floatSize = fraction: "size (monitor_w*${toString fraction}) (monitor_h*${toString fraction})";
  monitorListener = pkgs.writeShellScript "hyprland-monitor-listener" ''
    ${pkgs.socat}/bin/socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do
      case "$line" in
        "monitoradded>>"*|"monitorremoved>>"*)
          echo "$line" >> /tmp/monitor-change
          ${config.desktop.monitor.onChange}
          ;;
      esac
    done
  '';
  zoomFactor = 0.2;
in
{
  options.desktop.hyprland = {
    animationSpeed = lib.mkOption {
      type = lib.types.nullOr (lib.types.addCheck lib.types.float (x: x > 0));
    };
    border.size = lib.mkOption { type = lib.types.ints.unsigned; };
    blur = lib.mkOption { type = lib.types.bool; };
    float.size.default = lib.mkOption { type = lib.types.float; };
    gap = lib.mkOption { type = lib.types.ints.unsigned; };
    layout = lib.mkOption {
      type = lib.types.enum [
        "dwindle"
        "scrolling"
      ];
    };
    package = lib.mkOption {
      description = "Hyprland package (set to null if using distro-installed hyprland)";
      type = lib.types.nullOr lib.types.package;
    };
    rounding = lib.mkOption { type = lib.types.ints.unsigned; };
  };
  config = {
    catppuccin.hyprland.enable = false; # Broken since 0.55.
    wayland.windowManager.hyprland = {
      configType = "lua";
      enable = true;
      # TODO locked submap.
      # extraConfig = ''
      #   submap = locked
      #   bind = , code:255, exec, true
      #   submap = reset
      # '';
      # Workspace rule maps
      # workspace_rule = [ { match.workspace = "1"; monitor = "HDMI-A-1"; default = true; } ];
      package = config.desktop.hyprland.package;
      portalPackage =
        if config.desktop.hyprland.package == null then
          null
        else
          config.lib.nixGL.wrap pkgs.xdg-desktop-portal-hyprland;
      settings = {
        animation =
          let
            animation = leaf: speed: curve: style: {
              _args = [
                (lib.generators.mkLuaInline (
                  let
                    styleStr = if style == null then "" else ", style=\"${style}\"";
                    # If "animationSpeed" is null we don't apply a modifier to
                    # "speed".
                    speedStr = toString (
                      if config.desktop.hyprland.animationSpeed == null then
                        speed
                      else
                        speed / config.desktop.hyprland.animationSpeed
                    );
                  in
                  "{ leaf=\"${leaf}\", enabled=true, speed=${speedStr}, bezier=\"${curve}\" ${styleStr} }"
                ))
              ];
            };
          in
          if config.desktop.hyprland.animationSpeed == null then
            [ ]
          else
            [
              (animation "windowsIn" 3.0 "emphasizedDecel" "popin 80%")
              (animation "fadeIn" 3.0 "emphasizedDecel" null)
              (animation "windowsOut" 2.0 "emphasizedDecel" "popin 90%")
              (animation "fadeOut" 2.0 "emphasizedDecel" null)
              (animation "windowsMove" 3.0 "emphasizedDecel" "slide")
              (animation "border" 10.0 "emphasizedDecel" null)
              (animation "layersIn" 2.7 "emphasizedDecel" "popin 93%")
              (animation "layersOut" 2.4 "menu_accel" "popin 94%")
              (animation "fadeLayersIn" 0.5 "menu_decel" null)
              (animation "fadeLayersOut" 2.7 "stall" null)
              (animation "workspaces" 7.0 "menu_decel" "slide")
              (animation "specialWorkspaceIn" 2.8 "emphasizedDecel" "slidevert")
              (animation "specialWorkspaceOut" 1.2 "emphasizedAccel" "slidevert")
            ];
        curve =
          let
            bezier = name: x0: x1: y0: y1: {
              _args = [
                name
                (lib.generators.mkLuaInline "{ type=\"bezier\", points={ { ${x0}, ${x1} }, { ${y0}, ${y1} } } }")
              ];
            };
          in
          [
            (bezier "expressiveFastSpatial" "0.42" "1.67" "0.21" "0.90")
            (bezier "expressiveSlowSpatial" "0.39" "1.29" "0.35" "0.98")
            (bezier "expressiveDefaultSpatial" "0.38" "1.21" "0.22" "1.00")
            (bezier "emphasizedDecel" "0.05" "0.7" "0.1" "1")
            (bezier "emphasizedAccel" "0.3" "0" "0.8" "0.15")
            (bezier "standardDecel" "0" "0" "0" "1")
            (bezier "menu_decel" "0.1" "1" "0" "1")
            (bezier "menu_accel" "0.52" "0.03" "0.72" "0.08")
            (bezier "stall" "1" "-0.1" "0.7" "0.85")
          ];
        config = {
          cursor.no_hardware_cursors = true;
          debug.disable_logs = false;
          decoration = {
            active_opacity = 1;
            blur = {
              enabled = config.desktop.hyprland.blur;
              noise = 0.02;
              passes = 4;
              size = 5;
            };
            inactive_opacity = 1;
            rounding = config.desktop.hyprland.rounding;
          };
          dwindle.preserve_split = true;
          general = {
            border_size = config.desktop.hyprland.border.size;
            "col.active_border" = "rgb(${
              pkgs.lib.strings.removePrefix "#" config.desktop.theme.palette.${config.desktop.theme.accent}.hex
            })";
            "col.inactive_border" =
              "rgb(${pkgs.lib.strings.removePrefix "#" config.desktop.theme.palette.base.hex})";
            gaps_in = config.desktop.hyprland.gap;
            gaps_out = config.desktop.hyprland.gap * 2;
            layout = config.desktop.hyprland.layout;
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
        };
        env = map (tuple: { _args = tuple; }) [ ];
        # Hyprland hooks.
        on =
          let
            execOnStart = cmd: {
              _args = [
                "hyprland.start"
                (lib.generators.mkLuaInline ("function() hl.exec_cmd([[" + cmd + "]]) end"))
              ];
            };
          in
          map execOnStart (config.desktop.startup.allCommands ++ [ "${monitorListener}" ]);
        bind =
          let
            bind = keys: action: {
              _args = [
                keys
                (lib.generators.mkLuaInline action)
              ];
            };
            dispatch = action: arg: hl "dsp.${action}" arg;
            dispatchFocusMoveInDirection = direction: dispatch "focus" "{ direction = \"${direction}\" }";
            dispatchFocusMoveToWorkspace = workspace: dispatch "focus" "{ workspace = \"${workspace}\" }";
            dispatchLayoutSwapCol = direction: dispatch "layout" "\"swapcol ${direction}\"";
            dispatchWindowMoveInDirection =
              direction: dispatch "window.move" "{ direction = \"${direction}\" }";
            dispatchWindowMoveToWorkspace =
              workspace: dispatch "window.move" "{ workspace = \"${workspace}\" }";
            dispatchWorkspaceMoveInDirection =
              direction: dispatch "workspace.move" "{ monitor = \"${direction}\" }";
            execCmd = cmd: "hl.dsp.exec_cmd(\"${cmd}\")";
            hl = action: arg: "hl.${action}(${arg})";
            mod = "SUPER";
          in
          [
            # Function keys
            (bind "XF86MonBrightnessDown" (execCmd "${pkgs.brightnessctl}/bin/brightnessctl s 10%-"))
            (bind "XF86MonBrightnessUp" (execCmd "${pkgs.brightnessctl}/bin/brightnessctl s +10%"))
            (bind "XF86AudioMute" (execCmd "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_SINK@ toggle"))
            (bind "XF86AudioLowerVolume" (
              execCmd "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_SINK@ 5%-"
            ))
            (bind "XF86AudioRaiseVolume" (
              execCmd "${pkgs.wireplumber}/bin/wpctl set-volume -l 1.0 @DEFAULT_SINK@ 5%+"
            ))

            # Alphabet keys.
            (bind "${mod} + B" (execCmd "${floatCenter 0} ${config.desktop.bluetooth.guiCmd}"))
            (bind "${mod} + SHIFT + B" (execCmd config.desktop.cli.ui.menuBar.toggle))
            (bind "${mod} + D" (execCmd "kitty ${pkgs.yazi}/bin/yazi"))
            (bind "${mod} + SHIFT + D" (execCmd "${pkgs.wdisplays}/bin/wdisplays"))
            (bind "${mod} + E" (execCmd "${pkgs.emacs-pgtk}/bin/emacs"))
            (bind "${mod} + F" (dispatch "window.fullscreen" "{ mode = \"fullscreen\" }"))
            # https://wiki.hypr.land/Configuring/Basics/Dispatchers/#fullscreenstate
            (bind "${mod} + SHIFT + F" (dispatch "window.fullscreen_state" "{ client = 2, internal = 0 }"))
            (bind "${mod} + M" (execCmd "spotify"))
            (bind "${mod} + N" (execCmd "${pkgs.swaynotificationcenter}/bin/swaync-client -t"))
            (bind "${mod} + R" (execCmd "${pkgs.hyprpicker}/bin/hyprpicker --autocopy"))
            (bind "${mod} + SHIFT + R" (
              execCmd "${pkgs.hyprpicker}/bin/hyprpicker --autocopy --render-inactive"
            ))
            (bind "${mod} + P" (dispatch "layout" "\"promote\""))
            (bind "${mod} + Q" (dispatch "window.kill" ""))
            (bind "${mod} + SHIFT + Q" (execCmd "${pkgs.hyprshutdown}/bin/hyprshutdown"))
            (bind "${mod} + S" (execCmd config.desktop.cli.screenshot))
            (bind "${mod} + SHIFT + S" (execCmd "kitty ${config.desktop.cli.home.switch}"))
            (bind "${mod} + T" (execCmd "${floatCenter 0} kitty ${config.desktop.btop.package}/bin/btop"))
            (bind "${mod} + V" (execCmd "${floatCenter 0} ${config.desktop.audio.guiCmd}"))
            (bind "${mod} + W" (execCmd config.desktop.browser.cmd))
            (bind "${mod} + SHIFT + W" (execCmd "${pkgs.librewolf}/bin/librewolf"))

            # Other keys
            (bind "${mod} + BACKSPACE" (execCmd config.desktop.cli.ui.logoutMenu.toggle))
            (bind "${mod} + DELETE" (execCmd "systemctl suspend"))
            (bind "${mod} + RETURN" (execCmd "kitty"))
            (bind "${mod} + SHIFT + RETURN" (execCmd "konsole")) # Backup terminal.
            (bind "${mod} + SLASH" (execCmd config.desktop.cli.ui.appLauncher.toggle))
            (bind "${mod} + SPACE" (
              if config.desktop.hyprland.layout == "dwindle" then
                dispatch "togglesplit" ""
              else
                dispatch "layout" "\"fit visible\""
            ))
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
            (bind "${mod} + COMMA" (dispatchLayoutSwapCol "l"))
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
            (bind "${mod} + ALT + 1" (dispatch "layout" "\"colresize 1\""))
            (bind "${mod} + ALT + 2" (dispatch "layout" "\"colresize 0.5\""))
            (bind "${mod} + ALT + 3" (dispatch "layout" "\"colresize 0.333333\""))
            (bind "${mod} + ALT + 4" (dispatch "layout" "\"colresize 0.25\""))
            (bind "${mod} + ALT + 5" (dispatch "layout" "\"colresize 0.2\""))
            (bind "${mod} + ALT + 6" (dispatch "layout" "\"colresize 0.666666\""))
            (bind "${mod} + ALT + 9" (dispatch "layout" "\"colresize -conf\""))
            (bind "${mod} + ALT + 0" (dispatch "layout" "\"colresize +conf\""))

            # Zoom
            (bind "${mod} + SHIFT + U" (
              execCmd "hyprctl keyword cursor:zoom_factor $(hyprctl -j getoption cursor:zoom_factor | ${pkgs.jq}/bin/jq '[.float - ${toString zoomFactor}, 1.0] | max')"
            ))
            (bind "${mod} + SHIFT + I" (
              execCmd "hyprctl keyword cursor:zoom_factor $(hyprctl -j getoption cursor:zoom_factor | ${pkgs.jq}/bin/jq '.float + ${toString zoomFactor}')"
            ))
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
            blur = true;
            match.namespace = config.desktop.ignis.bar.namespace.regex;
          }
        ];
        window_rule =
          let
            floatRule = title: {
              center = true;
              float = true;
              match.title = "^(${title})$";
              size = "(monitor_w*${toString config.desktop.hyprland.float.size.default}) (monitor_h*${toString config.desktop.hyprland.float.size.default})";
            };
            noBorderIfSoleTile = {
              border_size = 0;
              match = {
                float = false;
                workspace = "f[1]";
              };
            };
          in
          map floatRule [
            config.desktop.audio.guiTitle
            config.desktop.bluetooth.guiTitle
            "wdisplays"
          ]
          ++ [ noBorderIfSoleTile ];
      };
    };
  };
}
