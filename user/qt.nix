{ pkgs, ... }:
{
  home.packages = with pkgs.kdePackages; [
    ark
    dolphin
    filelight
    okular
  ];
  qt.enable = true;
}
