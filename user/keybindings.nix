{
  config,
  lib,
  pkgs,
  showKeybindings,
}:
let
  dispatch = action: arg: hl "dsp.${action}" arg;
  dispatchFocusMoveInDirection = direction: ''
    function()
      local window = hl.get_active_window()
      local workspace = hl.get_active_workspace()
      -- Disable built-in fallbacks only for this synchronous focus attempt.
      local focusOptions = {
        ["binds.movefocus_cycles_fullscreen"] = false,
        ["binds.window_direction_monitor_fallback"] = false,
        ["general.no_focus_fallback"] = true,
      }
      local previousOptions = {}
      for name, value in pairs(focusOptions) do
        previousOptions[name] = hl.get_config(name)
      end
      hl.config(focusOptions)
      local result = hl.dispatch(hl.dsp.focus({ direction = "${direction}" }))
      hl.config(previousOptions)
      if not result.ok and result.code ~= "not_found" then
        return result
      end
      if hl.get_active_window() ~= window then
        return
      end
      local id = workspace and workspace.id
      if not id or id < 1 or id > 9 then
        return
      end
      local target = id ${if direction == "d" then "+ 1" else "- 1"}
      if target >= 1 and target <= 9 then
        return hl.dispatch(hl.dsp.focus({ workspace = target }))
      end
    end
  '';
  dispatchFocusMoveToWorkspace = workspace: dispatch "focus" "{ workspace = \"${workspace}\" }";
  dispatchLayoutSwapCol = direction: dispatch "layout" "\"swapcol ${direction}\"";
  dispatchWindowMoveInDirection =
    direction: dispatch "window.move" "{ direction = \"${direction}\" }";
  dispatchWindowMoveToWorkspace =
    workspace: dispatch "window.move" "{ workspace = \"${workspace}\" }";
  dispatchWorkspaceMoveInDirection =
    direction: dispatch "workspace.move" "{ monitor = \"${direction}\" }";
  execCmd = cmd: "hl.dsp.exec_cmd(\"${cmd}\")";
  floatCenter =
    cmd:
    lib.optionalString config.desktop.hyprland.float.center "[float;center;${floatSize config.desktop.hyprland.float.size.default}] "
    + cmd;
  floatSize = fraction: "size (monitor_w*${toString fraction}) (monitor_h*${toString fraction})";
  hl = action: arg: "hl.${action}(${arg})";
  mod = "SUPER";
  zoomFactor = 0.2;
in
[
  # Function keys
  [
    "XF86MonBrightnessDown"
    "Decrease brightness"
    (execCmd "${pkgs.brightnessctl}/bin/brightnessctl s 10%-")
  ]
  [
    "XF86MonBrightnessUp"
    "Increase brightness"
    (execCmd "${pkgs.brightnessctl}/bin/brightnessctl s +10%")
  ]
  [
    "XF86AudioMute"
    "Toggle mute"
    (execCmd "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_SINK@ toggle")
  ]
  [
    "XF86AudioLowerVolume"
    "Decrease volume"
    (execCmd "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_SINK@ 5%-")
  ]
  [
    "XF86AudioRaiseVolume"
    "Increase volume"
    (execCmd "${pkgs.wireplumber}/bin/wpctl set-volume -l 1.0 @DEFAULT_SINK@ 5%+")
  ]

  # Alphabet keys.
  [
    "${mod} + CTRL + A"
    "Audio settings"
    (execCmd (floatCenter config.desktop.audio.guiCmd))
  ]
  [
    "${mod} + CTRL + B"
    "Bluetooth settings"
    (execCmd (floatCenter config.desktop.bluetooth.guiCmd))
  ]
  [
    "${mod} + SHIFT + B"
    "Toggle bar"
    (execCmd "${lib.getExe config.programs.foyer.package} bar toggle")
  ]
  [
    "${mod} + C"
    "Center column"
    (dispatch "layout" "\"center\"")
  ]
  [
    "${mod} + D"
    "Yazi"
    (execCmd "kitty ${pkgs.yazi}/bin/yazi")
  ]
  [
    "${mod} + CTRL + D"
    "Display settings"
    (execCmd "${pkgs.wdisplays}/bin/wdisplays")
  ]
  [
    "${mod} + SHIFT + D"
    "Dolphin"
    (execCmd "${pkgs.kdePackages.dolphin}/bin/dolphin")
  ]
  [
    "${mod} + E"
    "Emacs"
    (execCmd "${config.programs.doom-emacs.finalEmacsPackage}/bin/emacs")
  ]
  [
    "${mod} + F"
    "Toggle fullscreen"
    (dispatch "window.fullscreen" "{ mode = \"fullscreen\" }")
  ]
  # https://wiki.hypr.land/Configuring/Basics/Dispatchers/#fullscreenstate
  [
    "${mod} + SHIFT + F"
    "Toggle client fullscreen"
    (dispatch "window.fullscreen_state" "{ client = 2, internal = 0 }")
  ]
  [
    "${mod} + M"
    "Spotify"
    (execCmd "spotify")
  ]
  [
    "${mod} + N"
    "Toggle notifications"
    (execCmd "${lib.getExe config.programs.foyer.package} notifications toggle")
  ]
  [
    "${mod} + O"
    "Toggle overview"
    ''function() hl.plugin.scrolloverview.overview("toggle all") end''
  ]
  [
    "${mod} + R"
    "Pick color"
    (execCmd "${pkgs.hyprpicker}/bin/hyprpicker --autocopy")
  ]
  [
    "${mod} + SHIFT + R"
    "Pick color including inactive windows"
    (execCmd "${pkgs.hyprpicker}/bin/hyprpicker --autocopy --render-inactive")
  ]
  [
    "${mod} + P"
    "Proton Pass"
    (execCmd "${lib.getExe pkgs.proton-pass}")
  ]
  [
    "${mod} + Q"
    "Close window"
    (dispatch "window.close" "")
  ]
  [
    "${mod} + SHIFT + Q"
    "End session"
    (execCmd "${pkgs.hyprshutdown}/bin/hyprshutdown")
  ]
  [
    "${mod} + S"
    "Screenshot"
    (execCmd config.desktop.cli.screenshot)
  ]
  [
    "${mod} + SHIFT + S"
    "Switch home configuration"
    (execCmd "kitty ${config.desktop.cli.home.switch}")
  ]
  [
    "${mod} + T"
    "System monitor"
    (execCmd (floatCenter "kitty ${config.desktop.btop.attach}"))
  ]
  [
    "${mod} + W"
    "Browser"
    (execCmd config.desktop.browser.cmd)
  ]
  [
    "${mod} + equal"
    "Promote column"
    (dispatch "layout" "\"promote\"")
  ]

  # Other keys
  [
    "${mod} + DELETE"
    "Lock session"
    (execCmd config.desktop.lock.cmd)
  ]
  [
    "${mod} + RETURN"
    "Terminal"
    (execCmd "kitty")
  ]
  [
    "${mod} + SHIFT + RETURN"
    "Terminal below active window"
    ''
      function()
        local w = hl.get_active_window()
        _G.kitty_below_height = w and w.size.y or nil
        hl.exec_cmd("kitty --class kitty-below")
      end
    ''
  ]
  [
    "${mod} + SLASH"
    "Toggle launcher"
    (execCmd "${lib.getExe config.programs.foyer.package} launcher toggle")
  ]
  [
    "${mod} + SHIFT + SLASH"
    "Show keybindings"
    (execCmd showKeybindings)
  ]
  [
    "${mod} + SPACE"
    "Fit visible columns or toggle split"
    (
      if config.desktop.hyprland.layout == "dwindle" then
        dispatch "togglesplit" ""
      else
        dispatch "layout" "\"fit visible\""
    )
  ]
  [
    "${mod} + SHIFT + SPACE"
    "Toggle floating"
    (dispatch "window.float" "")
  ]
  [
    "${mod} + TAB"
    "Cycle windows"
    (dispatch "window.cycle_next" "")
  ]
  [
    "${mod} + SHIFT + TAB"
    "Previous group window"
    (dispatch "group.prev" "")
  ]

  ##### Focus #####

  # Move focus in direction.
  [
    "${mod} + H"
    "Focus left"
    (dispatch "layout" "\"focus l\"")
  ]
  [
    "${mod} + J"
    "Focus down or next workspace (1-9)"
    (dispatchFocusMoveInDirection "d")
  ]
  [
    "${mod} + K"
    "Focus up or previous workspace (1-9)"
    (dispatchFocusMoveInDirection "u")
  ]
  [
    "${mod} + L"
    "Focus right"
    (dispatch "layout" "\"focus r\"")
  ]

  # Navigate columns with the mouse wheel.
  [
    "${mod} + mouse_up"
    "Focus column left"
    (dispatch "layout" "\"focus l\"")
  ]
  [
    "${mod} + mouse_down"
    "Focus column right"
    (dispatch "layout" "\"focus r\"")
  ]

  # Move focus to workspace.
  [
    "${mod} + 0"
    "Focus workspace 0"
    (dispatchFocusMoveToWorkspace "0")
  ]
  [
    "${mod} + 1"
    "Focus workspace 1"
    (dispatchFocusMoveToWorkspace "1")
  ]
  [
    "${mod} + 2"
    "Focus workspace 2"
    (dispatchFocusMoveToWorkspace "2")
  ]
  [
    "${mod} + 3"
    "Focus workspace 3"
    (dispatchFocusMoveToWorkspace "3")
  ]
  [
    "${mod} + 4"
    "Focus workspace 4"
    (dispatchFocusMoveToWorkspace "4")
  ]
  [
    "${mod} + 5"
    "Focus workspace 5"
    (dispatchFocusMoveToWorkspace "5")
  ]
  [
    "${mod} + 6"
    "Focus workspace 6"
    (dispatchFocusMoveToWorkspace "6")
  ]
  [
    "${mod} + 7"
    "Focus workspace 7"
    (dispatchFocusMoveToWorkspace "7")
  ]
  [
    "${mod} + 8"
    "Focus workspace 8"
    (dispatchFocusMoveToWorkspace "8")
  ]
  [
    "${mod} + 9"
    "Focus workspace 9"
    (dispatchFocusMoveToWorkspace "9")
  ]

  ##### Windows #####

  # Move window in direction.
  [
    "${mod} + SHIFT + H"
    "Move window left"
    (dispatchWindowMoveInDirection "l")
  ]
  [
    "${mod} + SHIFT + J"
    "Move window down"
    (dispatchWindowMoveInDirection "d")
  ]
  [
    "${mod} + SHIFT + K"
    "Move window up"
    (dispatchWindowMoveInDirection "u")
  ]
  [
    "${mod} + SHIFT + L"
    "Move window right"
    (dispatchWindowMoveInDirection "r")
  ]

  # Move window to workspace.
  [
    "${mod} + SHIFT + 0"
    "Move window to workspace 0"
    (dispatchWindowMoveToWorkspace "0")
  ]
  [
    "${mod} + SHIFT + 1"
    "Move window to workspace 1"
    (dispatchWindowMoveToWorkspace "1")
  ]
  [
    "${mod} + SHIFT + 2"
    "Move window to workspace 2"
    (dispatchWindowMoveToWorkspace "2")
  ]
  [
    "${mod} + SHIFT + 3"
    "Move window to workspace 3"
    (dispatchWindowMoveToWorkspace "3")
  ]
  [
    "${mod} + SHIFT + 4"
    "Move window to workspace 4"
    (dispatchWindowMoveToWorkspace "4")
  ]
  [
    "${mod} + SHIFT + 5"
    "Move window to workspace 5"
    (dispatchWindowMoveToWorkspace "5")
  ]
  [
    "${mod} + SHIFT + 6"
    "Move window to workspace 6"
    (dispatchWindowMoveToWorkspace "6")
  ]
  [
    "${mod} + SHIFT + 7"
    "Move window to workspace 7"
    (dispatchWindowMoveToWorkspace "7")
  ]
  [
    "${mod} + SHIFT + 8"
    "Move window to workspace 8"
    (dispatchWindowMoveToWorkspace "8")
  ]
  [
    "${mod} + SHIFT + 9"
    "Move window to workspace 9"
    (dispatchWindowMoveToWorkspace "9")
  ]

  # Move column horizontally in scrolling mode.
  [
    "${mod} + COMMA"
    "Move column left"
    (dispatchLayoutSwapCol "l")
  ]
  [
    "${mod} + PERIOD"
    "Move column right"
    (dispatchLayoutSwapCol "r")
  ]

  ##### Workspaces #####

  # Move workspace in direction.
  [
    "${mod} + CTRL + H"
    "Move workspace to monitor left"
    (dispatchWorkspaceMoveInDirection "l")
  ]
  [
    "${mod} + CTRL + J"
    "Move workspace to monitor down"
    (dispatchWorkspaceMoveInDirection "d")
  ]
  [
    "${mod} + CTRL + K"
    "Move workspace to monitor up"
    (dispatchWorkspaceMoveInDirection "u")
  ]
  [
    "${mod} + CTRL + L"
    "Move workspace to monitor right"
    (dispatchWorkspaceMoveInDirection "r")
  ]

  ##### Resizing and zooming #####

  # Resize column width
  [
    "${mod} +         ALT + 1"
    "Set column width to 10%"
    (dispatch "layout" "\"colresize 0.1\"")
  ]
  [
    "${mod} +         ALT + 2"
    "Set column width to 25%"
    (dispatch "layout" "\"colresize 0.25\"")
  ]
  [
    "${mod} +         ALT + 3"
    "Set column width to 33%"
    (dispatch "layout" "\"colresize 0.333333\"")
  ]
  [
    "${mod} + SHIFT + ALT + 3"
    "Set column width to 30%"
    (dispatch "layout" "\"colresize 0.3\"")
  ]
  [
    "${mod} +         ALT + 4"
    "Set column width to 40%"
    (dispatch "layout" "\"colresize 0.4\"")
  ]
  [
    "${mod} +         ALT + 5"
    "Set column width to 50%"
    (dispatch "layout" "\"colresize 0.5\"")
  ]
  [
    "${mod} +         ALT + 6"
    "Set column width to 67%"
    (dispatch "layout" "\"colresize 0.666666\"")
  ]
  [
    "${mod} + SHIFT + ALT + 6"
    "Set column width to 60%"
    (dispatch "layout" "\"colresize 0.6\"")
  ]
  [
    "${mod} +         ALT + 7"
    "Set column width to 75%"
    (dispatch "layout" "\"colresize 0.75\"")
  ]
  [
    "${mod} +         ALT + 8"
    "Set column width to 80%"
    (dispatch "layout" "\"colresize 0.8\"")
  ]
  [
    "${mod} +         ALT + 9"
    "Set column width to 90%"
    (dispatch "layout" "\"colresize 0.9\"")
  ]
  [
    "${mod} +         ALT + 0"
    "Set column width to 100%"
    (dispatch "layout" "\"colresize 1.0\"")
  ]

  # Zoom
  [
    "${mod} + SHIFT + U"
    "Zoom out"
    (execCmd "hyprctl keyword cursor:zoom_factor $(hyprctl -j getoption cursor:zoom_factor | ${pkgs.jq}/bin/jq '[.float - ${toString zoomFactor}, 1.0] | max')")
  ]
  [
    "${mod} + SHIFT + I"
    "Zoom in"
    (execCmd "hyprctl keyword cursor:zoom_factor $(hyprctl -j getoption cursor:zoom_factor | ${pkgs.jq}/bin/jq '.float + ${toString zoomFactor}')")
  ]
  [
    "${mod} + SHIFT + O"
    "Reset zoom"
    (execCmd "hyprctl keyword cursor:zoom_factor 1")
  ]

  [
    "switch:on:Lid Switch"
    "Suspend on lid close"
    (execCmd "systemctl suspend")
  ]
]
