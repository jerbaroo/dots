{
  config,
  lib,
  pkgs,
  system,
  ...
}:
let
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
  config = {
    wayland.windowManager.hyprland = {
      configType = "lua";
      enable = true;
      package = config.desktop.hyprland.packages.hyprland;
      portalPackage = config.desktop.hyprland.packages.xdg-desktop-portal-hyprland;
      settings = {
        animation =
          let
            animation = leaf: curve: style: {
              _args = [
                (lib.generators.mkLuaInline (
                  let
                    styleStr = if style == null then "" else ", style=\"${style}\"";
                    # A spring is referenced with spring=, a bezier with bezier=.
                    field = if config.desktop.animation.curves.${curve}.type == "spring" then "spring" else "bezier";
                    # Border colour and gradient-angle animations pace on their
                    # own time; every other leaf is a window/surface motion.
                    # Hyprland speed is in deciseconds, so seconds * 10.
                    seconds =
                      if leaf == "border" || leaf == "borderangle" then
                        config.desktop.hyprland.animationTime.border
                      else
                        config.desktop.hyprland.animationTime.window;
                  in
                  "{ leaf=\"${leaf}\", enabled=true, speed=${toString (seconds * 10)}, ${field}=\"${curve}\"${styleStr} }"
                ))
              ];
            };
            curveOf = name: config.desktop.animation.${name}.curve;
            drawer = "slidevert"; # the scratchpad sliding down and back
            gradient = config.desktop.hyprland.border.gradient;
            pop = "popin 80%"; # a surface scaling into/out of place (windows, layers)
            slide = "slide"; # lateral travel (window move, workspace switch)
          in
          if config.desktop.hyprland.animationTime == null then
            [ ]
          else
            [
              (animation "border" (curveOf "colorShift") null)
            ]
            ++ lib.optional (gradient.animate != "none") (
              # A decorative rotation of the gradient's angle — not one of the
              # OS's semantic animations, so it takes a curve straight from the
              # vocabulary (linear for a constant loop, decelerate for a one-shot
              # sweep); the style carries the mode.
              animation "borderangle" (
                if gradient.animate == "loop" then "linear" else "decelerate"
              ) gradient.animate
            )
            ++ [
              # Parent of every fade Hyprland does not name below — window switch,
              # shadow, inactive-dim, DPMS on/off, tooltips. Alphabetically first,
              # so the specific children after it still win.
              (animation "fade" (curveOf "fadeIn") null)
              (animation "fadeIn" (curveOf "fadeIn") null)
              (animation "fadeOut" (curveOf "fadeOut") null)
              (animation "fadeLayersIn" (curveOf "fadeIn") null)
              (animation "fadeLayersOut" (curveOf "fadeOut") null)
              (animation "layersIn" (curveOf "windowIn") pop)
              (animation "layersOut" (curveOf "windowOut") pop)
              (animation "specialWorkspaceIn" (curveOf "transitionY") drawer)
              (animation "specialWorkspaceOut" (curveOf "windowOut") drawer)
              (animation "windowsIn" (curveOf "windowIn") pop)
              (animation "windowsOut" (curveOf "windowOut") pop)
              (animation "windowsMove" (curveOf "windowMove") slide)
              (animation "workspacesIn" (curveOf "windowIn") slide)
              (animation "workspacesOut" (curveOf "windowOut") slide)
            ];
        # Emit curves from animation.nix, the animations above reference them.
        # Each is tagged bezier or spring (Hyprland understands both).
        curve =
          let
            toCurve = name: c: {
              _args = [
                name
                (lib.generators.mkLuaInline (
                  if c.type == "spring" then
                    "{ type=\"spring\", mass=${c.mass}, stiffness=${c.stiffness}, dampening=${c.dampening} }"
                  else
                    "{ type=\"bezier\", points={ { ${builtins.elemAt c.points 0}, ${builtins.elemAt c.points 1} }, { ${builtins.elemAt c.points 2}, ${builtins.elemAt c.points 3} } } }"
                ))
              ];
            };
          in
          lib.mapAttrsToList toCurve config.desktop.animation.curves;
        config = {
          # cursor.no_hardware_cursors = true;
          debug.disable_logs = false;
          decoration = {
            active_opacity = 1;
            blur = {
              enabled = config.desktop.hyprland.blur.enabled;
              noise = 0.02;
              passes = config.desktop.hyprland.blur.iterations;
              popups = true;
              size = config.desktop.hyprland.blur.size;
            };
            inactive_opacity = 1;
            rounding = config.desktop.hyprland.rounding;
          };
          dwindle.preserve_split = true;
          general = {
            border_size = config.desktop.hyprland.border.size;
            "col.active_border" =
              let
                g = config.desktop.hyprland.border.gradient;
                rgb = name: "\"rgb(${lib.strings.removePrefix "#" config.desktop.theme.palette.${name}.hex})\"";
              in
              lib.generators.mkLuaInline "{ colors = { ${lib.concatStringsSep ", " (map rgb g.colors)} }, angle = ${toString g.angle} }";
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
          render.cm_auto_hdr = config.desktop.monitor.hdr.auto;
          scrolling = {
            column_width = config.desktop.hyprland.defaultColumnWidth;
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
            (bind "${mod} + E" (execCmd "${config.programs.doom-emacs.finalEmacsPackage}/bin/emacs"))
            (bind "${mod} + F" (dispatch "window.fullscreen" "{ mode = \"fullscreen\" }"))
            # https://wiki.hypr.land/Configuring/Basics/Dispatchers/#fullscreenstate
            (bind "${mod} + SHIFT + F" (dispatch "window.fullscreen_state" "{ client = 2, internal = 0 }"))
            (bind "${mod} + M" (execCmd "spotify"))
            # TODO read command from quickshell.nix
            (bind "${mod} + N" (
              execCmd "${config.programs.quickshell.package}/bin/quickshell -p /home/${config.desktop.username}/.config/quickshell/bar.qml ipc call notifications toggleNotificationCenter"
            ))
            (bind "${mod} + R" (execCmd "${pkgs.hyprpicker}/bin/hyprpicker --autocopy"))
            (bind "${mod} + SHIFT + R" (
              execCmd "${pkgs.hyprpicker}/bin/hyprpicker --autocopy --render-inactive"
            ))
            (bind "${mod} + P" (dispatch "layout" "\"promote\""))
            (bind "${mod} + Q" (dispatch "window.close" ""))
            (bind "${mod} + SHIFT + Q" (execCmd "${pkgs.hyprshutdown}/bin/hyprshutdown"))
            (bind "${mod} + S" (execCmd config.desktop.cli.screenshot))
            (bind "${mod} + SHIFT + S" (execCmd "kitty ${config.desktop.cli.home.switch}"))
            (bind "${mod} + T" (execCmd "${floatCenter 0} kitty ${config.desktop.btop.attach}"))
            (bind "${mod} + V" (execCmd "${floatCenter 0} ${config.desktop.audio.guiCmd}"))
            (bind "${mod} + W" (execCmd config.desktop.browser.cmd))

            # Other keys
            (bind "${mod} + BACKSPACE" (execCmd config.desktop.cli.ui.logoutMenu.toggle))
            (bind "${mod} + DELETE" (execCmd "systemctl suspend"))
            (bind "${mod} + RETURN" (execCmd "kitty"))
            (bind "${mod} + SHIFT + RETURN" (execCmd "konsole")) # Backup terminal.
            # TODO read command from quickshell.nix
            (bind "${mod} + SLASH" (
              execCmd "${config.programs.quickshell.package}/bin/quickshell -p /home/${config.desktop.username}/.config/quickshell/app_launcher.qml ipc call app-launcher toggle"
            ))
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
        # Blur Quickshell components.
        layer_rule = [
          {
            blur = config.desktop.hyprland.blur.enabled;
            # Necessary for how the Quickshell menu bar is built.
            ignore_alpha = config.desktop.hyprland.blur.threshold;
            match.namespace = "^(quickshell-bar|quickshell-launcher|quickshell-notifications|quickshell-osd)$";
          }
          {
            # Fade the transient popups in/out in place. The global default
            # layer style is "popin", which scales out from the centre and
            # reads as the launcher/notifications "growing" from the middle
            # rather than appearing where they sit; "fade" keeps them put.
            animation = "fade";
            match.namespace = "^(quickshell-launcher|quickshell-notifications|quickshell-osd)$";
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
            noBlur = {
              # Regular hyprland blur disabled if using hyprglass.
              no_blur = config.desktop.hyprland.blur.liquidGlass.enabled;
              match.title = "^(.*)$";
            };
          in
          map floatRule [
            config.desktop.audio.guiTitle
            config.desktop.bluetooth.guiTitle
            "wdisplays"
          ]
          ++ [
            noBorderIfSoleTile
            noBlur
          ];
      };
    };
  };
  options.desktop.hyprland = {
    animationTime = lib.mkOption {
      default = { };
      description = ''
        Hyprland animation time in seconds, split by category so window motion
        and border effects pace independently. null disables all animations.
      '';
      type = lib.types.nullOr (
        lib.types.submodule {
          options = {
            border = lib.mkOption {
              default = 3 * config.desktop.hyprland.animationTime.window;
              description = "Time for the border colour and gradient-angle animations.";
              type = lib.types.addCheck lib.types.float (x: x > 0);
            };
            window = lib.mkOption {
              default = 0.3;
              description = "Time for window, layer, workspace and fade animations.";
              type = lib.types.addCheck lib.types.float (x: x > 0);
            };
          };
        }
      );
    };
    border.gradient = {
      angle = lib.mkOption {
        default = 45;
        description = "Angle of the active window border's gradient, in degrees.";
        type = lib.types.ints.unsigned;
      };
      animate = lib.mkOption {
        default = "once";
        description = ''
          Animate the active border's gradient angle: "none", "once" (a single
          sweep when a window gains focus, no idle cost), or "loop" (a constant
          spin, which forces a new frame every refresh — high GPU/battery cost).
        '';
        type = lib.types.enum [
          "none"
          "once"
          "loop"
        ];
      };
      colors = lib.mkOption {
        default = [
          config.desktop.theme.accent
          "mauve"
        ];
        description = ''
          Palette colour names forming the active border's gradient, in order.
          A single name gives a solid border.
        '';
        type = lib.types.listOf lib.types.str;
      };
    };
    border.size = lib.mkOption {
      default = 2;
      description = "Size of window borders.";
      type = lib.types.ints.unsigned;
    };
    blur = {
      enabled = lib.mkOption {
        default = true;
        description = "Enable background blur for transparent windows.";
        type = lib.types.bool;
      };
      iterations = lib.mkOption {
        default = 5;
        description = "Amount of regular (not liquid glass) blurring iterations.";
        type = lib.types.ints.unsigned;
      };
      liquidGlass = {
        enabled = lib.mkOption {
          default = true;
          description = "Apply liquid glass effect for blurred windows.";
          type = lib.types.bool;
        };
        iterations = lib.mkOption {
          default = 2;
          description = "Amount of liquid glass blurring iterations.";
          type = lib.types.ints.unsigned;
        };
        size = lib.mkOption {
          default = 2.0;
          description = "Liquid glass blur size.";
          type = lib.types.float;
        };
      };
      size = lib.mkOption {
        default = 5;
        description = "Regular (not liquid glass) blur size.";
        type = lib.types.ints.unsigned;
      };
      threshold = lib.mkOption {
        default = 0.001;
        description = "Alpha below which blur is not applied.";
        type = lib.types.float;
      };
    };
    defaultColumnWidth = lib.mkOption {
      default = 0.25;
      description = "Default size of hyprland scrolling layout columns.";
      type = lib.types.float;
    };
    float.size.default = lib.mkOption {
      default = 0.85;
      description = "Height and width of floating windows (0 1].";
      type = lib.types.float;
    };
    gap = lib.mkOption {
      default = 8;
      description = "Gap between windows.";
      type = lib.types.ints.unsigned;
    };
    layout = lib.mkOption {
      default = "scrolling";
      description = "Hyprland layout type.";
      type = lib.types.enum [
        "dwindle"
        "scrolling"
      ];
    };
    packages = lib.mkOption {
      description = "Hyprland packages.";
      type = lib.types.attrs;
    };
    rounding = lib.mkOption {
      default = 8;
      description = "Rounding of borders.";
      type = lib.types.ints.unsigned;
    };
  };
}
