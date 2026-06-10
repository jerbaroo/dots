{ lib, ... }:
{
  options.desktop = {
    allowUnfreePredicate = lib.mkOption {
      default = null; # See home.nix for why.
    };
    hostname = lib.mkOption { type = lib.types.str; };
    system = lib.mkOption { type = lib.types.str; };
    username = lib.mkOption { type = lib.types.str; };
  };
}
