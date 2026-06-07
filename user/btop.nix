{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = {
    programs.btop = {
      enable = true;
      package = config.desktop.btop.package;
      settings = {
        theme_background = false;
        vim_keys = true;
      };
    };
  };
  options.desktop.btop.attach = lib.mkOption {
    default = "${pkgs.tmux}/bin/tmux new-session -A -s btop ${config.desktop.btop.package}/bin/btop -u 500";
    readOnly = true;
    type = lib.types.str;
  };
  options.desktop.btop.package = lib.mkOption {
    default = pkgs.btop;
    readOnly = true;
    type = lib.types.package;
  };
  options.desktop.btop.startDetached = lib.mkOption {
    default = "${pkgs.tmux}/bin/tmux new-session -d -s btop ${config.desktop.btop.package}/bin/btop -u 500";
    readOnly = true;
    type = lib.types.str;
  };
}
