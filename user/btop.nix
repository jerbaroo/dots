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
  options.desktop.btop.package = lib.mkOption {
    default = pkgs.btop;
    readOnly = true;
    type = lib.types.package;
  };
}
