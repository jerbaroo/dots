{
  accent,
  flavor,
  lib,
  pkgs,
  ...
}:
let
  hx-tmux-file-open =
    # FIXME
    # Open file in helix and close tmux popup.
    (
      pkgs.writeScriptBin "hx-tmux-file-open" ''
        #!${pkgs.fish}/bin/fish

        echo "Opening $argv[1] in pane $hx_pane" > /tmp/hx_debug.txt
        tmux send-keys -t "$hx_pane" ":open $argv[1]" C-m
        # Close the matrix window and the popup.
        # tmux send-keys -t "$TMUX_PANE" C-c
        tmux display-popup -C
      ''
    );
  hx-tmux-git-open =
    # Wrapper over tmux-git-open for when in helix.
    (
      pkgs.writeScriptBin "hx-tmux-git-open" ''
        #!${pkgs.fish}/bin/fish

        # TODO simplify this.
        set -x before_tmux_git_open " \
          set -gx hx_pane \"$TMUX_PANE\"; \
          set -gx EDITOR ${hx-tmux-file-open}/bin/hx-tmux-file-open; \
          set -gx VISUAL ${hx-tmux-file-open}/bin/hx-tmux-file-open; \
        "
        tmux-git-open
      ''
    );
in
{
  home.file.".config/helix/themes/theme.toml".text = ''
    inherits = "catppuccin-${flavor}"
    "comment" = { fg = "${accent}" }
    "ui.background" = {}
    "ui.cursor.primary.normal" = { fg = "base", bg = "yellow" }
    "ui.help" = { fg = "text", bg = "base" }
    "ui.linenr" = { fg = "${accent}" }
    "ui.linenr.selected" = { fg = "base", bg = "${accent}" }
    "ui.menu" = { fg = "text", bg = "base" }
    "ui.popup" = { fg = "${accent}", bg = "base" }
    "ui.statusline.normal" = { fg = "base", bg = "yellow" }
    "ui.virtual.indent-guide" = { fg = "overlay0" }
    "ui.virtual.ruler" = { bg = "overlay0" }
  '';
  home.packages = [
    hx-tmux-file-open
    hx-tmux-git-open
  ];
  programs.helix = {
    defaultEditor = false;
    enable = true;
    languages = {
      language-server.haskell-language-server = {
        config = [ { haskell.plugin.hlint.globalOn = false; } ];
      };
    };
    settings = {
      editor = {
        line-number = "relative";
        lsp.display-messages = true;
        indent-guides.render = true;
        rulers = [ 80 ];
      };
      keys.normal = {
        "C-h" = "jump_view_left";
        "C-j" = "jump_view_down";
        "C-k" = "jump_view_up";
        "C-l" = "jump_view_right";
        space = {
          space = "file_picker";
          "." = [
            ":sh rm -f /tmp/unique-file"
            ":insert-output ${pkgs.yazi}/bin/yazi %{buffer_name} --chooser-file=/tmp/unique-file"
            ":insert-output echo '\x1b[?1049h\x1b[?2004h' > /dev/tty"
            ":open %sh{cat /tmp/unique-file}"
            ":redraw"
          ];
          ":" = "command_palette";
          b = {
            b = "buffer_picker";
            k = ":buffer-close";
            n = ":buffer-next";
            N = ":new";
            p = ":buffer-previous";
          };
          c = {
            c = "toggle_comments";
            d = "diagnostics_picker";
            r = "rename_symbol";
          };
          f = {
            s = ":w";
          };
          g = {
            # gitu doesn't appear to work in the same way as lazygit does below.
            g = [
              ":write-all"
              ":new"
              ":insert-output ${pkgs.lazygit}/bin/lazygit"
              ":set mouse false" # First disable mouse to hint helix into activating it
              ":set mouse true"
              ":buffer-close!"
              ":redraw"
              ":reload-all"
            ];
            s = ":run-shell-command '${hx-tmux-git-open}/bin/hx-tmux-git-open %{buffer_name}'";
          };
          l = {
            r = ":lsp-restart";
            s = ":lsp-stop";
          };
          r = ":config-reload";
        };
      };
      theme = lib.mkForce "theme";
    };
  };
}
