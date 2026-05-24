{ lib, pkgs, ... }:
let
  openrgb = pkgs.openrgb;
in
{
  config.home.packages = [ openrgb ];
  options.desktop.openrgb.command = lib.mkOption {
    default = "${openrgb}/bin/openrgb -c ff1300";
    description = "Command to set RGB colours";
    readOnly = true;
    type = lib.types.str;
  };
}
