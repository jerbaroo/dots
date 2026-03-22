{pkgs, ...}:
let
  guiTitle = "bluetui";
in {
  inherit guiTitle;
  guiCmd = "ghostty --title=${guiTitle} -e ${pkgs.bluetui}/bin/bluetui";
  hm = {
    # Blueman is a reliable fallback.
    home.packages = with pkgs; [ blueman ];
    # Daemon required for blueman.
    services.blueman-applet.enable = true;
  };
}
