{
  config,
  lib,
  pkgs,
  system,
  ...
}:
let
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
in
{
  config = {
    assertions = [
      {
        assertion =
          config.desktop.hyprland.border.gradient.animate != "none"
          -> builtins.length config.desktop.hyprland.border.gradient.colors >= 2;
        message = "To animate border gradient at least two colours are needed.";
      }
    ];
    wayland.windowManager.hyprland = {
      configType = "lua";
      enable = true;
      package = config.desktop.hyprland.packages.hyprland;
      portalPackage = config.desktop.hyprland.packages.xdg-desktop-portal-hyprland;
      settings = {
        animation =
          let
            # Convert an animation to Hyprland syntax.
            animation = animationName: isBorderAnimation: curve: style: {
              _args = [
                (lib.generators.mkLuaInline (
                  let
                    styleStr = if style == null then "" else ", style=\"${style}\"";
                    field = if config.desktop.animation.curves.${curve}.type == "spring" then "spring" else "bezier";
                    seconds =
                      if isBorderAnimation then
                        config.desktop.hyprland.animationTime.border
                      else
                        config.desktop.hyprland.animationTime.window;
                  in
                  "{ leaf=\"${animationName}\", enabled=true, speed=${toString (seconds * 10)}, ${field}=\"${curve}\"${styleStr} }"
                ))
              ];
            };
            curveOf = name: config.desktop.animation.${name}.curve;
            gradient = config.desktop.hyprland.border.gradient;
            # Styles of animation.
            drawer = "slidevert";
            pop = "popin 80%"; # Scaling in/out of place.
            slide = "slide"; # Lateral travel.
          in
          if config.desktop.hyprland.animationTime == null then
            [ ]
          else
            [ (animation "border" true (curveOf "colorShift") null) ]
            ++ lib.optional (gradient.animate != "none") (
              animation "borderangle" true (
                if gradient.animate == "loop" then "linear" else "decelerate"
              ) gradient.animate
            )
            ++ [
              (animation "fade" false (curveOf "fadeIn") null)
              (animation "fadeIn" false (curveOf "fadeIn") null)
              (animation "fadeOut" false (curveOf "fadeOut") null)
              (animation "fadeLayersIn" false (curveOf "fadeIn") null)
              (animation "fadeLayersOut" false (curveOf "fadeOut") null)
              (animation "layersIn" false (curveOf "windowIn") pop)
              (animation "layersOut" false (curveOf "windowOut") pop)
              (animation "specialWorkspaceIn" false (curveOf "transitionY") drawer)
              (animation "specialWorkspaceOut" false (curveOf "windowOut") drawer)
              (animation "windowsIn" false (curveOf "windowIn") pop)
              (animation "windowsOut" false (curveOf "windowOut") pop)
              (animation "windowsMove" false (curveOf "windowMove") slide)
              # Keep both workspaces moving together throughout the transition.
              (animation "workspacesIn" false (curveOf "transitionY") drawer)
              (animation "workspacesOut" false (curveOf "transitionY") drawer)
            ];
        # Map each curve from 'animation.nix' to Hyprland syntax.
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
        monitor = [
          {
            output = "DP-1";
            bitdepth = 10;
          }
        ];
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
          map execOnStart (config.desktop.startup.allCommands ++ [ "${monitorListener}" ])
          ++ lib.optionals (config.desktop.hyprland.layout == "scrolling") [
            {
              _args = [
                "window.open"
                (lib.generators.mkLuaInline ''
                  function(w)
                    if w.class == "kitty-below" then
                      local height = _G.kitty_below_height
                      _G.kitty_below_height = nil
                      hl.dispatch(hl.dsp.layout("consume_or_expel prev"))
                      if height then
                        hl.dispatch(hl.dsp.window.resize({
                          window = w,
                          x = w.size.x,
                          y = math.floor(height * 0.3),
                        }))
                      end
                    end
                  end
                '')
              ];
            }
          ];
        bind =
          let
            keybindings = import ./keybindings.nix {
              inherit
                config
                lib
                pkgs
                showKeybindings
                ;
            };
            keybindingsHelp =
              let
                rows = map (binding: {
                  description = builtins.elemAt binding 1;
                  keys = lib.concatStringsSep " " (
                    lib.filter (part: part != "") (lib.splitString " " (builtins.elemAt binding 0))
                  );
                }) keybindings;
                width = lib.foldl' (width: row: lib.max width (builtins.stringLength row.keys)) 0 rows;
                format =
                  row:
                  row.keys
                  + lib.concatStrings (lib.replicate (width - builtins.stringLength row.keys + 2) " ")
                  + row.description;
              in
              pkgs.writeText "keybindings-help.txt" (
                "Keybindings\n\n" + lib.concatMapStringsSep "\n" format rows + "\n"
              );
            # Overview submaps handle vertical focus; lid suspend also works while locked.
            options = {
              "SUPER + J".submap_universal = false;
              "SUPER + K".submap_universal = false;
              "switch:on:Lid Switch".locked = true;
            };
            showKeybindings = pkgs.writeShellScript "show-keybindings" ''
              exec ${lib.getExe config.programs.foyer.package} text < ${keybindingsHelp}
            '';
          in
          map (
            binding:
            let
              command = builtins.elemAt binding 2;
              keys = builtins.elemAt binding 0;
              name = builtins.elemAt binding 1;
            in
            {
              _args = [
                keys
                (lib.generators.mkLuaInline command)
                (
                  {
                    description = name;
                    submap_universal = true;
                  }
                  // (options.${keys} or { })
                )
              ];
            }
          ) keybindings;
        # Blur Quickshell components.
        layer_rule = [
          {
            blur = config.desktop.hyprland.blur.enabled;
            # Necessary for how the Quickshell menu bar is built.
            ignore_alpha = config.desktop.hyprland.blur.threshold;
            match.namespace = "^(${lib.concatStringsSep "|" (builtins.attrValues config.programs.foyer.layers)})$";
          }
          {
            # Fade the transient popups in/out in place.
            animation = "fade";
            match.namespace = "^(${
              lib.concatStringsSep "|" (
                with config.programs.foyer.layers;
                [
                  launcher
                  notifications
                  osd
                ]
              )
            })$";
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
            {
              # The portal picker has no app ID, so match its initial title.
              match.title = "^(Select what to share)$";
              float = true;
              center = true;
            }
            {
              match.class = "^kitty-below$";
              animation = "slide bottom";
            }
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
        default = "none";
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
        default = [ config.desktop.theme.accent ];
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
        grain = lib.mkOption {
          default = 0.3;
          description = "Amount of frosted grain.";
          type = lib.types.addCheck lib.types.float (x: x >= 0 && x <= 1);
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
    buttonRounding = lib.mkOption {
      default = config.desktop.hyprland.rounding / 2.0;
      defaultText = lib.literalExpression "config.desktop.hyprland.rounding / 2.0";
      description = "Corner radius of desktop buttons in pixels.";
      type = lib.types.addCheck lib.types.number (x: x >= 0);
    };
    defaultColumnWidth = lib.mkOption {
      default = 0.333333;
      description = "Default size of hyprland scrolling layout columns.";
      type = lib.types.float;
    };
    float.center = lib.mkOption {
      default = false;
      description = "Float, center and resize apps launched through the floatCenter helper.";
      type = lib.types.bool;
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
      default = 12;
      description = "Rounding of borders.";
      type = lib.types.ints.unsigned;
    };
  };
}
