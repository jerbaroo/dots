{pkgs}:
let
  guiTitle = "wiremix";
in {
  inherit guiTitle;
  guiCmd = "ghostty --title=${guiTitle} -e ${pkgs.wiremix}/bin/wiremix --tab output";
}
