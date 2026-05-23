{ pkgs }:
let
  openrgb = pkgs.openrgb;
in
{
  cmd = "${openrgb}/bin/openrgb -c ff1300";
  hm = {
    home.packages = [ openrgb ];
  };
  nixos = {
    services.hardware.openrgb.enable = true;
  };
}
