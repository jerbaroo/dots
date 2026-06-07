{ lib, ... }:
{
  options.desktop = {
    hostname = lib.mkOption { type = lib.types.str; };
    system = lib.mkOption { type = lib.types.str; };
    username = lib.mkOption { type = lib.types.str; };
  };
}
