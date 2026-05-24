{ lib, ... }:
let
  floatBetween0And1 = lib.types.addCheck lib.types.float (x: x >= 0.0 && x <= 1.0) // {
    description = "floating point number between 0.0 and 1.0 (inclusive)";
  };
in
{
  options.desktop = {
    font = {
      code = {
        name = lib.mkOption { type = lib.types.str; };
        size = lib.mkOption { type = lib.types.ints.unsigned; };
        backgroundOpacity = lib.mkOption { type = floatBetween0And1; };
      };
      system = {
        size = lib.mkOption { type = lib.types.ints.unsigned; };
      };
    };
    hostname = lib.mkOption { type = lib.types.str; };
    system = lib.mkOption { type = lib.types.str; };
    theme = {
      accent = lib.mkOption { type = lib.types.str; };
      colorSchemes = lib.mkOption { type = lib.types.attrs; };
      flavor = lib.mkOption { type = lib.types.str; };
      palette = lib.mkOption { type = lib.types.attrs; };
    };
    username = lib.mkOption { type = lib.types.str; };
    wrapGL = lib.mkOption { type = lib.types.functionTo lib.types.package; };
  };
}
