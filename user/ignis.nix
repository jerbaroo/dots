{
  accent,
  ignis,
  ignisPath,
  palette,
  pkgs,
  ...
}:
let
  audio = (import ./audio.nix { inherit pkgs; });
  bluetooth = (import ./bluetooth.nix { inherit pkgs; });
in {
  hm = {
    home.file.${ignisPath} = {
      source = ./ignis;
      recursive = true;
    };
    # Write command paths to a fixed location, to be picked up at run-time.
    home.file."${ignisPath}/nix_paths.py".text = ''
      AUDIO_GUI_CMD="${audio.guiCmd}"
      BLUETOOTH_GUI_CMD="${bluetooth.guiCmd}"
    '';
    # Write theme colours to a fixed location, to be picked up at run-time.
    home.file."${ignisPath}/colors.scss".text = ''
      $accent: ${palette.${accent}.hex};
      $base: ${palette.base.hex};
      $crust: ${palette.crust.hex};
      $mantle: ${palette.mantle.hex};
      $red: ${palette.red.hex};
      $yellow: ${palette.yellow.hex};
    '';
    programs.ignis = {
      enable = true;
      sass = {
        enable = true;
        useDartSass = true;
      };
      services = {
        audio.enable = true;
        # bluetooth.enable = true;
        # recorder.enable = true;
        # network.enable = true;
      };
      extraPackages = with pkgs; [
        libnotify
      ];
    };
  };
}
