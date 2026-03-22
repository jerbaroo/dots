{ pkgs, ... }:
{
  programs.neovim = {
    defaultEditor = true;
    enable = true;
    initLua = ''
      vim.g.mapleader = ' '

      vim.keymap.set('n', '<leader>bp', ':bprevious<CR>')
      vim.keymap.set('n', '<leader>bn', ':bnext<CR>')
      -- bb pick from open buffers
      -- bk kill buffers
      -- bN new empty buffers
      -- fc copy file to
      -- fm move file to
      -- fs save file
      -- SPC .   find file (not fuzzy)
      -- SPC SPC find file in project (fuzzy)
      -- SPC /   search in project (fuzzy)

      -- which-key
      -- snacks: lazygit
      -- lazygit
      -- snacks: smooth scroll
      -- snacks: indent guides
      -- snacks: animate
      -- snacks: dashboard
      -- completion: noice?
      -- lsp
      -- evil-tmux-navigator

      vim.o.colorcolumn = "80"
      vim.o.clipboard="unnamedplus"
      vim.o.tabstop = 2
    '';
    package = pkgs.neovim-unwrapped;
    plugins = with pkgs.vimPlugins; [
      # catppuccin-nvim
    ];
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
  };
}
