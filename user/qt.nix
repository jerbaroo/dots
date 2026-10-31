{
  config,
  lib,
  pkgs,
  ...
}:
let
  themeName = "catppuccin-${config.catppuccin.kvantum.flavor}-${config.catppuccin.kvantum.accent}";
  themeSource = "${config.catppuccin.sources.kvantum}/share/Kvantum/${themeName}";
  paletteChanges = config.desktop.theme.paletteChanges;
in
{
  # qt.kvantum also writes this file, be explicit, choose one writer.
  catppuccin.kvantum.apply = false;
  qt = {
    enable = true;
    kvantum = {
      enable = true;
      settings.General.theme = themeName;
    };
    # Use the Kvantum style engine so Qt apps render the selected theme.
    style.name = "kvantum";
  };
  # Apply the desktop palette overrides (including OLED backgrounds).,
  xdg.configFile."Kvantum/${themeName}".source = lib.mkIf (paletteChanges != { }) (
    lib.mkForce (
      pkgs.runCommandLocal "${themeName}-repalette" { } ''
        cp -r ${themeSource} $out
        chmod -R u+w $out
        find $out -type f \( -name '*.kvconfig' -o -name '*.svg' \) -print0 \
          | xargs -0 --no-run-if-empty sed -i ${
            lib.concatMapStringsSep " " (colour: "-e 's/${colour.from}/${colour.to}/gI'") (
              lib.attrValues paletteChanges
            )
          }
      ''
    )
  );
  home.packages = with pkgs.kdePackages; [
    ark
    dolphin
    filelight
    okular
  ];
}
