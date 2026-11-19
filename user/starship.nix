{ config, lib, ... }:
let
  palette = lib.mapAttrs (_: colour: colour.hex) config.desktop.theme.palette;
in
{
  programs.starship = {
    enable = true;
    enableTransience = true;
    settings = {
      add_newline = false;
      character = {
        error_symbol = "[❯](bold red)";
        success_symbol = "[❯](bold green)";
        vimcmd_symbol = "[❮](bold green)";
        vimcmd_replace_symbol = "[❮](bold purple)";
        vimcmd_replace_one_symbol = "[❮](bold purple)";
        vimcmd_visual_symbol = "[❮](bold yellow)";
      };
      gcloud.format = "$symbol";
      gcloud.symbol = "☁️ "; # To avoid extra space after default symbol.
      haskell.format = "[$symbol($version )]($style)";
      nix_shell.format = "$symbol";
      nix_shell.symbol = "❄️ "; # To avoid extra space after default symbol.
      palette = "desktop";
      palettes.desktop = palette // {
        black = palette.crust;
        bright-black = palette.overlay0;
        bright-blue = palette.blue;
        bright-cyan = palette.sky;
        bright-green = palette.green;
        bright-purple = palette.pink;
        bright-red = palette.red;
        bright-white = palette.text;
        bright-yellow = palette.yellow;
        cyan = palette.teal;
        purple = palette.mauve;
        white = palette.text;
      };
      python.format = "$symbol";
    };
  };
}
