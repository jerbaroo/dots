{ lib, ... }:
{
  options = {
    desktop.systemFontSize = lib.mkOption {
      type = lib.types.ints.unsigned;
    };
    desktop.username = lib.mkOption {
      type = lib.types.str;
    };
  };
}
