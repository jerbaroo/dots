{ pkgs, ... }:
{
  qt = {
    enable = true;
    kvantum.enable = true;
    # Without this line:
    #   Failed assertions:
    #   - `qt.style.name` must be `"kvantum"` to use `qt.style.catppuccin`.
    style.name = "kvantum";
  };
  home.packages = with pkgs.kdePackages; [
    ark
    dolphin
    filelight
    okular
  ];
}
