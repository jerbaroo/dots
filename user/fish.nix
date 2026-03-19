{ accent, lib, pkgs, username, ... }:
let
  neo-color = if accent == "blue" then "cyan" else accent;
  os-neo = pkgs.writeShellScriptBin "os-neo"
    "${pkgs.neo}/bin/neo -D -f 120 -F -c ${neo-color}";
  plugin = x: {
    name = x;
    src = pkgs.fishPlugins.${x}.src;
  };
in
{
  home.packages = with pkgs; [ grc ];
  programs.fish = {
    enable = true;
    functions = {
      echod = ''
        if test -n "$DEBUG"
          echo "$argv"
        end
      '';
      git_fixup = ''
        commandline "git commit --fixup "
        _fzf_search_git_log
        commandline -i " "
      '';
      # git status for file at path $argv1, useful for fzf preview.
      git_preview = ''
        set -l path (string replace '~' $HOME $argv[1])
        ${pkgs.git}/bin/git -C $path -c color.status=always status -b -s
        echo
        ${pkgs.lsd}/bin/lsd --color always --icon always $path
      '';
      # Run command in a tmux popup if within tmux, else run it normally.
      in_tmux_popup = ''
        echod "in_tmux_popup: $argv"
        set wd (pwd)
        echod "in_tmux_popup: pwd: $wd"
        if test -n "$TMUX"
          # tmux display-popup defaults to the directory of the tmux session
          # base or the client attachment point.
          tmux display-popup -E -d "$wd" -w '80%' -h '80%' "$argv"
        else
          eval "$argv"
        end
      '';
      notify_countdown = ''
        argparse 'h/help' 'm/message=' 's/sound' 't/time=' -- $argv
        or return
        if set -q _flag_help
          printf "Usage: notify_countdown [OPTIONS]\n\n"
          printf "Options:\n"
          printf "  -h, --help        Show this help message\n"
          printf "  -m, --message STR Set the text string\n"
          printf "  -s, --sound       Play a sound every second\n"
          printf "  -t, --time VAL    Set the countdown seconds (e.g., 5)\n"
          return 0
        end
        function make_message --inherit-variable _flag_message
          string replace '{}' $argv[1] $_flag_message
        end
        function play_sound --inherit-variable _flag_sound
          if set -q _flag_sound
            paplay /usr/share/sounds/freedesktop/stereo/complete.oga & disown
          end
        end
        play_sound
        set id (notify-send --print-id (make_message $_flag_time))
        for i in (seq (math $_flag_time - 1) -1 1)
          sleep 1
          play_sound
          notify-send --expire-time=1100 --replace-id=$id (make_message $i)
        end
      '';
      # Select projects from home directory. Project format: '~/foo'.
      project_select = ''
        set -l custom_paths
        set -l ignore_paths
        set -l projects_path ~/.projects
        if test -f $projects_path
          for line in (cat $projects_path | string split '\n' | string trim)
            if string match -q 'ignore:*' $line
              set -a ignore_paths -E (echo $line | string replace 'ignore:' "" | string trim)
            else
              set -a custom_paths $line
            end
          end
        end
        string replace -r '^' '~/' $custom_paths
        ${pkgs.fd}/bin/fd $ignore_paths '^\.git$' "$HOME" \
          --unrestricted -t f -t d -x dirname \
          | string replace $HOME "~"
      '';
      tmux_project_open = ''
        if test -z "$EDITOR"
          echo 'EDITOR variable not set'
          exit 0
        end

        set project_selection \
          ( project_select \
          | ${pkgs.fzf}/bin/fzf --reverse --preview 'git_preview {}' \
          )
        echod $project_selection

        # If an empty project.
        if test -n "$project_selection"

          # Expand the path.
          set project_path (eval echo $project_selection)
          # If project directory does exist.
          if test -d "$project_path"

            set project_name (path basename $project_path)
            if test -n "$project_name"

              # Create a session for the project if it doesn't exist.
              if not ${pkgs.tmux}/bin/tmux has-session -t $project_name 2> /dev/null
                ${pkgs.tmux}/bin/tmux new-session -d -s "$project_name" -c "$project_path"
                ${pkgs.tmux}/bin/tmux send-keys -t "$project_name" "$EDITOR ." C-m
              end
              tmux_switch_or_attach "$project_name"

            end
          end
        end
      '';
      tmux_session_open = ''
        set current_sess (${pkgs.tmux}/bin/tmux display-message -p '#{session_name}')
        set current_win (${pkgs.tmux}/bin/tmux display-message -p '#{window_id}')

        # Command to preview a tmux session.
        set preview_cmd "if test \"$current_sess\" = '{}'; \
            ${pkgs.tmux}/bin/tmux capture-pane -e -p -t \"$current_win\"; \
          else; \
            ${pkgs.tmux}/bin/tmux capture-pane -e -p -t {}; \
          end;"

        # Select a tmux session with fzf.
        set target \
          ( ${pkgs.tmux}/bin/tmux list-sessions -F '#{session_name}' \
          | ${pkgs.fzf}/bin/fzf --reverse --preview "$preview_cmd {}" \
          )

        if test -n "$target"
          tmux_switch_or_attach "$target"
        end
      '';
      tmux_switch_or_attach = ''
        if test -n "$TMUX"
          ${pkgs.tmux}/bin/tmux switch-client -t "$argv"
        else
          ${pkgs.tmux}/bin/tmux attach-session -t "$argv"
        end
      '';
      # Run the command in a new window with a background command iff TMUX_BG is
      # set AND we are within tmux, otherwise run the command normally.
      with_tmux_bg = ''
        set TMUX_BG ${os-neo}/bin/os-neo # Here for now..
        echod "TMUX: $TMUX"
        if test -n "$TMUX"; and test -n "$TMUX_BG";
          set bg_window_name "$argv[1]"
          echod "bg_window_name: $bg_window_name"

          set current_win (${pkgs.tmux}/bin/tmux display-message -p '#{session_name}:#{window_id}')
          echod "current_win: $current_win"
          set session_name (${pkgs.tmux}/bin/tmux display-message -p '#{session_name}')
          echod "session_name: $session_name"

          # Remove background on exit (only if inside tmux).
          function cleanup_bg --inherit-variable current_win --inherit-variable session_name --inherit-variable bg_window_name
            ${pkgs.tmux}/bin/tmux select-window -t "$current_win"
            ${pkgs.tmux}/bin/tmux kill-window -t "$session_name:$bg_window_name"
          end

          trap cleanup_bg INT TERM

          # Setup background (only if inside tmux).
          ${pkgs.tmux}/bin/tmux new-window -d -n "$bg_window_name" "$TMUX_BG"
          ${pkgs.tmux}/bin/tmux select-window -t "$bg_window_name"
        end

        in_tmux_popup "$argv[2]"
        echod "with_tmux_bg: command: $argv[2]"
        echod 'with_tmux_bg: command finished'

        # We check if the function exists (meaning we are in tmux) and run it.
        if functions -q cleanup_bg
          echod 'with_tmux_bg: cleaning up'
           cleanup_bg
           trap - INT TERM # Clear the trap so it doesn't run again
        end
      '';
    };
    shellAbbrs = {
      d = "git diff";
      dr = "direnv reload";
      grep = "batgrep";
      f = "git_fixup";
      g = "git";
      l = "eza";
      man = "batman";
      s = "git status";
      watch = "batwatch";
    };
    plugins = map plugin [
      "autopair"
      "bang-bang"
      "done"
      "forgit"
      "fzf-fish"
      "grc"
      "humantime-fish"
      "z"
    ];
    shellInit = ''
      set -g fish_key_bindings fish_vi_key_bindings
      set fish_greeting
    '';
  };
  programs.fzf = {
    colors = {
      bg = lib.mkForce "-1"; # Use terminal background colour.
      "bg+" = lib.mkForce "-1"; # Use terminal background colour.
    };
    enable = true;
    enableFishIntegration = false; # Just for the config file. Prefer fzf.fish.
  };
}
