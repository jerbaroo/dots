{
  accent,
  palette,
  pkgs,
  ...
}:
let
  # Run git in the current directory with a tmux background.
  # The caller must ensure they are in the correct directory.
  tmux-git-open = pkgs.writeScriptBin "tmux-git-open" ''
    #!${pkgs.fish}/bin/fish

    if not git rev-parse --is-inside-work-tree &> /dev/null
      set wd (pwd)
      echo "Not in a git repository: $wd"
      exit 0
    end

    set git_cmd '${pkgs.gitu}/bin/gitu'
    if test -n "$before_tmux_git_open"
      set cmd "$before_tmux_git_open; $git_cmd"
    else
      set cmd "$git_cmd"
    end
    echod "tmux-git-open: cmd=$cmd"

    with_tmux_bg 'git' "$cmd"
  '';
  tmux-project-edit = pkgs.writeScriptBin "tmux-project-edit" ''
    #!${pkgs.fish}/bin/fish

    if test -z "$EDITOR"
      echo 'EDITOR variable not set'
      exit 0
    end
    with_tmux_bg 'Projects' "$EDITOR ~/.projects"
  '';
  tmux-project-open = pkgs.writeScriptBin "tmux-project-open" ''
    #!${pkgs.fish}/bin/fish

    with_tmux_bg 'Projects' 'tmux_project_open'
  '';
  tmux-session-open = pkgs.writeScriptBin "tmux-session-open" ''
    #!${pkgs.fish}/bin/fish

    with_tmux_bg 'Sessions' 'tmux_session_open'
  '';
in
{
  catppuccin.tmux.enable = false;
  home.packages = [
    tmux-git-open
    tmux-project-edit
    tmux-project-open
    tmux-session-open
  ];
  programs.tmux = {
    aggressiveResize = true;
    baseIndex = 1;
    clock24 = true;
    disableConfirmationPrompt = true;
    enable = true;
    escapeTime = 0;
    focusEvents = true; # Because neovim :healthcheck told me to.
    historyLimit = 1000000000;
    keyMode = "vi";
    mouse = true;
    secureSocket = true;
    sensibleOnTop = true;
    shortcut = "a";
    shell = "${pkgs.fish}/bin/fish";
    terminal = "tmux-256color";
    extraConfig = ''
      # Project and session commands.
      bind -n M-g run-shell 'cd #{pane_current_path} && ${tmux-git-open}/bin/tmux-git-open'
      bind -n M-m switch-client -t main
      bind -n M-p run-shell ${tmux-project-open}/bin/tmux-project-open
      bind -n M-P run-shell ${tmux-project-edit}/bin/tmux-project-edit
      bind -n M-s run-shell ${tmux-session-open}/bin/tmux-session-open

      # Theming.
      set -as terminal-features ",*:RGB" # True color.
      set -g pane-active-border-style fg=${palette.${accent}.hex}
      set -g pane-border-lines heavy
      set -g pane-border-style fg=${palette.base.hex}
      set -g message-command-style bg=${palette.base.hex},fg=${palette.text.hex}
      set -g message-style bg=${palette.base.hex},fg=${palette.text.hex}
      set -g prompt-cursor-colour "${palette.${accent}.hex}"
      set -g status-left-style fg=${palette.text.hex}
      set -g status-style bg=default # Transparent status bar background.
      set -g window-status-separator " "
      set -g window-status-style fg=${palette.text.hex}
      set -g window-status-current-style bg=${palette.base.hex},fg="${palette.${accent}.hex} bold"

      # Status bar format.
      set -g status-interval 1
      set -g status-right ""
      set -g automatic-rename-format '[#{b:pane_current_path}] #{b:pane_current_command}'

      # Renumber windows.
      set -g renumber-windows on

      # Reload configuration.
      unbind R
      bind -n M-r source-file $HOME/.config/tmux/tmux.conf \; display-message "Sourced $HOME/.config/tmux/tmux.conf"

      # Clipboard.
      set -g set-clipboard on
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
      unbind -T copy-mode-vi MouseDragEnd1Pane

      # Split panes.
      unbind %
      unbind '"'
      bind -n M-\; split-window -h -c "#{pane_current_path}"
      bind -n M-/ split-window -v -c "#{pane_current_path}"

      # Select panes.
      bind -n M-h select-pane -L
      bind -n M-j select-pane -D
      bind -n M-k select-pane -U
      bind -n M-l select-pane -R

      # Select windows.
      bind -n M-1 select-window -t 1
      bind -n M-2 select-window -t 2
      bind -n M-3 select-window -t 3
      bind -n M-4 select-window -t 4
      bind -n M-5 select-window -t 5
      bind -n M-6 select-window -t 6
      bind -n M-7 select-window -t 7
      bind -n M-8 select-window -t 8
      bind -n M-9 select-window -t 9
    '';
  };
}
